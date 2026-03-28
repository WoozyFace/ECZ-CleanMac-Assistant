// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CleanMacAssistantNative",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "CleanMacAssistantNative",
            targets: ["CleanMacAssistantNative"]
        )
    ],
    targets: [
        .executableTarget(
            name: "CleanMacAssistantNative",
            path: "Sources/CleanMacAssistantNative",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .define("DEVELOPER_BUILD", .when(configuration: .debug))
            ]
        )
    ]
)
