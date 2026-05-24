// swift-tools-version: 5.9
import PackageDescription

// WristShell — voice-controlled remote command execution via Tailscale.
//
// Architecture (security-first):
//   - Default transport: watch → phone (WCSession) → phone → user's VPS over Tailscale.
//   - VPS exposes a tiny Swift-on-Linux service that runs ONLY allowlisted command
//     templates (restart_service, tail_log, disk_usage, etc.) — never free-form shell.
//   - LLM converts natural language to a JSON command call against this allowlist;
//     untemplated requests are rejected.
//   - Standalone mode (cellular watch, phone absent) is opt-in and uses mTLS.
//
// Default PrivacyConfig for this app is .strict, not .balanced.
let package = Package(
    name: "WristShell",
    platforms: [.iOS(.v17), .watchOS(.v10)],
    products: [
        .library(name: "WristShellCore", targets: ["WristShellCore"]),
    ],
    dependencies: [
        .package(path: "../watch-ai-core-prototype"),
    ],
    targets: [
        .target(
            name: "WristShellCore",
            dependencies: [.product(name: "Core", package: "watch-ai-core-prototype")],
            path: "Sources/WristShellCore"
        ),
        .target(
            name: "WristShellWatch",
            dependencies: [
                "WristShellCore",
                .product(name: "Core", package: "watch-ai-core-prototype"),
                .product(name: "CoreUI", package: "watch-ai-core-prototype"),
            ],
            path: "Sources/WristShellWatch"
        ),
        .target(
            name: "WristShellPhone",
            dependencies: [
                "WristShellCore",
                .product(name: "Core", package: "watch-ai-core-prototype"),
                .product(name: "CoreUI", package: "watch-ai-core-prototype"),
            ],
            path: "Sources/WristShellPhone"
        ),
        .testTarget(
            name: "WristShellCoreTests",
            dependencies: ["WristShellCore"],
            path: "Tests/WristShellCoreTests"
        ),
    ]
)
