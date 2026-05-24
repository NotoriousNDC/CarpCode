import XCTest
@testable import MomCore
import Core

final class CuePromptBuilderTests: XCTestCase {
    func testBalancedModeExcludesEventTitles() throws {
        let builder = CuePromptBuilder(privacy: PrivacyConfig(mode: .balanced))
        let context = CalendarContext(
            now: Date(),
            events: [CalendarEvent(
                start: Date(), end: Date().addingTimeInterval(3600),
                category: .meeting, title: "Quarterly board review"
            )],
            lastWorkoutAt: nil,
            lastSleep: nil
        )
        let prompt = try builder.userPrompt(habits: [], tasks: [], context: context)
        XCTAssertFalse(prompt.contains("Quarterly board review"),
                       "Event titles must not leak in Balanced mode")
    }

    func testConvenienceModeIncludesEventTitles() throws {
        let builder = CuePromptBuilder(privacy: PrivacyConfig(mode: .convenience))
        let context = CalendarContext(
            now: Date(),
            events: [CalendarEvent(
                start: Date(), end: Date().addingTimeInterval(3600),
                category: .meeting, title: "Quarterly board review"
            )],
            lastWorkoutAt: nil,
            lastSleep: nil
        )
        let prompt = try builder.userPrompt(habits: [], tasks: [], context: context)
        XCTAssertTrue(prompt.contains("Quarterly board review"))
    }
}
