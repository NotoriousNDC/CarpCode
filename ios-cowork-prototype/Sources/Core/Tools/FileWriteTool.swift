import Foundation

public struct FileWriteTool: AgentTool {
    public let name = "file_write"
    public let description = "Write or overwrite a file within the app sandbox."
    private let sandbox: SandboxPolicy

    public init(sandbox: SandboxPolicy = .default) {
        self.sandbox = sandbox
    }

    public var parameterSchema: JSONSchemaObject {
        JSONSchemaObject(
            properties: [
                "path": JSONSchemaProperty(type: "string", description: "Absolute path to write within the sandbox."),
                "content": JSONSchemaProperty(type: "string", description: "Text content to write."),
            ],
            required: ["path", "content"]
        )
    }

    public func execute(input: String) async throws -> ToolResult {
        let args = try parseInput(input)
        guard let pathStr = args["path"] as? String,
              let content = args["content"] as? String else {
            return .error("Missing required parameters: path, content")
        }
        let url = URL(fileURLWithPath: pathStr)
        try sandbox.validate(path: url)

        // Create parent directories if needed
        let dir = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return ToolResult(content: "Wrote \(content.utf8.count) bytes to \(pathStr)", metadata: ["path": pathStr])
    }
}
