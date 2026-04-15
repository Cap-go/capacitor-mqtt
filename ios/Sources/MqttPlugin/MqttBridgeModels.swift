import Foundation
import Capacitor
import CocoaMQTT

enum MqttBridgeEvent {
    static let connectionLost = "onConnectionLost"
    static let connectComplete = "onConnectComplete"
    static let messageArrived = "onMessageArrived"
}

enum MqttBridgeReasonCode {
    static let clientDisconnecting = 32102
    static let connectionLost = 32109
}

enum MqttBridgeValidationError: LocalizedError, Equatable {
    case missing(String)
    case invalid(String)

    var errorDescription: String? {
        switch self {
        case .missing(let field):
            return "\(field) is required"
        case .invalid(let message):
            return message
        }
    }
}

struct MqttBridgeConnectionTarget: Equatable {
    let host: String
    let port: UInt16
    let usesSSL: Bool
    let serverURI: String

    init(serverURI rawServerURI: String, port rawPort: Int) throws {
        let trimmedServerURI = rawServerURI.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedServerURI.isEmpty else {
            throw MqttBridgeValidationError.missing("serverURI")
        }

        guard (1...65_535).contains(rawPort) else {
            throw MqttBridgeValidationError.invalid("port must be between 1 and 65535")
        }

        let port = UInt16(rawPort)
        let parsedScheme: String
        let parsedHost: String

        if trimmedServerURI.contains("://") {
            guard let components = URLComponents(string: trimmedServerURI),
                  let scheme = components.scheme?.lowercased(),
                  let host = components.host,
                  !host.isEmpty else {
                throw MqttBridgeValidationError.invalid("serverURI must be a valid MQTT broker URL")
            }

            guard components.port == nil else {
                throw MqttBridgeValidationError.invalid(
                    "serverURI should not include a port; use the port option instead"
                )
            }

            guard components.query == nil, components.fragment == nil else {
                throw MqttBridgeValidationError.invalid("serverURI query and fragment are not supported")
            }

            guard components.path.isEmpty || components.path == "/" else {
                throw MqttBridgeValidationError.invalid("serverURI path is not supported")
            }

            guard MqttBridgeConnectionTarget.supportedSchemes.contains(scheme) else {
                throw MqttBridgeValidationError.invalid("serverURI scheme must be tcp, mqtt, ssl, tls, or mqtts")
            }

            parsedScheme = scheme
            parsedHost = host
        } else {
            parsedScheme = "tcp"
            parsedHost = trimmedServerURI
        }

        let formattedHost = parsedHost.contains(":") ? "[\(parsedHost)]" : parsedHost

        self.host = parsedHost
        self.port = port
        self.usesSSL = MqttBridgeConnectionTarget.sslSchemes.contains(parsedScheme)
        self.serverURI = "\(parsedScheme)://\(formattedHost):\(port)"
    }

    private static let supportedSchemes: Set<String> = ["tcp", "mqtt", "ssl", "tls", "mqtts"]
    private static let sslSchemes: Set<String> = ["ssl", "tls", "mqtts"]
}

enum MqttBridgeQoS {
    static func make(_ rawValue: Int) throws -> CocoaMQTTQoS {
        switch rawValue {
        case 0:
            return .qos0
        case 1:
            return .qos1
        case 2:
            return .qos2
        default:
            throw MqttBridgeValidationError.invalid("qos must be 0, 1, or 2")
        }
    }
}

struct MqttBridgeConnectOptions {
    let target: MqttBridgeConnectionTarget
    let clientId: String
    let username: String?
    let password: String?
    let cleanSession: Bool
    let connectionTimeout: TimeInterval
    let keepAliveInterval: UInt16
    let automaticReconnect: Bool
    let lastWillMessage: CocoaMQTTMessage?

    init(call: CAPPluginCall) throws {
        guard let rawServerURI = call.getString("serverURI") else {
            throw MqttBridgeValidationError.missing("serverURI")
        }
        guard let rawPort = call.getInt("port") else {
            throw MqttBridgeValidationError.missing("port")
        }

        let connectionTimeout = call.getInt("connectionTimeout") ?? 30
        guard connectionTimeout > 0 else {
            throw MqttBridgeValidationError.invalid(
                "Invalid connection timeout value. Please provide a non-zero value, otherwise your MQTT client connection cannot be established."
            )
        }

        let keepAliveInterval = call.getInt("keepAliveInterval") ?? 60
        let trimmedClientId = call.getString("clientId")?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.target = try MqttBridgeConnectionTarget(serverURI: rawServerURI, port: rawPort)
        self.clientId = trimmedClientId.flatMap { $0.isEmpty ? nil : $0 } ?? UUID().uuidString
        self.username = call.getString("username")
        self.password = call.getString("password")
        self.cleanSession = call.getBool("setCleanSession") ?? false
        self.connectionTimeout = TimeInterval(connectionTimeout)
        self.keepAliveInterval = try MqttBridgeConnectOptions.makeKeepAliveInterval(keepAliveInterval)
        self.automaticReconnect = call.getBool("setAutomaticReconnect") ?? true
        self.lastWillMessage = try MqttBridgeConnectOptions.makeLastWillMessage(from: call)
    }

    static func makeKeepAliveInterval(_ rawValue: Int) throws -> UInt16 {
        guard rawValue > 0, let keepAliveInterval = UInt16(exactly: rawValue) else {
            throw MqttBridgeValidationError.invalid(
                "Invalid keep alive interval value. Please provide a non-zero value, otherwise " +
                    "your MQTT client connection may timeout or disconnect unexpectedly. " +
                    "Value must be between 1 and 65535."
            )
        }

        return keepAliveInterval
    }

    private static func makeLastWillMessage(from call: CAPPluginCall) throws -> CocoaMQTTMessage? {
        guard let lastWill = call.getObject("setLastWill") else {
            return nil
        }

        guard let topic = lastWill["willTopic"] as? String,
              !topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MqttBridgeValidationError.invalid("setLastWill.willTopic is required")
        }

        guard let payload = lastWill["willPayload"] as? String else {
            throw MqttBridgeValidationError.invalid("setLastWill.willPayload is required")
        }

        let qos = try MqttBridgeQoS.make(lastWill["willQoS"] as? Int ?? 0)
        let retained = lastWill["setRetained"] as? Bool ?? false
        return CocoaMQTTMessage(topic: topic, string: payload, qos: qos, retained: retained)
    }
}

struct MqttBridgeSubscriptionOptions {
    let topic: String
    let qosValue: Int
    let qos: CocoaMQTTQoS

    init(call: CAPPluginCall) throws {
        guard let topic = call.getString("topic")?.trimmingCharacters(in: .whitespacesAndNewlines),
              !topic.isEmpty else {
            throw MqttBridgeValidationError.missing("topic")
        }

        let qosValue = call.getInt("qos") ?? 0
        self.topic = topic
        self.qosValue = qosValue
        self.qos = try MqttBridgeQoS.make(qosValue)
    }
}

struct MqttBridgePublishOptions {
    let topic: String
    let payload: String
    let qosValue: Int
    let qos: CocoaMQTTQoS
    let retained: Bool

    init(call: CAPPluginCall) throws {
        guard let topic = call.getString("topic")?.trimmingCharacters(in: .whitespacesAndNewlines),
              !topic.isEmpty else {
            throw MqttBridgeValidationError.missing("topic")
        }
        guard let payload = call.getString("payload") else {
            throw MqttBridgeValidationError.missing("payload")
        }

        let qosValue = call.getInt("qos") ?? 0
        self.topic = topic
        self.payload = payload
        self.qosValue = qosValue
        self.qos = try MqttBridgeQoS.make(qosValue)
        self.retained = call.getBool("retained") ?? false
    }
}
