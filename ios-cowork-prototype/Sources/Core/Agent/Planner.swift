import Foundation

public struct Planner: Sendable {
    private let provider: any ModelProvider
    private let config: InferenceConfig

    public init(provider: any ModelProvider, config: InferenceConfig = InferenceConfig()) {
        self.provider = provider
        self.config = config
    }

    public func decompose(task: String) async throws -> AgentPlan {
        let planConfig = InferenceConfig(temperature: 0.3, maxTokens: 512)
        let messages: [Message] = [.user(PromptTemplates.planPrompt(task: task))]
        let stream = try await provider.complete(messages: messages, tools: [], config: planConfig)

        var accumulated = ""
        for try await chunk in stream {
            if case .textDelta(let delta) = chunk {
                accumulated += delta
            }
        }

        return parse(accumulated) ?? .fallback
    }

    private func parse(_ text: String) -> AgentPlan? {
        // Extract JSON object from the response (model may add surrounding text)
        guard let jsonRange = extractJSONRange(from: text),
              let data = String(text[jsonRange]).data(using: .utf8),
              let plan = try? JSONCoder.decoder.decode(AgentPlan.self, from: data) else {
            return nil
        }
        return plan.subtasks.isEmpty ? nil : plan
    }

    private func extractJSONRange(from text: String) -> Range<String.Index>? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}") else { return nil }
        return start...end
    }
}
