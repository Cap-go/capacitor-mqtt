import XCTest
import Capacitor
@testable import MqttPlugin

class MqttPluginTests: XCTestCase {
    var plugin: MqttBridgePlugin!
    
    override func setUp() {
        super.setUp()
        plugin = MqttBridgePlugin()
        plugin.load()
    }
    
    func testPluginJSName() {
        XCTAssertEqual(plugin.jsName, "MqttBridge")
    }
    
    func testPluginIdentifier() {
        XCTAssertEqual(plugin.identifier, "MqttBridgePlugin")
    }
    
    func testPluginMethods() {
        let methods = plugin.pluginMethods.map { $0.name }
        XCTAssertTrue(methods.contains("connect"))
        XCTAssertTrue(methods.contains("disconnect"))
        XCTAssertTrue(methods.contains("subscribe"))
        XCTAssertTrue(methods.contains("publish"))
    }
}
