import Foundation

public actor AgentLoop {
    public static let maxIterations = 20

    private let provider: any ModelProvider
    private let tools: ToolRegistry
    private let settings: AppSettings
    private var conversationHistory: [Message] = []
    private var isCancelled = false

    public init(provider: any ModelProvider, tools: ToolRegistry, settings: AppSettings = AppSettings()) {
        self.provider = provider
        self.tools = tools
        self.settings = settings
    }

    public func cancel() {
        isCancelled = true
    }

    // Main entry point. Yields AgentStep updates as the loop progresses.
    public func run(task: String) -> AsyncThrowingStream<AgentStep, Error> {
        isCancelled = false
        conversationHistory = [
            Message.system(PromptTemplates.systemPrompt(tools: tools.definitions)),
            Message.user(task),
        ]

        return makeAsyncStream { [self] continuation in
            // Phase 1: Plan
            var planStep = AgentStep(phase: .planning, content: "Breaking down the task…")
            continuation.yield(planStep)

            let plan: AgentPlan
            do {
                plan = try await self.planTask(task: task)
            } catch {
                planStep.fail(error.localizedDescription)
                continuation.yield(planStep)
                throw error
            }
            planStep.complete(detail: "Subtasks:\n" + plan.subtasks.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"))
            continuation.yield(planStep)

            // Phase 2-4: Act → Observe → Reflect (loop per subtask)
            var iteration = 0
            for subtask in plan.subtasks {
                if self.isCancelled { break }
                if iteration >= Self.maxIterations { break }
                iteration += 1

                // Act
                let toolCalls: [ToolCall]
                do {
                    let (calls, actStep) = try await self.act(subtask: subtask, continuation: continuation)
                    toolCalls = calls
                    _ = actStep
                } catch {
                    break
                }

                // Observe
                await self.observe(toolCalls: toolCalls, continuation: continuation)
            }

            // Phase 5: Final reflection and response
            var respondStep = AgentStep(phase: .responding, content: "Generating final response…")
            continuation.yield(respondStep)

            do {
                let finalResponse = try await self.generateFinalResponse(task: task)
                self.conversationHistory.append(Message.assistant(finalResponse))
                respondStep.complete(detail: finalResponse)
                continuation.yield(respondStep)
            } catch {
                respondStep.fail(error.localizedDescription)
                continuation.yield(respondStep)
                throw error
            }
        }
    }

    // MARK: - Private phases

    private func planTask(task: String) async throws -> AgentPlan {
        let planner = Planner(provider: provider)
        return try await planner.decompose(task: task)
    }

    private func act(
        subtask: String,
        continuation: AsyncThrowingStream<AgentStep, Error>.Continuation
    ) async throws -> ([ToolCall], AgentStep) {
        var step = AgentStep(phase: .acting(toolName: "model"), content: subtask)
        continuation.yield(step)

        conversationHistory.append(Message.user(subtask))

        let config = InferenceConfig(
            temperature: settings.agentConfig.inferenceTemperature,
            maxTokens: settings.agentConfig.maxTokensPerStep
        )

        let toolDefs = provider.supportsTools ? tools.definitions : []
        let stream = try await provider.complete(messages: conversationHistory, tools: toolDefs, config: config)

        // Accumulate the streamed response
        var fullText = ""
        var pendingToolCalls: [Int: (id: String, name: String, args: String)] = [:]

        for try await chunk in stream {
            switch chunk {
            case .textDelta(let delta):
                fullText += delta
            case .toolCallDelta(let index, let id, let name, let argDelta):
                var existing = pendingToolCalls[index] ?? (id: id ?? "", name: name ?? "", args: "")
                if let id = id { existing.id = id }
                if let name = name { existing.name = name }
                existing.args += argDelta
                pendingToolCalls[index] = existing
            case .finishReason:
                break
            }
        }

        conversationHistory.append(Message.assistant(fullText))

        // Build tool call list
        var toolCalls: [ToolCall] = []
        if provider.supportsTools {
            toolCalls = pendingToolCalls.sorted { $0.key < $1.key }.map {
                ToolCall(id: $0.value.id, name: $0.value.name, input: $0.value.args)
            }
        } else {
            // ReAct text shim: parse <tool>name({...})</tool> from fullText
            toolCalls = parseReActToolCalls(from: fullText)
        }

        step.complete(detail: fullText)
        continuation.yield(step)
        return (toolCalls, step)
    }

    private func observe(
        toolCalls: [ToolCall],
        continuation: AsyncThrowingStream<AgentStep, Error>.Continuation
    ) async {
        for call in toolCalls {
            var step = AgentStep(phase: .acting(toolName: call.name), content: "Running \(call.name)…")
            continuation.yield(step)

            let result = await tools.dispatch(call: call)
            let resultMessage = Message.toolResult(toolCallID: call.id, content: result.content, isError: result.isError)
            conversationHistory.append(resultMessage)

            step.complete(detail: "Input: \(call.input)\n\nOutput: \(result.content)")
            continuation.yield(step)
        }
    }

    private func generateFinalResponse(task: String) async throws -> String {
        let config = InferenceConfig(temperature: 0.5, maxTokens: 1024)
        let stream = try await provider.complete(messages: conversationHistory, tools: [], config: config)
        var response = ""
        for try await chunk in stream {
            if case .textDelta(let delta) = chunk { response += delta }
        }
        return response
    }

    // MARK: - ReAct text parser (for on-device models)

    private func parseReActToolCalls(from text: String) -> [ToolCall] {
        var calls: [ToolCall] = []
        // Matches <tool>name({"key":"val"})</tool>
        let pattern = #"<tool>(\w+)\((\{.*?\})\)<\/tool>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return []
        }
        let range = NSRange(text.startIndex..., in: text)
        for match in regex.matches(in: text, range: range) {
            guard let nameRange = Range(match.range(at: 1), in: text),
                  let inputRange = Range(match.range(at: 2), in: text) else { continue }
            let name = String(text[nameRange])
            let input = String(text[inputRange])
            calls.append(ToolCall(id: UUID().uuidString, name: name, input: input))
        }
        return calls
    }
}
