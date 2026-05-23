import Foundation

// Runs a Shortcuts shortcut via the x-shortcuts-run URL scheme.
// Full x-callback-url response requires AppDelegate wiring (future iteration).
public struct ShortcutsTool: AgentTool {
    public let name = "run_shortcut"
    public let description = "Run an Apple Shortcuts shortcut by name. Returns immediately (fire-and-forget in prototype)."

    public init() {}

    public var parameterSchema: JSONSchemaObject {
        JSONSchemaObject(
            properties: [
                "shortcut_name": JSONSchemaProperty(type: "string", description: "Exact name of the Shortcuts shortcut to run."),
                "input": JSONSchemaProperty(type: "string", description: "Optional text input to pass to the shortcut."),
            ],
            required: ["shortcut_name"]
        )
    }

    public func execute(input: String) async throws -> ToolResult {
        let args = try parseInput(input)
        guard let shortcutName = args["shortcut_name"] as? String else {
            return .error("Missing required parameter: shortcut_name")
        }

        var components = URLComponents(string: "shortcuts://run-shortcut")!
        components.queryItems = [URLQueryItem(name: "name", value: shortcutName)]
        if let inputText = args["input"] as? String {
            components.queryItems?.append(URLQueryItem(name: "input", value: inputText))
        }

        // TODO: Switch to x-callback-url + register callback handler for response
        guard let url = components.url else {
            return .error("Could not build Shortcuts URL")
        }
        return ToolResult(
            content: "Shortcut '\(shortcutName)' queued. URL: \(url.absoluteString). Note: response capture requires x-callback-url wiring (not yet implemented in prototype).",
            metadata: ["shortcut": shortcutName, "url": url.absoluteString]
        )
    }
}
