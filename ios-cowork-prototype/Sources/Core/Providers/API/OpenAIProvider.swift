import Foundation

public final class OpenAIProvider: APIModelProvider, ModelProvider {
    public override var id: String { "openai/\(model)" }
    public override var displayName: String { "GPT (\(model))" }
    public override var supportsTools: Bool { true }

    public init(model: String, apiKey: String, baseURL: URL? = nil) {
        super.init(
            model: model,
            apiKey: apiKey,
            baseURL: baseURL ?? URL(string: "https://api.openai.com/v1")!
        )
    }

    public func complete(
        messages: [Message],
        tools: [ToolDefinition],
        config: InferenceConfig
    ) async throws -> AsyncThrowingStream<CompletionChunk, Error> {
        var request = URLRequest(url: baseURL.appendingPathComponent("chat/completions"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        var body: [String: Any] = [
            "model": model,
            "max_tokens": config.maxTokens,
            "temperature": config.temperature,
            "stream": true,
            "messages": messages.map(openAIMessage),
        ]
        if !tools.isEmpty {
            body["tools"] = tools.map(openAITool)
            body["tool_choice"] = "auto"
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await event in self.streamSSE(request: request) {
                        if let chunk = self.parseEvent(event) {
                            continuation.yield(chunk)
                            if case .finishReason = chunk { break }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - OpenAI-specific serialization

    private func openAIMessage(_ msg: Message) -> [String: Any] {
        switch msg.content {
        case .text(let text):
            return ["role": msg.role.rawValue, "content": text]
        case .toolResult(let toolCallID, let content, _):
            return ["role": "tool", "tool_call_id": toolCallID, "content": content]
        case .toolUse(let id, let name, let input):
            return ["role": "assistant", "tool_calls": [
                ["id": id, "type": "function", "function": ["name": name, "arguments": input]]
            ]]
        case .multipart(let parts):
            let content = parts.map { part -> [String: Any] in
                if case .text(let t) = part { return ["type": "text", "text": t] }
                if case .image(let b64, let mime) = part {
                    return ["type": "image_url", "image_url": ["url": "data:\(mime);base64,\(b64)"]]
                }
                return [:]
            }
            return ["role": msg.role.rawValue, "content": content]
        }
    }

    private func openAITool(_ def: ToolDefinition) -> [String: Any] {
        ["type": "function", "function": [
            "name": def.name,
            "description": def.description,
            "parameters": [
                "type": "object",
                "properties": def.parameters.properties.mapValues { prop -> [String: Any] in
                    var p: [String: Any] = ["type": prop.type, "description": prop.description]
                    if let e = prop.enumValues { p["enum"] = e }
                    return p
                },
                "required": def.parameters.required,
            ] as [String: Any]
        ] as [String: Any]]
    }

    private func parseEvent(_ event: SSEEvent) -> CompletionChunk? {
        guard event.isDataLine,
              let data = event.data.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let choice = choices.first else { return nil }

        if let finishReason = choice["finish_reason"] as? String, !finishReason.isEmpty, finishReason != "null" {
            return .finishReason(finishReason == "tool_calls" ? .toolUse : .stop)
        }

        guard let delta = choice["delta"] as? [String: Any] else { return nil }

        if let content = delta["content"] as? String {
            return .textDelta(content)
        }

        if let toolCalls = delta["tool_calls"] as? [[String: Any]], let first = toolCalls.first {
            let index = first["index"] as? Int ?? 0
            let id = first["id"] as? String
            let function_ = first["function"] as? [String: Any]
            let name = function_?["name"] as? String
            let argsDelta = function_?["arguments"] as? String ?? ""
            return .toolCallDelta(index: index, id: id, name: name, argumentsDelta: argsDelta)
        }

        return nil
    }
}
