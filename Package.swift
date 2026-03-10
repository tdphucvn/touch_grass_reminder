// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WorkPulse",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "WorkPulse", targets: ["WorkPulse"])
    ],
    targets: [
        .executableTarget(
            name: "WorkPulse",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("UserNotifications")
            ]
        )
    ]
)
