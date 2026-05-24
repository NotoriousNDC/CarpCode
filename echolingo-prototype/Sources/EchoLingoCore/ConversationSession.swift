import Foundation
import Core

public struct TranslatedUtterance: Sendable {
    public let direction: Direction
    public let original: String
    public let translated: String
    public let at: Date
}

/// Orchestrates a continuous translation session. Receives chunked audio
/// URLs (one per VAD-detected utterance) and emits translated utterances.
public actor ConversationSession {
    public let pair: LanguagePair
    public let transcription: TranscriptionProvider
    public let translator: Translator
    public var direction: Direction

    public init(
        pair: LanguagePair,
        transcription: TranscriptionProvider,
        translator: Translator,
        direction: Direction = .aToB
    ) {
        self.pair = pair
        self.transcription = transcription
        self.translator = translator
        self.direction = direction
    }

    public func toggleDirection() {
        direction = direction == .aToB ? .bToA : .aToB
    }

    public func process(chunkURL: URL) async throws -> TranslatedUtterance? {
        defer { try? FileManager.default.removeItem(at: chunkURL) }
        let sourceLang = direction == .aToB ? pair.a : pair.b
        let transcript = try await transcription.transcribe(
            audioURL: chunkURL,
            options: TranscriptionOptions(languageHint: sourceLang)
        )
        guard !transcript.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        let translated = try await translator.translate(transcript.text, pair: pair, direction: direction)
        guard !translated.isEmpty else { return nil }
        return TranslatedUtterance(
            direction: direction,
            original: transcript.text,
            translated: translated,
            at: Date()
        )
    }
}
