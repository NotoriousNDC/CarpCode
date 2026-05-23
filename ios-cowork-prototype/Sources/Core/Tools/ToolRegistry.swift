import Foundation

public final class ToolRegistry: Sendable {
    private let tools: [String: any AgentTool]

    public init(tools: [any AgentTool]) {
        self.tools = Dictionary(uniqueKeysWithValues: tools.map { ($0.name, $0) })
    }

    public static func defaultTools(sandbox: SandboxPolicy = .default) -> ToolRegistry {
        ToolRegistry(tools: [
            FileReadTool(sandbox: sandbox),
            FileWriteTool(sandbox: sandbox),
            WebSearchTool(),
            CodeExecutorTool(),
            ShortcutsTool(),
        ])
    }

    public var definitions: [ToolDefinition] {
        tools.values.map(\.definition).sorted { $0.name < $1.name }
    }

    public func dispatch(call: ToolCall) async -> ToolResult {
        guard let tool = tools[call.name] else {
            return ToolResult.error("Unknown tool: '\(call.name)'")
        }
        do {
            return try await tool.execute(input: call.input)
        } catch {
            return ToolResult.error("Tool '\(call.name)' failed: \(error.localizedDescription)")
        }
    }
}
