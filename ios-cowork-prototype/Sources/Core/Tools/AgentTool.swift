import Foundation

public protocol AgentTool: Sendable {
    var name: String { get }
    var description: String { get }
    var parameterSchema: JSONSchemaObject { get }

    // input is a raw JSON string matching parameterSchema
    func execute(input: String) async throws -> ToolResult
}

public extension AgentTool {
    var definition: ToolDefinition {
        ToolDefinition(name: name, description: description, parameters: parameterSchema)
    }

    // Helper: parse JSON input string into [String: Any]
    func parseInput(_ input: String) throws -> [String: Any] {
        try JSONCoder.object(from: input)
    }
}
