import Foundation
import Core

/// Builds the LLM prompt for the next scheduling round.
/// Centralizes privacy decisions: only fields the privacy mode allows
/// are stamped into the prompt.
public struct CuePromptBuilder: Sendable {
    public let privacy: PrivacyConfig
    public let horizonHours: Int

    public init(privacy: PrivacyConfig, horizonHours: Int = 4) {
        self.privacy = privacy
        self.horizonHours = horizonHours
    }

    public func systemPrompt() -> String {
        """
        You schedule habit + task cues for a wrist-worn assistant called Mom.
        Output is JSON, no commentary. Schema:

        {
          "cues": [
            { "source_id": "<uuid>", "kind": "habit|task", "scheduled_for": "<ISO8601>", "reason": "short rationale" }
          ]
        }

        Constraints:
        - Don't schedule cues during scheduled events unless the event itself is the trigger.
        - Don't stack cues less than 15 minutes apart unless explicitly justified.
        - Prefer the user's preferred windows when present.
        - Each cue's `scheduled_for` must be within the next \(horizonHours) hours.
        - If you would suggest more than 8 cues, pick the 8 best.
        """
    }

    public func userPrompt(habits: [Habit], tasks: [Task], context: CalendarContext) throws -> String {
        let snapshot = ContextSnapshot(
            now: context.now,
            horizonHours: horizonHours,
            events: context.events.map { ev in
                EventSnapshot(
                    start: ev.start,
                    end: ev.end,
                    category: ev.category.rawValue,
                    title: privacy.allowsCalendarTitles ? ev.title : nil
                )
            },
            lastWorkoutAt: context.lastWorkoutAt,
            habits: habits.map {
                HabitSnapshot(id: $0.id, name: $0.name, glyph: $0.glyph.rawValue,
                              targetPerDay: $0.targetPerDay, windows: $0.preferredWindows)
            },
            tasks: tasks.filter { !$0.completed }.map {
                TaskSnapshot(id: $0.id, title: $0.title, trigger: String(describing: $0.trigger))
            }
        )
        let data = try JSONCoder.encoder.encode(snapshot)
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    // MARK: Snapshot DTOs (kept private to the prompt layer)

    struct ContextSnapshot: Codable {
        let now: Date
        let horizonHours: Int
        let events: [EventSnapshot]
        let lastWorkoutAt: Date?
        let habits: [HabitSnapshot]
        let tasks: [TaskSnapshot]
    }
    struct EventSnapshot: Codable {
        let start: Date
        let end: Date
        let category: String
        let title: String?
    }
    struct HabitSnapshot: Codable {
        let id: UUID
        let name: String
        let glyph: String
        let targetPerDay: Int
        let windows: [TimeWindow]
    }
    struct TaskSnapshot: Codable {
        let id: UUID
        let title: String
        let trigger: String
    }
}
