import Foundation
import Core

// Deterministic provider for unit tests — no network, no ML inference
public final class MockModelProvider: ModelProvider, Sendable {
    public let id: String
    public let displayName: String
    public let supportsTools: Bool
    public let isOnDevice: Bool = false

    // Configure the response the mock will emit
    public var responses: [String]
    public var toolCallsToEmit: [[ToolCall]]
    private var callIndex = 0

    public init(
        id: String = "mock",
        displayName: String = "Mock Provider",
        supportsTools: Bool = true,
        responses: [String] = ["Task completed."],
        toolCallsToEmit: [[ToolCall]] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.supportsTools = supportsTools
        self.responses = responses
        self.toolCallsToEmit = toolCallsToEmit
    }

    public func complete(
        messages: [Message],
        tools: [ToolDefinition],
        config: InferenceConfig
    ) async throws -> AsyncThrowingStream<CompletionChunk, Error> {
        let index = callIndex
        callIndex += 1
        let text = index < responses.count ? responses[index] : responses.last ?? ""
        let calls = index < toolCallsToEmit.count ? toolCallsToEmit[index] : []

        return AsyncThrowingStream { continuation in
            // Emit tool call deltas first
            for (i, call) in calls.enumerated() {
                continuation.yield(.toolCallDelta(index: i, id: call.id, name: call.name, argumentsDelta: ""))
                continuation.yield(.toolCallDelta(index: i, id: nil, name: nil, argumentsDelta: call.input))
            }
            if !calls.isEmpty {
                continuation.yield(.finishReason(.toolUse))
            } else {
                // Stream text word by word
                for word in text.components(separatedBy: " ") {
                    continuation.yield(.textDelta(word + " "))
                }
                continuation.yield(.finishReason(.stop))
            }
            continuation.finish()
        }
    }

    public func reset() {
        callIndex = 0
    }
}
