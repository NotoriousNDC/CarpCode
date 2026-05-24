import Foundation

/// One ops operation the user has explicitly allowed. Identified by name,
/// constrained by a tiny argument schema. Templates ship with the app.
///
/// Free-form shell is intentionally not modeled here — that's the point.
public struct CommandTemplate: Codable, Sendable, Identifiable {
    public let id: String                 // stable name, e.g. "restart_service"
    public let description: String
    public let argSchema: [ArgSpec]
    public let bashTemplate: String       // server-side; the watch never reads this
    public let requiresBiometric: Bool

    public init(id: String, description: String, argSchema: [ArgSpec], bashTemplate: String, requiresBiometric: Bool = true) {
        self.id = id
        self.description = description
        self.argSchema = argSchema
        self.bashTemplate = bashTemplate
        self.requiresBiometric = requiresBiometric
    }
}

public struct ArgSpec: Codable, Sendable {
    public let name: String
    public let kind: Kind
    /// For `.enum` kind, the allowed values. For others, nil.
    public let allowed: [String]?

    public enum Kind: String, Codable, Sendable {
        case string
        case int
        case `enum`
    }

    public init(name: String, kind: Kind, allowed: [String]? = nil) {
        self.name = name
        self.kind = kind
        self.allowed = allowed
    }
}

/// What the LLM emits — checked against the registry before execution.
public struct PlannedCommand: Codable, Sendable {
    public let template: String
    public let args: [String: String]
    public init(template: String, args: [String: String]) {
        self.template = template
        self.args = args
    }
}
