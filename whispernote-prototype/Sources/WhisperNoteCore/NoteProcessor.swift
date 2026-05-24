import Foundation
import Core

/// Takes a raw `Transcript` and runs the LLM cleanup pipeline:
///   1. Disfluency cleanup (uh / um / repeated phrases removed)
///   2. Title generation
///   3. Action-item extraction
///
/// In Strict privacy mode this becomes a no-op (the raw transcript is the note).
public struct NoteProcessor: Sendable {
    public let model: ModelProvider
    public let privacy: PrivacyConfig

    public init(model: ModelProvider, privacy: PrivacyConfig) {
        self.model = model
        self.privacy = privacy
    }

    public func process(transcript: Transcript) async throws -> Note {
        let base = Note(
            transcript: transcript.text,
            capturedAt: Date(),
            durationSeconds: transcript.durationSeconds,
            languageCode: transcript.language
        )
        guard privacy.allowsCloudLLM else { return base }

        let prompt = """
        You are formatting a spoken voice memo into a usable note.
        The input is a raw Whisper transcript and may contain disfluencies, false starts, and run-on phrasing.

        Return JSON with exactly these keys:
        - "title": short (≤ 60 char) title.
        - "body": cleaned-up version of the memo, preserving meaning. Don't editorialize.
        - "actions": array of explicit action items the speaker stated (may be empty).

        Transcript:
        \(transcript.text)
        """

        let stream = try await model.complete(
            messages: [
                .system("You return only valid JSON, no markdown fences."),
                .user(prompt),
            ],
            tools: [],
            config: InferenceConfig(temperature: 0.2, maxTokens: 1500)
        )
        let raw = try await stream.joinedText()
        let parsed = try parseResponse(raw)
        return Note(
            id: base.id,
            title: parsed.title,
            transcript: transcript.text,
            cleanedBody: parsed.body,
            actionItems: parsed.actions,
            capturedAt: base.capturedAt,
            durationSeconds: base.durationSeconds,
            languageCode: base.languageCode
        )
    }

    struct ParsedResponse: Codable {
        let title: String
        let body: String
        let actions: [String]
    }

    func parseResponse(_ raw: String) throws -> ParsedResponse {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let stripped: String
        if trimmed.hasPrefix("```") {
            // Defensive: strip ``` fences even though we asked the model not to use them.
            let dropFirst = trimmed.drop { $0 != "\n" }.dropFirst()
            stripped = String(dropFirst.split(separator: "```").first ?? "")
        } else {
            stripped = trimmed
        }
        guard let data = stripped.data(using: .utf8) else {
            throw ProviderError.invalidResponse("note response not UTF-8")
        }
        return try JSONCoder.decoder.decode(ParsedResponse.self, from: data)
    }
}
