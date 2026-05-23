// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CarpCowork",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Core", targets: ["Core"]),
        .library(name: "UI", targets: ["UI"]),
    ],
    targets: [
        // Pure Swift — no UIKit/SwiftUI, testable on Linux
        .target(
            name: "Core",
            path: "Sources/Core"
        ),
        // SwiftUI layer
        .target(
            name: "UI",
            dependencies: ["Core"],
            path: "Sources/UI"
        ),
        // iOS App executable
        .executableTarget(
            name: "CarpCoworkApp",
            dependencies: ["Core", "UI"],
            path: "Sources/CarpCoworkApp"
        ),
        // Tests (Core only — no UIKit needed)
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core", "MockProviders"],
            path: "Tests/CoreTests"
        ),
        .target(
            name: "MockProviders",
            dependencies: ["Core"],
            path: "Tests/MockProviders"
        ),
    ]
)
