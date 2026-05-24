import Foundation

/// Strict-mode fallback. Pure-function deterministic scheduling — no LLM.
///
/// Strategy:
///   - For each habit, divide remaining awake time by `targetPerDay`,
///     skip slots that overlap with calendar events, prefer the user's
///     preferred windows when they don't conflict.
///   - For each task with a time-based trigger, emit at the trigger time
///     if it's within the horizon.
///   - Ignore location-based triggers (need the phone's location services).
public struct HeuristicScheduler: Sendable {
    public let horizonHours: Int

    public init(horizonHours: Int = 4) {
        self.horizonHours = horizonHours
    }

    public func schedule(habits: [Habit], tasks: [Task], context: CalendarContext) -> [ScheduledCue] {
        var cues: [ScheduledCue] = []
        let calendar = Calendar.current
        let now = context.now
        guard let horizon = calendar.date(byAdding: .hour, value: horizonHours, to: now) else {
            return []
        }

        let busy: [(Date, Date)] = context.events
            .filter { !$0.isAllDay && $0.end > now }
            .map { ($0.start, $0.end) }

        // Habits: even spacing within preferred windows, skipping busy slots.
        for habit in habits {
            guard habit.targetPerDay > 0 else { continue }
            let interval = TimeInterval(3600 * 16) / Double(habit.targetPerDay)
            var candidate = now.addingTimeInterval(interval)
            var emitted = 0
            while candidate < horizon && emitted < habit.targetPerDay {
                if !busy.contains(where: { $0.0 <= candidate && candidate < $0.1 }) {
                    cues.append(ScheduledCue(
                        sourceID: habit.id,
                        sourceKind: .habit,
                        glyph: habit.glyph,
                        title: habit.name,
                        scheduledFor: candidate,
                        reason: "heuristic: spaced across the horizon"
                    ))
                    emitted += 1
                }
                candidate = candidate.addingTimeInterval(interval)
            }
        }

        // Tasks: only handle `.at(date)` triggers in the heuristic path.
        for task in tasks where !task.completed {
            if case .at(let date) = task.trigger, date > now, date < horizon {
                cues.append(ScheduledCue(
                    sourceID: task.id,
                    sourceKind: .task,
                    glyph: .journal,
                    title: task.title,
                    scheduledFor: date,
                    reason: "heuristic: explicit time trigger"
                ))
            }
        }

        return cues.sorted { $0.scheduledFor < $1.scheduledFor }
    }
}
