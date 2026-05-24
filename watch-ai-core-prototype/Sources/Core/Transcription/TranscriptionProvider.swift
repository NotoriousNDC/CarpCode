import Foundation

public struct Transcript: Sendable {
    public let text: String
    public let language: String?
    public let segments: [Segment]
    public let durationSeconds: Double

    public struct Segment: Sendable {
        public let start: Double
        public let end: Double
        public let text: String
        public init(start: Double, end: Double, text: String) {
            self.start = start; self.end = end; self.text = text
        }
    }

    public init(text: String, language: String? = nil, segments: [Segment] = [], durationSeconds: Double = 0) {
        self.text = text
        self.language = language
        self.segments = segments
        self.durationSeconds = durationSeconds
    }
}

public struct TranscriptionOptions: Sendable {
    /// ISO-639-1 hint to improve accuracy (e.g. "en", "es").
    public var languageHint: String?
    /// Optional prompt to bias Whisper toward names/jargon.
    public var prompt: String?
    /// Return word/segment timestamps. Increases cost.
    public var withTimestamps: Bool

    public init(languageHint: String? = nil, prompt: String? = nil, withTimestamps: Bool = false) {
        self.languageHint = languageHint
        self.prompt = prompt
        self.withTimestamps = withTimestamps
    }
}

public protocol TranscriptionProvider: Sendable {
    var id: String { get }
    var isOnDevice: Bool { get }
    func transcribe(audioURL: URL, options: TranscriptionOptions) async throws -> Transcript
}
