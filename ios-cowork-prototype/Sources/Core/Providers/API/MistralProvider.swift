import Foundation

// Mistral uses the OpenAI-compatible chat completions format
public final class MistralProvider: APIModelProvider, ModelProvider {
    public override var id: String { "mistral/\(model)" }
    public override var displayName: String { "Mistral (\(model))" }
    public override var supportsTools: Bool { true }

    private let openAIProxy: OpenAIProvider

    public init(model: String, apiKey: String) {
        let baseURL = URL(string: "https://api.mistral.ai/v1")!
        self.openAIProxy = OpenAIProvider(model: model, apiKey: apiKey, baseURL: baseURL)
        super.init(model: model, apiKey: apiKey, baseURL: baseURL)
    }

    public func complete(
        messages: [Message],
        tools: [ToolDefinition],
        config: InferenceConfig
    ) async throws -> AsyncThrowingStream<CompletionChunk, Error> {
        // Mistral's API is OpenAI-compatible — delegate entirely
        try await openAIProxy.complete(messages: messages, tools: tools, config: config)
    }
}
