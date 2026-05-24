import Foundation
import Core

/// The scheduler. Given habits, tasks, and the current calendar context,
/// produces a list of `ScheduledCue`s for the next horizon.
///
/// In privacy mode `.strict`, falls back to `HeuristicScheduler` (no LLM).
public struct CalendarFlexEngine: Sendable {
    public let model: ModelProvider?
    public let privacy: PrivacyConfig
    public let promptBuilder: CuePromptBuilder
    public let heuristic: HeuristicScheduler

    public init(
        model: ModelProvider?,
        privacy: PrivacyConfig,
        horizonHours: Int = 4
    ) {
        self.model = model
        self.privacy = privacy
        self.promptBuilder = CuePromptBuilder(privacy: privacy, horizonHours: horizonHours)
        self.heuristic = HeuristicScheduler(horizonHours: horizonHours)
    }

    public func schedule(habits: [Habit], tasks: [Task], context: CalendarContext) async throws -> [ScheduledCue] {
        if !privacy.allowsCloudLLM || model == nil {
            return heuristic.schedule(habits: habits, tasks: tasks, context: context)
        }
        guard let model else { return [] }

        let user = try promptBuilder.userPrompt(habits: habits, tasks: tasks, context: context)
        let stream = try await model.complete(
            messages: [.user(user)],
            tools: [],
            config: InferenceConfig(
                temperature: 0.4,
                maxTokens: 800,
                systemPrompt: promptBuilder.systemPrompt()
            )
        )
        let raw = try await stream.joinedText()
        return try parseCues(raw, habits: habits, tasks: tasks)
    }

    func parseCues(_ raw: String, habits: [Habit], tasks: [Task]) throws -> [ScheduledCue] {
        guard let data = raw.data(using: .utf8) else { return [] }
        struct Envelope: Decodable {
            let cues: [Item]
            struct Item: Decodable {
                let sourceId: UUID
                let kind: String
                let scheduledFor: Date
                let reason: String
            }
        }
        let envelope: Envelope
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            envelope = try decoder.decode(Envelope.self, from: data)
        } catch {
            throw ProviderError.invalidResponse("scheduler JSON malformed: \(error.localizedDescription)")
        }
        let habitByID = Dictionary(uniqueKeysWithValues: habits.map { ($0.id, $0) })
        let taskByID = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })
        return envelope.cues.compactMap { item -> ScheduledCue? in
            if item.kind == "habit", let h = habitByID[item.sourceId] {
                return ScheduledCue(
                    sourceID: h.id, sourceKind: .habit, glyph: h.glyph,
                    title: h.name, scheduledFor: item.scheduledFor, reason: item.reason
                )
            }
            if item.kind == "task", let t = taskByID[item.sourceId] {
                return ScheduledCue(
                    sourceID: t.id, sourceKind: .task, glyph: .journal,
                    title: t.title, scheduledFor: item.scheduledFor, reason: item.reason
                )
            }
            return nil
        }
    }
}
