import Foundation

/// Schema passed to model providers describing a tool the model may call.
/// (Used by AskBand, Mom, WristShell, where the LLM can request structured action.)
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

public struct JSONSchemaObject: Codable, Sendable {
    public let type: String
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
