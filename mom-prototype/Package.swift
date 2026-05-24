// swift-tools-version: 5.9
import PackageDescription

// Mom — a habit-builder + task manager that flexes around your real calendar.
//
// One engine, two surfaces:
//   - Habits  recurring, glyph-tagged (water / sun / guitar / dumbbell / book)
//   - Tasks   one-off natural-language items
// The CalendarFlexEngine asks an LLM "for the next N hours, what should I cue,
// when, and why?" using EventKit + HealthKit context, and schedules notifications.
let package = Package(
    name: "Mom",
    platforms: [.iOS(.v17), .watchOS(.v10)],
    products: [
        .library(name: "MomCore", targets: ["MomCore"]),
        .library(name: "MomWatch", targets: ["MomWatch"]),
        .library(name: "MomPhone", targets: ["MomPhone"]),
    ],
    dependencies: [
        .package(path: "../watch-ai-core-prototype"),
    ],
    targets: [
        .target(
            name: "MomCore",
            dependencies: [
                .product(name: "Core", package: "watch-ai-core-prototype"),
            ],
            path: "Sources/MomCore"
        ),
        .target(
            name: "MomWatch",
            dependencies: [
                "MomCore",
                .product(name: "Core", package: "watch-ai-core-prototype"),
                .product(name: "CoreUI", package: "watch-ai-core-prototype"),
            ],
            path: "Sources/MomWatch"
        ),
        .target(
            name: "MomPhone",
            dependencies: [
                "MomCore",
                .product(name: "Core", package: "watch-ai-core-prototype"),
                .product(name: "CoreUI", package: "watch-ai-core-prototype"),
            ],
            path: "Sources/MomPhone"
        ),
        .testTarget(
            name: "MomCoreTests",
            dependencies: ["MomCore"],
            path: "Tests/MomCoreTests"
        ),
    ]
)
