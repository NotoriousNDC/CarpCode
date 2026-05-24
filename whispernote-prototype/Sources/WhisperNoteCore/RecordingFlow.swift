import Foundation
import Core

/// Orchestrates the full capture flow on the phone side:
///   1. Receive audio file from watch (or recorded locally if testing on iOS).
///   2. Transcribe via `TranscriptionProvider`.
///   3. Post-process via `NoteProcessor`.
///   4. Hand result to the storage layer.
///   5. Delete the audio file from disk.
public actor RecordingFlow {
    public let transcription: TranscriptionProvider
    public let processor: NoteProcessor
    public let privacy: PrivacyConfig
    public let onNoteReady: @Sendable (Note) -> Void

    public init(
        transcription: TranscriptionProvider,
        processor: NoteProcessor,
        privacy: PrivacyConfig,
        onNoteReady: @escaping @Sendable (Note) -> Void
    ) {
        self.transcription = transcription
        self.processor = processor
        self.privacy = privacy
        self.onNoteReady = onNoteReady
    }

    public func process(audioURL: URL, languageHint: String? = nil) async throws -> Note {
        defer {
            try? FileManager.default.removeItem(at: audioURL)
        }
        let transcript = try await transcription.transcribe(
            audioURL: audioURL,
            options: TranscriptionOptions(languageHint: languageHint, withTimestamps: false)
        )
        let note = try await processor.process(transcript: transcript)
        onNoteReady(note)
        return note
    }
}
