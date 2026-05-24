import Foundation

/// A recurring habit the user wants to build.
public struct Habit: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var name: String
    public var glyph: Glyph
    public var targetPerDay: Int
    public var preferredWindows: [TimeWindow]
    public var notes: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        glyph: Glyph,
        targetPerDay: Int = 1,
        preferredWindows: [TimeWindow] = [],
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.glyph = glyph
        self.targetPerDay = targetPerDay
        self.preferredWindows = preferredWindows
        self.notes = notes
        self.createdAt = createdAt
    }
}

/// Glyph + haptic style for a habit. Maps to an SF Symbol on the watch face.
public enum Glyph: String, Codable, Sendable, CaseIterable {
    case water = "drop.fill"
    case sun = "sun.max.fill"
    case walk = "figure.walk"
    case dog = "pawprint.fill"
    case guitar = "guitars.fill"
    case workout = "dumbbell.fill"
    case book = "book.fill"
    case meditate = "leaf.fill"
    case sleep = "bed.double.fill"
    case journal = "square.and.pencil"
}

/// A one-off task with a natural-language trigger the engine resolves.
public struct Task: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var title: String
    public var trigger: TriggerRule
    public var completed: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        trigger: TriggerRule,
        completed: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.trigger = trigger
        self.completed = completed
        self.createdAt = createdAt
    }
}

/// The structured form of a natural-language trigger phrase.
/// LLM parses "remind me to call dad when I leave the office" once into
/// `.onLocationExit(name: "Office")`; afterwards the engine reads only the
/// structured form.
public enum TriggerRule: Codable, Sendable, Equatable {
    case at(Date)
    case after(eventCategory: EventCategory)
    case before(eventCategory: EventCategory, minutes: Int)
    case onLocationExit(name: String)
    case onLocationArrive(name: String)
    case anyFreeWindow(minimumMinutes: Int)
}

public enum EventCategory: String, Codable, Sendable {
    case work
    case personal
    case meeting
    case workout
    case meal
    case sleep
    case other
}

/// User-defined preferred hours (e.g. "morning water" = 7-11am).
public struct TimeWindow: Codable, Sendable, Equatable {
    public let startHour: Int   // 0-23, local time
    public let endHour: Int

    public init(startHour: Int, endHour: Int) {
        self.startHour = startHour
        self.endHour = endHour
    }
}

/// The engine's output: a specific cue to deliver at a specific time.
public struct ScheduledCue: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let sourceID: UUID            // Habit.id or Task.id
    public let sourceKind: SourceKind
    public let glyph: Glyph
    public let title: String             // 1-line wrist-glanceable text
    public let scheduledFor: Date
    public let reason: String            // engine's rationale; surfaced in detail view

    public enum SourceKind: String, Codable, Sendable { case habit; case task }

    public init(
        id: UUID = UUID(),
        sourceID: UUID,
        sourceKind: SourceKind,
        glyph: Glyph,
        title: String,
        scheduledFor: Date,
        reason: String
    ) {
        self.id = id
        self.sourceID = sourceID
        self.sourceKind = sourceKind
        self.glyph = glyph
        self.title = title
        self.scheduledFor = scheduledFor
        self.reason = reason
    }
}
