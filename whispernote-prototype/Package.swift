// swift-tools-version: 5.9
import PackageDescription

// WhisperNote — voice → Whisper → LLM-structured notes, from the wrist.
//
// Three targets:
//   WhisperNoteCore   pure Swift, testable on Linux
//   WhisperNoteWatch  watchOS app entry point (SwiftUI)
//   WhisperNotePhone  iOS companion entry point (SwiftUI)
//
// All three depend on the shared WatchAICore via a relative SPM path.
let package = Package(
    name: "WhisperNote",
    platforms: [.iOS(.v17), .watchOS(.v10)],
    products: [
        .library(name: "WhisperNoteCore", targets: ["WhisperNoteCore"]),
    ],
    dependencies: [
        .package(path: "../watch-ai-core-prototype"),
    ],
    targets: [
        .target(
            name: "WhisperNoteCore",
            dependencies: [
                .product(name: "Core", package: "watch-ai-core-prototype"),
            ],
            path: "Sources/WhisperNoteCore"
        ),
        .target(
            name: "WhisperNoteWatch",
            dependencies: [
                "WhisperNoteCore",
                .product(name: "Core", package: "watch-ai-core-prototype"),
                .product(name: "CoreUI", package: "watch-ai-core-prototype"),
            ],
            path: "Sources/WhisperNoteWatch"
        ),
        .target(
            name: "WhisperNotePhone",
            dependencies: [
                "WhisperNoteCore",
                .product(name: "Core", package: "watch-ai-core-prototype"),
                .product(name: "CoreUI", package: "watch-ai-core-prototype"),
            ],
            path: "Sources/WhisperNotePhone"
        ),
        .testTarget(
            name: "WhisperNoteCoreTests",
            dependencies: ["WhisperNoteCore"],
            path: "Tests/WhisperNoteCoreTests"
        ),
    ]
)
