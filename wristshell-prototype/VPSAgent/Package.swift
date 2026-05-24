// swift-tools-version: 5.9
import PackageDescription

// VPS-side companion daemon for wristshell-prototype.
// Runs on the user's Linux server, binds only to the Tailscale interface
// by default. Receives PlannedCommand JSON, validates against the same
// AllowlistRegistry the watch app ships with, executes via /bin/bash with
// restricted env, returns AgentResponse JSON.
//
// Built as a separate SPM package because it links neither HealthKit nor
// WatchKit; pure swift-nio + Foundation so it cross-compiles cleanly.
let package = Package(
    name: "VPSAgent",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "vps-agent", targets: ["VPSAgent"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
    ],
    targets: [
        .executableTarget(
            name: "VPSAgent",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
            ],
            path: "Sources/VPSAgent"
        ),
    ]
)
