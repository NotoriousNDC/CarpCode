import Foundation

/// User-facing privacy posture. Surfaced at the top of every app's settings.
///
/// Privacy decisions made via this enum cascade through every feature in
/// every prototype that depends on `Core`. The intent is that a single
/// switch communicates a coherent stance.
public enum PrivacyMode: String, Codable, Sendable, CaseIterable {
    /// On-device only where feasible. Cloud calls require per-session consent.
    /// No telemetry. Logs redacted. Whisper falls back to `SFSpeechRecognizer`.
    case strict

    /// Default. Cloud LLM / Whisper allowed. Payloads minimized
    /// (no raw HealthKit samples, no calendar titles, etc.). No analytics.
    case balanced

    /// Same as Balanced but relaxes minimization for richer context
    /// (e.g. event titles included in scheduler prompts).
    case convenience

    public var displayName: String {
        switch self {
        case .strict: "Strict"
        case .balanced: "Balanced"
        case .convenience: "Convenience"
        }
    }

    public var summary: String {
        switch self {
        case .strict:
            "On-device only where possible. Cloud calls require explicit consent."
        case .balanced:
            "Cloud LLM allowed. Payloads minimized. No analytics."
        case .convenience:
            "Cloud LLM allowed with richer context for better results."
        }
    }
}

/// The privacy decisions a given feature should make. Built from `PrivacyMode`.
///
/// Features should read this struct rather than branching on `PrivacyMode`
/// directly, so new modes don't require touching every call site.
public struct PrivacyConfig: Sendable {
    public let mode: PrivacyMode

    public init(mode: PrivacyMode = .balanced) {
        self.mode = mode
    }

    // MARK: Cloud calls

    /// May the app send transcribable audio to a cloud Whisper endpoint?
    public var allowsCloudTranscription: Bool {
        switch mode {
        case .strict: false
        case .balanced, .convenience: true
        }
    }

    /// May the app send text prompts to a cloud LLM?
    public var allowsCloudLLM: Bool {
        switch mode {
        case .strict: false
        case .balanced, .convenience: true
        }
    }

    /// Cloud calls require an explicit per-session consent tap. Strict only.
    public var requiresPerSessionConsent: Bool {
        mode == .strict
    }

    // MARK: Minimization

    /// May calendar event titles / attendees be included in cloud prompts?
    /// (Used by `mom-prototype`'s `CalendarFlexEngine`.)
    public var allowsCalendarTitles: Bool {
        mode == .convenience
    }

    /// May raw HealthKit samples (vs. aggregated summary stats) leave the device?
    /// Always false — even Convenience keeps health data summarized.
    public var allowsRawHealthSamples: Bool { false }

    /// Persist transcripts / chats across sessions?
    public var allowsPersistence: Bool {
        switch mode {
        case .strict: false
        case .balanced, .convenience: true
        }
    }

    // MARK: Logging

    /// Apply `Redactor` to logged strings? Always on except for Convenience.
    public var redactsLogs: Bool { mode != .convenience }
}
