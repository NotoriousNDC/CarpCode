import Foundation
#if canImport(CoreML)
import CoreML

public final class OnDeviceModelProvider: ModelProvider {
    public let id: String
    public let displayName: String
    public let supportsTools: Bool = false  // use ReAct text shim
    public let isOnDevice: Bool = true

    private var mlModel: MLModel?
    private var tokenizer: CoreMLTokenizer?

    public init(descriptor: OnDeviceModelDescriptor) {
        self.id = "ondevice/\(descriptor.id)"
        self.displayName = descriptor.displayName
        Task { [weak self] in
            try? await self?.load(descriptor: descriptor)
        }
    }

    private func load(descriptor: OnDeviceModelDescriptor) async throws {
        self.mlModel = try await ModelBundleLoader.load(descriptor: descriptor)
        self.tokenizer = try CoreMLTokenizer(vocabURL: descriptor.vocabURL, mergesURL: descriptor.mergesURL)
    }

    public func complete(
        messages: [Message],
        tools: [ToolDefinition],
        config: InferenceConfig
    ) async throws -> AsyncThrowingStream<CompletionChunk, Error> {
        guard let model = mlModel, let tokenizer = tokenizer else {
            return AsyncThrowingStream { continuation in
                continuation.yield(.textDelta(
                    "[On-device model not loaded. Drop a .mlpackage into CoreMLModels/ — see CoreMLModels/README.md]"
                ))
                continuation.yield(.finishReason(.stop))
                continuation.finish()
            }
        }

        let prompt = flattenMessages(messages, systemPrompt: config.systemPrompt)
        let inputTokens = tokenizer.encode(prompt)

        return makeAsyncStream { continuation in
            try await self.generate(
                model: model,
                tokenizer: tokenizer,
                inputTokens: inputTokens,
                maxNewTokens: config.maxTokens,
                temperature: config.temperature,
                continuation: continuation
            )
        }
    }

    // MARK: - Auto-regressive generation

    private func generate(
        model: MLModel,
        tokenizer: CoreMLTokenizer,
        inputTokens: [Int],
        maxNewTokens: Int,
        temperature: Float,
        continuation: AsyncThrowingStream<CompletionChunk, Error>.Continuation
    ) async throws {
        var tokens = inputTokens
        for _ in 0..<maxNewTokens {
            // Build input feature provider
            // TODO: Replace with proper MLMultiArray construction matching model input shape
            let input = try buildMLInput(tokens: tokens)
            let output = try model.prediction(from: input)
            let nextToken = try sampleLogits(output: output, temperature: temperature, eosTokenID: tokenizer.eosTokenID)

            if nextToken == tokenizer.eosTokenID { break }
            tokens.append(nextToken)
            let decoded = tokenizer.decode([nextToken])
            continuation.yield(.textDelta(decoded))
        }
        continuation.yield(.finishReason(.stop))
    }

    private func buildMLInput(tokens: [Int]) throws -> MLFeatureProvider {
        // TODO: Construct MLMultiArray from token IDs matching the model's expected input name/shape
        // Placeholder that will cause a runtime error if a real model is loaded
        throw ProviderError.modelNotLoaded("MLInput construction not yet implemented — update buildMLInput() for your model's input spec")
    }

    private func sampleLogits(output: MLFeatureProvider, temperature: Float, eosTokenID: Int) throws -> Int {
        // TODO: Extract logits array from output, apply temperature, sample via top-k
        throw ProviderError.modelNotLoaded("Logit sampling not yet implemented — update sampleLogits() for your model's output spec")
    }

    private func flattenMessages(_ messages: [Message], systemPrompt: String?) -> String {
        var parts: [String] = []
        if let sys = systemPrompt { parts.append("<|system|>\n\(sys)") }
        for msg in messages {
            let tag = msg.role == .user ? "<|user|>" : "<|assistant|>"
            parts.append("\(tag)\n\(msg.content.plainText)")
        }
        parts.append("<|assistant|>\n")
        return parts.joined(separator: "\n")
    }
}

// MARK: - Apple Foundation Models fallback (iOS 18.1+)
#if canImport(FoundationModels)
import FoundationModels

// Wraps the system on-device LLM behind the same ModelProvider interface
@available(iOS 18.1, *)
public final class AppleIntelligenceProvider: ModelProvider {
    public let id = "apple/on-device"
    public let displayName = "Apple Intelligence (On-Device)"
    public let supportsTools = false
    public let isOnDevice = true

    private let session: LanguageModelSession

    public init() {
        self.session = LanguageModelSession()
    }

    public func complete(
        messages: [Message],
        tools: [ToolDefinition],
        config: InferenceConfig
    ) async throws -> AsyncThrowingStream<CompletionChunk, Error> {
        let prompt = messages.last?.content.plainText ?? ""
        return makeAsyncStream { continuation in
            let stream = self.session.streamResponse(to: prompt)
            for try await partial in stream {
                continuation.yield(.textDelta(partial))
            }
            continuation.yield(.finishReason(.stop))
        }
    }
}
#endif

#else
// Non-Apple platforms — stub so Core compiles on Linux for tests
public final class OnDeviceModelProvider: ModelProvider {
    public let id = "ondevice/stub"
    public let displayName = "On-Device (unavailable on this platform)"
    public let supportsTools = false
    public let isOnDevice = true

    public init() {}

    public func complete(
        messages: [Message], tools: [ToolDefinition], config: InferenceConfig
    ) async throws -> AsyncThrowingStream<CompletionChunk, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(.textDelta("[Core ML not available on this platform]"))
            continuation.yield(.finishReason(.stop))
            continuation.finish()
        }
    }
}
#endif
