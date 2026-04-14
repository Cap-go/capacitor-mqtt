import Foundation
import MQTTNIO
import NIO
import NIOTransportServices
import Capacitor

@objc public class MqttBridge: NSObject {
    private var client: MQTTClient?
    private weak var plugin: CAPPlugin?
    private let group = NIOTSEventLoopGroup()
    
    init(plugin: CAPPlugin) {
        self.plugin = plugin
    }
    
    func connect(_ call: CAPPluginCall) {
        guard let serverURI = call.getString("serverURI"),
              let port = call.getInt("port"),
              let clientId = call.getString("clientId") else {
            call.reject("serverURI, port, and clientId are required")
            return
        }
        
        let username = call.getString("username")
        let password = call.getString("password")
        let keepAliveInterval = call.getInt("keepAliveInterval") ?? 60
        
        let configuration = MQTTClient.Configuration(
            version: .v3_1_1,
            keepAliveInterval: .seconds(Int64(keepAliveInterval)),
            userName: username,
            password: password
        )
        
        let client = MQTTClient(
            host: serverURI,
            port: port,
            identifier: clientId,
            eventLoopGroupProvider: .shared(group),
            configuration: configuration
        )
        self.client = client
        
        // Setup listeners
        client.addPublishListener(named: "messageArrived") { result in
            switch result {
            case .success(let publish):
                let topic = publish.topicName
                let message = String(buffer: publish.payload)
                self.plugin?.notifyListeners("onMessageArrived", data: [
                    "topic": topic,
                    "message": message
                ])
            case .failure:
                break
            }
        }
        
        client.addCloseListener(named: "connectionLost") { result in
            var data: [String: Any] = [
                "connectionStatus": "disconnected",
                "reasonCode": -1,
                "message": "Client disconnected"
            ]
            
            switch result {
            case .success:
                data["message"] = "Client disconnected purposefully"
                // Android uses MqttException.REASON_CODE_CLIENT_DISCONNECTING (32102)
                data["reasonCode"] = 32102
            case .failure(let error):
                data["message"] = "Client disconnected unexpectedly: \(error.localizedDescription)"
                // Android uses MqttException.REASON_CODE_CONNECTION_LOST (32109)
                data["reasonCode"] = 32109
            }
            
            self.plugin?.notifyListeners("onConnectionLost", data: data)
        }
        
        Task {
            do {
                try await client.connect()
                
                self.plugin?.notifyListeners("onConnectComplete", data: [
                    "reconnected": false,
                    "serverURI": "\(serverURI):\(port)"
                ])
                
                call.resolve()
            } catch {
                call.reject("Failed to connect: \(error.localizedDescription)")
            }
        }
    }
    
    func disconnect(_ call: CAPPluginCall) {
        guard let client = client else {
            call.reject("Client not initialized")
            return
        }
        
        Task {
            do {
                try await client.disconnect()
                call.resolve()
            } catch {
                call.reject("Failed to disconnect: \(error.localizedDescription)")
            }
        }
    }
    
    func subscribe(_ call: CAPPluginCall) {
        guard let client = client else {
            call.reject("Client not initialized")
            return
        }
        
        guard let topic = call.getString("topic") else {
            call.reject("topic is required")
            return
        }
        
        let qosValue = call.getInt("qos") ?? 0
        let qos: MQTTQoS = qosValue == 1 ? .atLeastOnce : (qosValue == 2 ? .exactlyOnce : .atMostOnce)
        
        Task {
            do {
                let subscription = MQTTSubscribeInfo(topicFilter: topic, qos: qos)
                _ = try await client.subscribe(to: [subscription])
                call.resolve([
                    "topic": topic,
                    "qos": qosValue
                ])
            } catch {
                call.reject("Failed to subscribe: \(error.localizedDescription)")
            }
        }
    }
    
    func publish(_ call: CAPPluginCall) {
        guard let client = client else {
            call.reject("Client not initialized")
            return
        }
        
        guard let topic = call.getString("topic"),
              let payload = call.getString("payload") else {
            call.reject("topic and payload are required")
            return
        }
        
        let qosValue = call.getInt("qos") ?? 0
        let qos: MQTTQoS = qosValue == 1 ? .atLeastOnce : (qosValue == 2 ? .exactlyOnce : .atMostOnce)
        let retained = call.getBool("retained") ?? false
        
        Task {
            do {
                try await client.publish(
                    to: topic,
                    payload: ByteBuffer(string: payload),
                    qos: qos,
                    retain: retained
                )
                call.resolve([
                    "topic": topic,
                    "payload": payload,
                    "qos": qosValue,
                    "retained": retained,
                    "messageId": -1 // MQTTNIO doesn't easily expose messageId for async publish
                ])
            } catch {
                call.reject("Failed to publish: \(error.localizedDescription)")
            }
        }
    }
}
