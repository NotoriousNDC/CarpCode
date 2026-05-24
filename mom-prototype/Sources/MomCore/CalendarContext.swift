import Foundation

/// Read-only snapshot of the user's day. The engine reasons against this
/// rather than calling EventKit/HealthKit directly, which keeps the engine
/// unit-testable and lets us swap data sources behind a protocol.
public struct CalendarContext: Codable, Sendable {
    public let now: Date
    public let events: [CalendarEvent]
    public let lastWorkoutAt: Date?
    public let lastSleep: SleepWindow?

    public init(now: Date, events: [CalendarEvent], lastWorkoutAt: Date?, lastSleep: SleepWindow?) {
        self.now = now
        self.events = events
        self.lastWorkoutAt = lastWorkoutAt
        self.lastSleep = lastSleep
    }
}

public struct CalendarEvent: Codable, Sendable {
    public let start: Date
    public let end: Date
    public let category: EventCategory
    /// Only included in Convenience mode; nil otherwise.
    public let title: String?
    public let isAllDay: Bool

    public init(start: Date, end: Date, category: EventCategory, title: String? = nil, isAllDay: Bool = false) {
        self.start = start
        self.end = end
        self.category = category
        self.title = title
        self.isAllDay = isAllDay
    }

    public var durationMinutes: Int {
        Int(end.timeIntervalSince(start) / 60)
    }
}

public struct SleepWindow: Codable, Sendable {
    public let bedtime: Date
    public let wakeTime: Date

    public init(bedtime: Date, wakeTime: Date) {
        self.bedtime = bedtime
        self.wakeTime = wakeTime
    }
}

/// Protocol so the watch + phone can plug in real EventKit/HealthKit
/// readers and tests can plug in a stub.
public protocol CalendarContextProvider: Sendable {
    func currentContext() async throws -> CalendarContext
}
