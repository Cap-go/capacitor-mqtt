import XCTest
@testable import MqttPlugin

class MqttPluginTests: XCTestCase {
    func testParsesTcpServerURI() throws {
        let target = try MqttBridgeConnectionTarget(serverURI: "tcp://broker.hivemq.com", port: 1883)

        XCTAssertEqual(target.host, "broker.hivemq.com")
        XCTAssertEqual(target.port, 1883)
        XCTAssertFalse(target.usesSSL)
        XCTAssertEqual(target.serverURI, "tcp://broker.hivemq.com:1883")
    }

    func testParsesSslServerURI() throws {
        let target = try MqttBridgeConnectionTarget(serverURI: "mqtts://broker.example.com", port: 8883)

        XCTAssertEqual(target.host, "broker.example.com")
        XCTAssertEqual(target.port, 8883)
        XCTAssertTrue(target.usesSSL)
        XCTAssertEqual(target.serverURI, "mqtts://broker.example.com:8883")
    }

    func testRejectsUnsupportedScheme() {
        XCTAssertThrowsError(
            try MqttBridgeConnectionTarget(serverURI: "wss://broker.example.com", port: 443)
        ) { error in
            XCTAssertEqual(
                error as? MqttBridgeValidationError,
                .invalid("serverURI scheme must be tcp, mqtt, ssl, tls, or mqtts")
            )
        }
    }

    func testRejectsInvalidQoS() {
        XCTAssertThrowsError(try MqttBridgeQoS.make(3)) { error in
            XCTAssertEqual(
                error as? MqttBridgeValidationError,
                .invalid("qos must be 0, 1, or 2")
            )
        }
    }

    func testRejectsKeepAliveIntervalAboveUInt16Max() {
        let invalidKeepAliveError = MqttBridgeValidationError.invalid(
            "Invalid keep alive interval value. Please provide a non-zero value, otherwise " +
                "your MQTT client connection may timeout or disconnect unexpectedly. " +
                "Value must be between 1 and 65535."
        )

        XCTAssertThrowsError(
            try MqttBridgeConnectOptions.makeKeepAliveInterval(Int(UInt16.max) + 1)
        ) { error in
            XCTAssertEqual(
                error as? MqttBridgeValidationError,
                invalidKeepAliveError
            )
        }
    }
}
