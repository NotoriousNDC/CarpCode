import Foundation
import Core

/// State machine for a single ask. Drives the watch UI from `.idle` through
/// recording, transcribing, answering, and back.
public enum AskState: Sendable, Equatable {
    case idle
    case recording
    case transcribing
    case answering(partial: String)
    case done(answer: String)
    case error(String)
}

public actor AskSession {
    public let model: ModelProvider
    public let transcription: TranscriptionProvider
    public let recorder: AudioRecorder
    public let privacy: PrivacyConfig
    public let historyTimeout: TimeInterval

    private var history: [Message] = []
    private var lastTurnAt: Date = .distantPast

    public init(
        model: ModelProvider,
        transcription: TranscriptionProvider,
        recorder: AudioRecorder = AudioRecorder(),
        privacy: PrivacyConfig = .init(),
        historyTimeout: TimeInterval = 300
    ) {
        self.model = model
        self.transcription = transcription
        self.recorder = recorder
        self.privacy = privacy
        self.historyTimeout = historyTimeout
    }

    public func ask(audioURL: URL, languageHint: String? = nil) -> AsyncThrowingStream<AskState, Error> {
        AsyncThrowingStream { continuation in
            _Concurrency.Task {
                do {
                    if Date().timeIntervalSince(lastTurnAt) > historyTimeout {
                        history.removeAll()
                    }
                    continuation.yield(.transcribing)
                    let transcript = try await transcription.transcribe(
                        audioURL: audioURL,
                        options: TranscriptionOptions(languageHint: languageHint)
                    )
                    try? FileManager.default.removeItem(at: audioURL)
                    history.append(.user(transcript.text))

                    continuation.yield(.answering(partial: ""))
                    var accumulated = ""
                    let stream = try await model.complete(
                        messages: history,
                        tools: [],
                        config: InferenceConfig(
                            temperature: 0.5,
                            maxTokens: 800,
                            systemPrompt: "You answer in under 80 words unless asked for more. Plain prose; no markdown."
                        )
                    )
                    for try await chunk in stream {
                        if case .textDelta(let t) = chunk {
                            accumulated += t
                            continuation.yield(.answering(partial: accumulated))
                        }
                    }
                    history.append(.assistant(accumulated))
                    lastTurnAt = Date()
                    continuation.yield(.done(answer: accumulated))
                    continuation.finish()
                } catch {
                    continuation.yield(.error(error.localizedDescription))
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    public func clearHistory() {
        history.removeAll()
        lastTurnAt = .distantPast
    }
}
