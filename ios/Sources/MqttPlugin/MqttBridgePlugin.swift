import Foundation
import Capacitor

/**
 * Basic iOS wiring for the MqttBridge Capacitor plugin.
 */
@objc(MqttBridgePlugin)
public class MqttBridgePlugin: CAPPlugin {
    public let jsName = "MqttBridge"

    @objc func connect(_ call: CAPPluginCall) {
        call.reject("MqttBridge is not implemented on iOS yet.")
    }

    @objc func disconnect(_ call: CAPPluginCall) {
        call.reject("MqttBridge is not implemented on iOS yet.")
    }

    @objc func subscribe(_ call: CAPPluginCall) {
        call.reject("MqttBridge is not implemented on iOS yet.")
    }

    @objc func publish(_ call: CAPPluginCall) {
        call.reject("MqttBridge is not implemented on iOS yet.")
    }

}
