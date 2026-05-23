import Foundation

public struct ToolCall: Identifiable, Sendable {
    public let id: String           // tool_call_id from the model
    public let name: String
    public let input: String        // raw JSON string
    public var result: ToolResult?

    public init(id: String, name: String, input: String) {
        self.id = id
        self.name = name
        self.input = input
    }
}

public struct ToolResult: Sendable {
    public let content: String
    public let isError: Bool
    public let metadata: [String: String]

    public init(content: String, isError: Bool = false, metadata: [String: String] = [:]) {
        self.content = content
        self.isError = isError
        self.metadata = metadata
    }

    public static func error(_ message: String) -> ToolResult {
        ToolResult(content: message, isError: true)
    }
}

// Schema object passed to model providers describing a tool
public struct ToolDefinition: Codable, Sendable {
    public let name: String
    public let description: String
    public let parameters: JSONSchemaObject

    public init(name: String, description: String, parameters: JSONSchemaObject) {
        self.name = name
        self.description = description
        self.parameters = parameters
    }
}

// Minimal JSON Schema representation sufficient for tool definitions
public struct JSONSchemaObject: Codable, Sendable {
    public let type: String                           // always "object" for tool input
    public let properties: [String: JSONSchemaProperty]
    public let required: [String]

    public init(properties: [String: JSONSchemaProperty], required: [String] = []) {
        self.type = "object"
        self.properties = properties
        self.required = required
    }
}

public struct JSONSchemaProperty: Codable, Sendable {
    public let type: String
    public let description: String
    public let enumValues: [String]?

    public init(type: String, description: String, enumValues: [String]? = nil) {
        self.type = type
        self.description = description
        self.enumValues = enumValues
    }

    enum CodingKeys: String, CodingKey {
        case type, description
        case enumValues = "enum"
    }
}
