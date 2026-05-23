import Foundation

// A single streamed chunk from a model provider
public enum CompletionChunk: Sendable {
    case textDelta(String)
    // Tool call streaming — arguments arrive incrementally
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
    // false for on-device nanoGPT; true for all API providers
    var supportsTools: Bool { get }
    var isOnDevice: Bool { get }

    func complete(
        messages: [Message],
        tools: [ToolDefinition],
        config: InferenceConfig
    ) async throws -> AsyncThrowingStream<CompletionChunk, Error>
}

public enum ProviderError: Error, LocalizedError {
    case unknownVendor(String)
    case missingAPIKey(String)
    case networkError(String)
    case modelNotLoaded(String)
    case invalidResponse(String)
    case rateLimited
    case contextWindowExceeded

    public var errorDescription: String? {
        switch self {
        case .unknownVendor(let v): return "Unknown provider: \(v)"
        case .missingAPIKey(let v): return "No API key set for \(v). Add it in Settings."
        case .networkError(let msg): return "Network error: \(msg)"
        case .modelNotLoaded(let id): return "On-device model '\(id)' not loaded. See CoreMLModels/README.md."
        case .invalidResponse(let msg): return "Invalid response: \(msg)"
        case .rateLimited: return "Rate limited. Please wait before retrying."
        case .contextWindowExceeded: return "Context window exceeded. Start a new session."
        }
    }
}
