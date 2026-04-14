// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MqttPlugin",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "MqttPlugin",
            targets: ["MqttPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0"),
        .package(url: "https://github.com/emqx/CocoaMQTT.git", from: "2.2.3")
    ],
    targets: [
        .target(
            name: "MqttPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                .product(name: "CocoaMQTT", package: "CocoaMQTT")
            ],
            path: "ios/Sources/MqttPlugin"),
        .testTarget(
            name: "MqttPluginTests",
            dependencies: ["MqttPlugin"],
            path: "ios/Tests/MqttPluginTests")
    ]
)
