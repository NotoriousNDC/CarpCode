import Foundation

/// A single chunk yielded from a streaming completion.
public enum CompletionChunk: Sendable {
    case textDelta(String)
    case toolCallDelta(index: Int, id: String?, name: String?, argumentsDelta: String)
    case finishReason(FinishReason)
}

public enum FinishReason: String, Sendable {
    case stop
    case toolUse
    case length
    case contentFilter
}

public struct InferenceConfig: Sendable {
    public var temperature: Float
    public var maxTokens: Int
    public var systemPrompt: String?

    public init(temperature: Float = 0.7, maxTokens: Int = 2048, systemPrompt: String? = nil) {
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.systemPrompt = systemPrompt
    }
}

public protocol ModelProvider: Sendable {
    var id: String { get }
    var displayName: String { get }
    var supportsTools: Bool { get }

    func complete(
        messages: [Message],
        tools: [ToolDefinition],
        config: InferenceConfig
    ) async throws -> AsyncThrowingStream<CompletionChunk, Error>
}

public enum ProviderError: Error, LocalizedError {
    case missingAPIKey(String)
    case invalidResponse(String)
    case privacyBlocked(String)
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey(let v): "No API key set for \(v). Add it in Settings."
        case .invalidResponse(let msg): "Invalid response: \(msg)"
        case .privacyBlocked(let reason): "Blocked by privacy config: \(reason)"
        case .unknown(let msg): msg
        }
    }
}
