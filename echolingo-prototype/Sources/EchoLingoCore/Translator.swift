import Foundation
import Core

public struct LanguagePair: Sendable, Equatable {
    public let a: String   // ISO-639-1
    public let b: String

    public init(a: String, b: String) {
        self.a = a; self.b = b
    }
}

public enum Direction: Sendable, Equatable { case aToB; case bToA }

/// LLM-backed translator. Strict prompt: source-language goes in, target
/// goes out, no editorializing or transliterations in parens.
public struct Translator: Sendable {
    public let model: ModelProvider

    public init(model: ModelProvider) {
        self.model = model
    }

    public func translate(_ text: String, pair: LanguagePair, direction: Direction) async throws -> String {
        let (from, to) = direction == .aToB ? (pair.a, pair.b) : (pair.b, pair.a)
        let system = """
        You are a professional simultaneous interpreter. Translate the user's text from \(from) to \(to).
        Output only the translation. Do NOT add transliteration, romanization, parenthetical notes, or commentary.
        Preserve the speaker's register (formal/casual). If the input is silent or unintelligible, return an empty string.
        """
        let stream = try await model.complete(
            messages: [.user(text)],
            tools: [],
            config: InferenceConfig(temperature: 0.2, maxTokens: 400, systemPrompt: system)
        )
        return try await stream.joinedText().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
