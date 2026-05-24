import Foundation

public struct Note: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var title: String
    public var transcript: String
    public var cleanedBody: String?
    public var actionItems: [String]
    public var capturedAt: Date
    public var durationSeconds: Double
    public var languageCode: String?

    public init(
        id: UUID = UUID(),
        title: String = "Untitled note",
        transcript: String,
        cleanedBody: String? = nil,
        actionItems: [String] = [],
        capturedAt: Date = Date(),
        durationSeconds: Double = 0,
        languageCode: String? = nil
    ) {
        self.id = id
        self.title = title
        self.transcript = transcript
        self.cleanedBody = cleanedBody
        self.actionItems = actionItems
        self.capturedAt = capturedAt
        self.durationSeconds = durationSeconds
        self.languageCode = languageCode
    }
}
