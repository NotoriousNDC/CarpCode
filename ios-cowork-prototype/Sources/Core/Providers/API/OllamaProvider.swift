import Foundation

// Ollama exposes an OpenAI-compatible /api/chat endpoint at localhost:11434
// No API key required — useful for on-Mac private inference
public final class OllamaProvider: APIModelProvider, ModelProvider {
    public override var id: String { "ollama/\(model)" }
    public override var displayName: String { "Ollama (\(model))" }
    public override var supportsTools: Bool { true }

    private let openAIProxy: OpenAIProvider

    public init(model: String, baseURL: URL = URL(string: "http://localhost:11434/v1")!) {
        self.openAIProxy = OpenAIProvider(model: model, apiKey: "ollama", baseURL: baseURL)
        super.init(model: model, apiKey: "ollama", baseURL: baseURL)
    }

    public func complete(
        messages: [Message],
        tools: [ToolDefinition],
        config: InferenceConfig
    ) async throws -> AsyncThrowingStream<CompletionChunk, Error> {
        try await openAIProxy.complete(messages: messages, tools: tools, config: config)
    }
}
