// swift-tools-version: 5.9
import PackageDescription

// AskBand — push-to-talk LLM Q&A from the wrist.
//
// Tap the complication, speak a question, get a streamed answer back as
// both text and AVSpeech. Conversation history kept ~5 minutes for follow-ups,
// then cleared. Provider-agnostic (Claude / GPT via watch-ai-core's
// ProviderRegistry).
let package = Package(
    name: "AskBand",
    platforms: [.iOS(.v17), .watchOS(.v10)],
    products: [
        .library(name: "AskBandCore", targets: ["AskBandCore"]),
        .library(name: "AskBandWatch", targets: ["AskBandWatch"]),
        .library(name: "AskBandPhone", targets: ["AskBandPhone"]),
    ],
    dependencies: [
        .package(path: "../watch-ai-core-prototype"),
    ],
    targets: [
        .target(
            name: "AskBandCore",
            dependencies: [.product(name: "Core", package: "watch-ai-core-prototype")],
            path: "Sources/AskBandCore"
        ),
        .target(
            name: "AskBandWatch",
            dependencies: [
                "AskBandCore",
                .product(name: "Core", package: "watch-ai-core-prototype"),
                .product(name: "CoreUI", package: "watch-ai-core-prototype"),
            ],
            path: "Sources/AskBandWatch"
        ),
        .target(
            name: "AskBandPhone",
            dependencies: [
                "AskBandCore",
                .product(name: "Core", package: "watch-ai-core-prototype"),
                .product(name: "CoreUI", package: "watch-ai-core-prototype"),
            ],
            path: "Sources/AskBandPhone"
        ),
        .testTarget(
            name: "AskBandCoreTests",
            dependencies: ["AskBandCore"],
            path: "Tests/AskBandCoreTests"
        ),
    ]
)
