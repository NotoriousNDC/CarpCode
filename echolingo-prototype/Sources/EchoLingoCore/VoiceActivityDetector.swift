import Foundation

/// Minimal energy-threshold VAD. Feed it normalized [0, 1] meter samples
/// every N ms; it emits "speech started" / "speech ended" events so the
/// caller can decide when to chunk audio for Whisper.
///
/// Not a serious VAD — replace with WebRTC VAD or Silero when ready.
public final class VoiceActivityDetector: @unchecked Sendable {
    public enum Event: Sendable, Equatable {
        case speechStart
        case speechEnd
    }

    private let activeThreshold: Float
    private let silenceThreshold: Float
    private let minSilenceMs: Int

    private var isSpeaking = false
    private var silenceStreakMs = 0

    public init(
        activeThreshold: Float = 0.15,
        silenceThreshold: Float = 0.07,
        minSilenceMs: Int = 700
    ) {
        self.activeThreshold = activeThreshold
        self.silenceThreshold = silenceThreshold
        self.minSilenceMs = minSilenceMs
    }

    public func feed(meter: Float, deltaMs: Int) -> Event? {
        if !isSpeaking && meter > activeThreshold {
            isSpeaking = true
            silenceStreakMs = 0
            return .speechStart
        }
        if isSpeaking {
            if meter < silenceThreshold {
                silenceStreakMs += deltaMs
                if silenceStreakMs >= minSilenceMs {
                    isSpeaking = false
                    silenceStreakMs = 0
                    return .speechEnd
                }
            } else {
                silenceStreakMs = 0
            }
        }
        return nil
    }
}
