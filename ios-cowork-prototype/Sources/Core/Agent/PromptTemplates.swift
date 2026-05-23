import Foundation

public enum PromptTemplates {
    public static func systemPrompt(tools: [ToolDefinition]) -> String {
        let toolList = tools.map { "- \($0.name): \($0.description)" }.joined(separator: "\n")
        return """
        You are CarpCowork, an expert iOS development assistant with access to the following tools:
        \(toolList)

        You work iteratively to complete tasks. When given a task:
        1. Think through the steps needed.
        2. Use tools when you need to read/write files, search the web, or interact with the system.
        3. Review tool results and adjust your approach.
        4. Provide a clear, concise final answer.

        Always be careful with file operations — only modify files the user has asked you to work with.
        """
    }

    public static func planPrompt(task: String) -> String {
        """
        Break down the following task into concrete, sequential subtasks.
        Respond ONLY with a JSON object in this exact format:
        {"subtasks": ["step 1", "step 2", ...], "reasoning": "why these steps"}

        Task: \(task)
        """
    }

    public static func reflectPrompt(task: String, stepsCompleted: Int) -> String {
        """
        Original task: \(task)
        Steps completed so far: \(stepsCompleted)

        Review the conversation above. Has the original task been fully completed?
        Respond ONLY with a JSON object:
        - If complete: {"done": true, "summary": "what was accomplished"}
        - If incomplete: {"done": false, "next_action": "specific next step to take"}
        """
    }

    // Used when the provider doesn't support native tool calls (on-device models)
    public static func reactSystemPrompt(tools: [ToolDefinition]) -> String {
        let toolDescriptions = tools.map { tool -> String in
            let params = tool.parameters.properties.map { "\($0.key) (\($0.value.type)): \($0.value.description)" }.joined(separator: ", ")
            return "  \(tool.name)(\(params)) — \(tool.description)"
        }.joined(separator: "\n")

        return """
        You are CarpCowork, an expert iOS development assistant.

        To use a tool, output it on its own line in this exact format:
        <tool>tool_name({"param": "value"})</tool>

        Available tools:
        \(toolDescriptions)

        After each tool result (shown as <tool_result>...</tool_result>), continue reasoning.
        When the task is complete, provide your final answer without any <tool> tags.
        """
    }
}
