// swift-tools-version: 5.9
import PackageDescription

// VitaQuery — natural-language HealthKit queries from the wrist.
//
// "Is my HRV trend concerning?" "Am I overtraining this week?"
// The trick is in the HealthSummarizer: it aggregates HealthKit into a small,
// privacy-minimal struct (means, stddevs, deltas — never raw samples) and
// then the LLM reasons against that JSON.
let package = Package(
    name: "VitaQuery",
    platforms: [.iOS(.v17), .watchOS(.v10)],
    products: [
        .library(name: "VitaQueryCore", targets: ["VitaQueryCore"]),
        .library(name: "VitaQueryWatch", targets: ["VitaQueryWatch"]),
        .library(name: "VitaQueryPhone", targets: ["VitaQueryPhone"]),
    ],
    dependencies: [
        .package(path: "../watch-ai-core-prototype"),
    ],
    targets: [
        .target(
            name: "VitaQueryCore",
            dependencies: [.product(name: "Core", package: "watch-ai-core-prototype")],
            path: "Sources/VitaQueryCore"
        ),
        .target(
            name: "VitaQueryWatch",
            dependencies: [
                "VitaQueryCore",
                .product(name: "Core", package: "watch-ai-core-prototype"),
                .product(name: "CoreUI", package: "watch-ai-core-prototype"),
            ],
            path: "Sources/VitaQueryWatch"
        ),
        .target(
            name: "VitaQueryPhone",
            dependencies: [
                "VitaQueryCore",
                .product(name: "Core", package: "watch-ai-core-prototype"),
                .product(name: "CoreUI", package: "watch-ai-core-prototype"),
            ],
            path: "Sources/VitaQueryPhone"
        ),
        .testTarget(
            name: "VitaQueryCoreTests",
            dependencies: ["VitaQueryCore"],
            path: "Tests/VitaQueryCoreTests"
        ),
    ]
)
