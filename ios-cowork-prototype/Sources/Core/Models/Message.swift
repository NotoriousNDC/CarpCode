import Foundation

public enum Role: String, Codable, Sendable {
    case system
    case user
    case assistant
    case tool
}

public enum ContentPart: Codable, Sendable {
    case text(String)
    case image(base64: String, mimeType: String)
}

public enum MessageContent: Codable, Sendable {
    case text(String)
    case toolResult(toolCallID: String, content: String, isError: Bool)
    case toolUse(id: String, name: String, input: String)   // input is raw JSON string
    case multipart([ContentPart])

    public var plainText: String {
        switch self {
        case .text(let s): return s
        case .toolResult(_, let c, _): return c
        case .toolUse(_, let name, let input): return "[\(name)] \(input)"
        case .multipart(let parts):
            return parts.compactMap { if case .text(let t) = $0 { return t } else { return nil } }.joined(separator: " ")
        }
    }
}

public struct Message: Identifiable, Codable, Sendable {
    public let id: UUID
    public let role: Role
    public var content: MessageContent
    public let timestamp: Date

    public init(id: UUID = UUID(), role: Role, content: MessageContent, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }

    // Convenience constructors
    public static func system(_ text: String) -> Message {
        Message(role: .system, content: .text(text))
    }

    public static func user(_ text: String) -> Message {
        Message(role: .user, content: .text(text))
    }

    public static func assistant(_ text: String) -> Message {
        Message(role: .assistant, content: .text(text))
    }

    public static func toolResult(toolCallID: String, content: String, isError: Bool = false) -> Message {
        Message(role: .tool, content: .toolResult(toolCallID: toolCallID, content: content, isError: isError))
    }
}
