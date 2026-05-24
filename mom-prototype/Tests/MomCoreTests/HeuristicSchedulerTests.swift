import XCTest
@testable import MomCore

final class HeuristicSchedulerTests: XCTestCase {
    func testSpacesHabitAcrossHorizon() {
        let now = Date(timeIntervalSinceReferenceDate: 0)
        let scheduler = HeuristicScheduler(horizonHours: 4)
        let habit = Habit(name: "Water", glyph: .water, targetPerDay: 4)
        let context = CalendarContext(now: now, events: [], lastWorkoutAt: nil, lastSleep: nil)
        let cues = scheduler.schedule(habits: [habit], tasks: [], context: context)
        XCTAssertFalse(cues.isEmpty, "Should emit at least one habit cue inside the horizon")
        XCTAssertTrue(cues.allSatisfy { $0.sourceID == habit.id })
        XCTAssertTrue(cues.allSatisfy { $0.scheduledFor > now })
    }

    func testSkipsBusySlots() {
        let now = Date(timeIntervalSinceReferenceDate: 0)
        // Busy for the full horizon
        let busyEvent = CalendarEvent(
            start: now,
            end: now.addingTimeInterval(3600 * 24),
            category: .meeting
        )
        let scheduler = HeuristicScheduler(horizonHours: 4)
        let habit = Habit(name: "Water", glyph: .water, targetPerDay: 4)
        let context = CalendarContext(now: now, events: [busyEvent], lastWorkoutAt: nil, lastSleep: nil)
        let cues = scheduler.schedule(habits: [habit], tasks: [], context: context)
        XCTAssertTrue(cues.isEmpty, "All slots covered by a calendar event — should emit nothing")
    }

    func testEmitsExplicitTimeTask() {
        let now = Date(timeIntervalSinceReferenceDate: 0)
        let when = now.addingTimeInterval(3600)
        let task = MomCore.Task(title: "Call dad", trigger: .at(when))
        let context = CalendarContext(now: now, events: [], lastWorkoutAt: nil, lastSleep: nil)
        let cues = HeuristicScheduler(horizonHours: 4).schedule(habits: [], tasks: [task], context: context)
        XCTAssertEqual(cues.count, 1)
        XCTAssertEqual(cues.first?.title, "Call dad")
        XCTAssertEqual(cues.first?.scheduledFor, when)
    }
}
