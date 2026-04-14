import Foundation
import Capacitor

/**
 * Basic iOS wiring for the MqttBridge Capacitor plugin.
 */
@objc(MqttBridgePlugin)
public class MqttBridgePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "MqttBridgePlugin"
    public let jsName = "MqttBridge"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "connect", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "disconnect", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "subscribe", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "publish", returnType: CAPPluginReturnPromise)
    ]

    private var mqttBridge: MqttBridge?

    override public func load() {
        mqttBridge = MqttBridge(plugin: self)
    }

    @objc func connect(_ call: CAPPluginCall) {
        mqttBridge?.connect(call)
    }

    @objc func disconnect(_ call: CAPPluginCall) {
        mqttBridge?.disconnect(call)
    }

    @objc func subscribe(_ call: CAPPluginCall) {
        mqttBridge?.subscribe(call)
    }

    @objc func publish(_ call: CAPPluginCall) {
        mqttBridge?.publish(call)
    }
}
