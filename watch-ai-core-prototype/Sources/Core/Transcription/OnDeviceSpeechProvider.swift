import Foundation
#if canImport(Speech)
import Speech
import AVFoundation
#endif

/// On-device transcription via `SFSpeechRecognizer`. Used as the Strict-mode
/// fallback when cloud Whisper is disabled.
///
/// Quality is meaningfully lower than Whisper, especially for non-English
/// audio and noisy environments — call out the trade-off in app UI.
public final class OnDeviceSpeechProvider: TranscriptionProvider, @unchecked Sendable {
    public let id = "apple/sfspeech"
    public let isOnDevice = true

    public init() {}

    public func transcribe(audioURL: URL, options: TranscriptionOptions) async throws -> Transcript {
#if canImport(Speech)
        let locale: Locale
        if let hint = options.languageHint {
            locale = Locale(identifier: hint)
        } else {
            locale = Locale.current
        }
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw ProviderError.invalidResponse("SFSpeechRecognizer unavailable for \(locale.identifier)")
        }
        // Prefer fully on-device so audio doesn't leak to Apple's servers.
        if recognizer.supportsOnDeviceRecognition == false {
            throw ProviderError.privacyBlocked("On-device recognition unavailable for \(locale.identifier); falling back would require cloud.")
        }
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = false

        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    continuation.resume(throwing: error); return
                }
                guard let result, result.isFinal else { return }
                let text = result.bestTranscription.formattedString
                let segments = result.bestTranscription.segments.map {
                    Transcript.Segment(
                        start: $0.timestamp,
                        end: $0.timestamp + $0.duration,
                        text: $0.substring
                    )
                }
                let duration = segments.last.map { $0.end } ?? 0
                continuation.resume(returning: Transcript(
                    text: text,
                    language: locale.identifier,
                    segments: segments,
                    durationSeconds: duration
                ))
            }
        }
#else
        throw ProviderError.invalidResponse("Speech framework unavailable on this platform")
#endif
    }
}
