// swift-tools-version: 5.9
import PackageDescription

// EchoLingo — real-time bidirectional voice translation from the wrist.
//
// Wrist-flip (CoreMotion) toggles language direction. Chunked audio →
// Whisper (with language hint) → LLM translation → AVSpeech in target language.
// VoiceActivityDetector cuts chunks at natural pauses.
let package = Package(
    name: "EchoLingo",
    platforms: [.iOS(.v17), .watchOS(.v10)],
    products: [
        .library(name: "EchoLingoCore", targets: ["EchoLingoCore"]),
    ],
    dependencies: [
        .package(path: "../watch-ai-core-prototype"),
    ],
    targets: [
        .target(
            name: "EchoLingoCore",
            dependencies: [.product(name: "Core", package: "watch-ai-core-prototype")],
            path: "Sources/EchoLingoCore"
        ),
        .target(
            name: "EchoLingoWatch",
            dependencies: [
                "EchoLingoCore",
                .product(name: "Core", package: "watch-ai-core-prototype"),
                .product(name: "CoreUI", package: "watch-ai-core-prototype"),
            ],
            path: "Sources/EchoLingoWatch"
        ),
        .target(
            name: "EchoLingoPhone",
            dependencies: [
                "EchoLingoCore",
                .product(name: "Core", package: "watch-ai-core-prototype"),
                .product(name: "CoreUI", package: "watch-ai-core-prototype"),
            ],
            path: "Sources/EchoLingoPhone"
        ),
        .testTarget(
            name: "EchoLingoCoreTests",
            dependencies: ["EchoLingoCore"],
            path: "Tests/EchoLingoCoreTests"
        ),
    ]
)
