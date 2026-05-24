// swift-tools-version: 5.9
import PackageDescription

// Shared logic across the watch+AI prototypes:
//   whispernote, mom, askband, echolingo, vitaquery, wristshell.
// Each app depends on this via `.package(path: "../watch-ai-core-prototype")`.
//
// `Core` is pure Swift — no SwiftUI / UIKit / WatchKit / HealthKit imports —
// so it compiles for iOS, watchOS, AND Linux (for testing).
// `CoreUI` is SwiftUI bits shared across the watch apps.
let package = Package(
    name: "WatchAICore",
    platforms: [.iOS(.v17), .watchOS(.v10)],
    products: [
        .library(name: "Core", targets: ["Core"]),
        .library(name: "CoreUI", targets: ["CoreUI"]),
    ],
    targets: [
        .target(
            name: "Core",
            path: "Sources/Core"
        ),
        .target(
            name: "CoreUI",
            dependencies: ["Core"],
            path: "Sources/CoreUI"
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"],
            path: "Tests/CoreTests"
        ),
    ]
)
