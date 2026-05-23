import Foundation

public struct FileReadTool: AgentTool {
    public let name = "file_read"
    public let description = "Read the contents of a file within the app sandbox."
    private let sandbox: SandboxPolicy
    private let maxBytes: Int

    public init(sandbox: SandboxPolicy = .default, maxBytes: Int = 8192) {
        self.sandbox = sandbox
        self.maxBytes = maxBytes
    }

    public var parameterSchema: JSONSchemaObject {
        JSONSchemaObject(
            properties: [
                "path": JSONSchemaProperty(type: "string", description: "Absolute path to the file within the sandbox."),
            ],
            required: ["path"]
        )
    }

    public func execute(input: String) async throws -> ToolResult {
        let args = try parseInput(input)
        guard let pathStr = args["path"] as? String else {
            return .error("Missing required parameter: path")
        }
        let url = URL(fileURLWithPath: pathStr)
        try sandbox.validate(path: url)

        guard FileManager.default.fileExists(atPath: url.path) else {
            return .error("File not found: \(pathStr)")
        }
        let data = try Data(contentsOf: url)
        let truncated = data.prefix(maxBytes)
        let text = String(data: truncated, encoding: .utf8) ?? String(data: truncated, encoding: .isoLatin1) ?? "<binary>"
        let suffix = data.count > maxBytes ? "\n\n[Truncated — \(data.count - maxBytes) bytes omitted]" : ""
        return ToolResult(content: text + suffix, metadata: ["path": pathStr, "size": "\(data.count)"])
    }
}
