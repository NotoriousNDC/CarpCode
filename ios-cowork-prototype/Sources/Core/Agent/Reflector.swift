import Foundation

public struct Reflector: Sendable {
    private let provider: any ModelProvider

    public init(provider: any ModelProvider) {
        self.provider = provider
    }

    public func evaluate(task: String, history: [Message], stepsCompleted: Int) async throws -> ReflectDecision {
        var messages = history
        messages.append(.user(PromptTemplates.reflectPrompt(task: task, stepsCompleted: stepsCompleted)))

        let config = InferenceConfig(temperature: 0.1, maxTokens: 256)
        let stream = try await provider.complete(messages: messages, tools: [], config: config)

        var accumulated = ""
        for try await chunk in stream {
            if case .textDelta(let delta) = chunk {
                accumulated += delta
            }
        }

        return parse(accumulated) ?? .done(summary: "Task evaluation complete.")
    }

    private func parse(_ text: String) -> ReflectDecision? {
        guard let jsonStart = text.firstIndex(of: "{"),
              let jsonEnd = text.lastIndex(of: "}") else { return nil }
        let jsonString = String(text[jsonStart...jsonEnd])
        guard let data = jsonString.data(using: .utf8),
              let response = try? JSONCoder.decoder.decode(ReflectResponse.self, from: data) else {
            return nil
        }
        if response.done {
            return .done(summary: response.summary ?? "Task completed.")
        } else {
            return .continue(nextAction: response.nextAction ?? "Continue working on the task.")
        }
    }
}
