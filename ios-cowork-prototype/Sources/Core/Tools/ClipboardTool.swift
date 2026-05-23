#if canImport(UIKit)
import UIKit

// UIPasteboard must be accessed on @MainActor
@MainActor
public struct ClipboardTool: AgentTool {
    public let name = "clipboard"
    public let description = "Read from or write to the iOS clipboard."

    public init() {}

    public var parameterSchema: JSONSchemaObject {
        JSONSchemaObject(
            properties: [
                "action": JSONSchemaProperty(type: "string", description: "'read' or 'write'", enumValues: ["read", "write"]),
                "text": JSONSchemaProperty(type: "string", description: "Text to write (required for 'write' action)."),
            ],
            required: ["action"]
        )
    }

    public func execute(input: String) async throws -> ToolResult {
        let args = try parseInput(input)
        let action = args["action"] as? String ?? "read"

        switch action {
        case "read":
            let text = UIPasteboard.general.string ?? ""
            return ToolResult(content: text.isEmpty ? "(clipboard is empty)" : text)
        case "write":
            guard let text = args["text"] as? String else {
                return .error("Missing required parameter: text")
            }
            UIPasteboard.general.string = text
            return ToolResult(content: "Wrote \(text.count) characters to clipboard.")
        default:
            return .error("Unknown action: '\(action)'. Use 'read' or 'write'.")
        }
    }
}
#endif
