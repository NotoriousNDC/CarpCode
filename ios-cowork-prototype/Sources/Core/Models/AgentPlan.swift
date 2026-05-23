import Foundation

public struct AgentPlan: Codable, Sendable {
    public let subtasks: [String]
    public let reasoning: String

    public init(subtasks: [String], reasoning: String) {
        self.subtasks = subtasks
        self.reasoning = reasoning
    }

    public static let fallback = AgentPlan(
        subtasks: ["Complete the requested task directly"],
        reasoning: "Could not parse a structured plan; falling back to direct completion."
    )
}

public enum ReflectDecision: Sendable {
    case `continue`(nextAction: String)
    case done(summary: String)
}

// Codable shape the Reflector expects from the model
struct ReflectResponse: Codable {
    let done: Bool
    let summary: String?
    let nextAction: String?
}
