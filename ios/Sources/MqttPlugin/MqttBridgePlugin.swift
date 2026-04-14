import Foundation
import Capacitor
import CocoaMQTT

private struct PendingSubscription {
    let call: CAPPluginCall
    let qos: Int
}

private struct PendingPublish {
    let call: CAPPluginCall
    let result: [String: Any]
}

@objc(MqttBridgePlugin)
public class MqttBridgePlugin: CAPPlugin, CAPBridgedPlugin, CocoaMQTTDelegate {
    public let identifier = "MqttBridgePlugin"
    public let jsName = "MqttBridge"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "connect", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "disconnect", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "subscribe", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "publish", returnType: CAPPluginReturnPromise)
    ]

    private var mqttClient: CocoaMQTT?
    private var pendingConnectCall: CAPPluginCall?
    private var pendingSubscriptions: [String: [PendingSubscription]] = [:]
    private var pendingPublishes: [UInt16: PendingPublish] = [:]
    private var currentServerURI = ""
    private var isExpectingDisconnect = false
    private var isReconnecting = false

    deinit {
        mqttClient?.autoReconnect = false
        mqttClient?.disconnect()
    }

    @objc func connect(_ call: CAPPluginCall) {
        do {
            let options = try MqttBridgeConnectOptions(call: call)

            if pendingConnectCall != nil {
                call.reject("MQTT client is already connecting")
                return
            }

            if let existingClient = mqttClient,
               existingClient.connState == .connected || existingClient.connState == .connecting {
                call.reject("MQTT client is already connected")
                return
            }

            mqttClient?.autoReconnect = false
            mqttClient = nil

            let client = CocoaMQTT(clientID: options.clientId, host: options.target.host, port: options.target.port)
            client.delegate = self
            client.cleanSession = options.cleanSession
            client.keepAlive = options.keepAliveInterval
            client.autoReconnect = options.automaticReconnect
            client.username = options.username
            client.password = options.password
            client.willMessage = options.lastWillMessage
            client.enableSSL = options.target.usesSSL

            pendingConnectCall = call
            mqttClient = client
            currentServerURI = options.target.serverURI
            isExpectingDisconnect = false
            isReconnecting = false

            guard client.connect(timeout: options.connectionTimeout) else {
                pendingConnectCall = nil
                mqttClient = nil
                call.reject("Failed to connect to MQTT broker: unable to open socket")
                return
            }
        } catch {
            call.reject(error.localizedDescription)
        }
    }

    @objc func disconnect(_ call: CAPPluginCall) {
        guard let client = mqttClient else {
            call.resolve()
            return
        }

        client.autoReconnect = false
        isExpectingDisconnect = true
        isReconnecting = false

        if client.connState == .connected || client.connState == .connecting {
            client.disconnect()
        } else {
            mqttClient = nil
        }

        call.resolve()
    }

    @objc func subscribe(_ call: CAPPluginCall) {
        do {
            let options = try MqttBridgeSubscriptionOptions(call: call)
            guard let client = mqttClient, client.connState == .connected else {
                call.reject("MQTT client is not connected")
                return
            }

            pendingSubscriptions[options.topic, default: []].append(
                PendingSubscription(call: call, qos: options.qosValue)
            )
            client.subscribe(options.topic, qos: options.qos)
        } catch {
            call.reject(error.localizedDescription)
        }
    }

    @objc func publish(_ call: CAPPluginCall) {
        do {
            let options = try MqttBridgePublishOptions(call: call)
            guard let client = mqttClient, client.connState == .connected else {
                call.reject("MQTT client is not connected")
                return
            }

            let result: [String: Any] = [
                "topic": options.topic,
                "payload": options.payload,
                "qos": options.qosValue,
                "retained": options.retained
            ]

            let messageId = client.publish(
                options.topic,
                withString: options.payload,
                qos: options.qos,
                retained: options.retained
            )

            guard messageId >= 0 else {
                call.reject("Failed to publish message to topic: \(options.topic)")
                return
            }

            if options.qos == .qos0 {
                call.resolve(result.merging(["messageId": messageId]) { _, newValue in newValue })
                return
            }

            guard let pendingMessageId = UInt16(exactly: messageId) else {
                call.reject("Failed to publish message to topic: \(options.topic)")
                return
            }

            pendingPublishes[pendingMessageId] = PendingPublish(
                call: call,
                result: result.merging(["messageId": messageId]) { _, newValue in newValue }
            )
        } catch {
            call.reject(error.localizedDescription)
        }
    }

    public func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        guard mqtt === mqttClient else {
            return
        }

        let connectCall = pendingConnectCall
        pendingConnectCall = nil

        guard ack == .accept else {
            mqtt.autoReconnect = false
            mqtt.disconnect()
            mqttClient = nil
            connectCall?.reject("Failed to connect to MQTT broker: \(ack.description)")
            return
        }

        notifyListeners(
            MqttBridgeEvent.connectComplete,
            data: [
                "reconnected": isReconnecting,
                "serverURI": currentServerURI
            ]
        )
        isReconnecting = false
        connectCall?.resolve()
    }

    public func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {}

    public func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        guard mqtt === mqttClient, let pendingPublish = pendingPublishes.removeValue(forKey: id) else {
            return
        }

        pendingPublish.call.resolve(pendingPublish.result)
    }

    public func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        guard mqtt === mqttClient else {
            return
        }

        notifyListeners(
            MqttBridgeEvent.messageArrived,
            data: [
                "topic": message.topic,
                "message": message.string ?? ""
            ]
        )
    }

    public func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        guard mqtt === mqttClient else {
            return
        }

        for failedTopic in failed {
            let pendingCalls = pendingSubscriptions.removeValue(forKey: failedTopic) ?? []
            for pendingCall in pendingCalls {
                pendingCall.call.reject("Failed to subscribe to topic: \(failedTopic)")
            }
        }

        for (rawTopic, rawQoS) in success {
            guard let topic = rawTopic as? String else {
                continue
            }

            let pendingCalls = pendingSubscriptions.removeValue(forKey: topic) ?? []
            let resolvedQoS = MqttBridgePlugin.qosValue(from: rawQoS)
            for pendingCall in pendingCalls {
                pendingCall.call.resolve([
                    "topic": topic,
                    "qos": resolvedQoS ?? pendingCall.qos
                ])
            }
        }
    }

    public func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {}

    public func mqttDidPing(_ mqtt: CocoaMQTT) {}

    public func mqttDidReceivePong(_ mqtt: CocoaMQTT) {}

    public func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        guard mqtt === mqttClient else {
            return
        }

        let expectedDisconnect = isExpectingDisconnect
        isExpectingDisconnect = false

        rejectPendingWork(
            message: err?.localizedDescription ?? "MQTT client disconnected before the operation completed"
        )

        if expectedDisconnect {
            mqttClient = nil
        } else {
            isReconnecting = mqtt.autoReconnect && err != nil
        }

        let reasonCode = expectedDisconnect
            ? MqttBridgeReasonCode.clientDisconnecting
            : MqttBridgeReasonCode.connectionLost
        let message = expectedDisconnect ? "Client disconnected purposefully" : "Client disconnected unexpectedly"

        notifyListeners(
            MqttBridgeEvent.connectionLost,
            data: [
                "connectionStatus": "disconnected",
                "reasonCode": reasonCode,
                "message": message
            ]
        )
    }

    private func rejectPendingWork(message: String) {
        pendingConnectCall?.reject("Failed to connect to MQTT broker: \(message)")
        pendingConnectCall = nil

        for pendingCalls in pendingSubscriptions.values {
            for pendingCall in pendingCalls {
                pendingCall.call.reject(message)
            }
        }
        pendingSubscriptions.removeAll()

        for pendingPublish in pendingPublishes.values {
            pendingPublish.call.reject(message)
        }
        pendingPublishes.removeAll()
    }

    private static func qosValue(from rawValue: Any) -> Int? {
        switch rawValue {
        case let qos as CocoaMQTTQoS:
            return Int(qos.rawValue)
        case let int as Int:
            return int
        case let uint as UInt8:
            return Int(uint)
        case let number as NSNumber:
            return number.intValue
        default:
            return nil
        }
    }
}
