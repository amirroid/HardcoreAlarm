// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HardcoreAlarm",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "HardcoreAlarm",
            targets: ["HardcoreAlarmApp"]
        ),
        .executable(
            name: "TestRunner",
            targets: ["TestRunner"]
        ),
        .library(
            name: "HardcoreAlarmCore",
            targets: ["HardcoreAlarmCore"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "HardcoreAlarmCore",
            dependencies: [],
            path: "Sources/HardcoreAlarmCore"
        ),
        .executableTarget(
            name: "HardcoreAlarmApp",
            dependencies: ["HardcoreAlarmCore"],
            path: "Sources/HardcoreAlarmApp"
        ),
        .executableTarget(
            name: "TestRunner",
            dependencies: ["HardcoreAlarmCore"],
            path: "Sources/TestRunner"
        )
    ]
)
