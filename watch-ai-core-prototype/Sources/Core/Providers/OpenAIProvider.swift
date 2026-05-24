import Foundation

/// Streaming OpenAI chat-completions client.
public final class OpenAIProvider: ModelProvider, @unchecked Sendable {
    public let id: String
    public let displayName: String
    public let supportsTools = true

    private let model: String
    private let apiKey: String
    private let baseURL: URL
    private let http: HTTPClient

    public init(
        model: String = "gpt-4o-mini",
        apiKey: String,
        baseURL: URL = URL(string: "https://api.openai.com/v1")!,
        http: HTTPClient = HTTPClient()
    ) {
        self.model = model
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.http = http
        self.id = "openai/\(model)"
        self.displayName = "GPT (\(model))"
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
                    for try await event in self.http.streamSSE(request: request, cloudPurpose: .llm) {
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

    private func openAIMessage(_ msg: Message) -> [String: Any] {
        switch msg.content {
        case .text(let t):
            return ["role": msg.role.rawValue, "content": t]
        case .toolResult(let id, let content, _):
            return ["role": "tool", "tool_call_id": id, "content": content]
        case .toolUse(let id, let name, let input):
            return ["role": "assistant", "tool_calls": [
                ["id": id, "type": "function", "function": ["name": name, "arguments": input]]
            ]]
        case .multipart(let parts):
            let content = parts.map { p -> [String: Any] in
                if case .text(let t) = p { return ["type": "text", "text": t] }
                if case .image(let b64, let mime) = p {
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
                "properties": def.parameters.properties.mapValues { p -> [String: Any] in
                    var dict: [String: Any] = ["type": p.type, "description": p.description]
                    if let e = p.enumValues { dict["enum"] = e }
                    return dict
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

        if let finishReason = choice["finish_reason"] as? String,
           !finishReason.isEmpty, finishReason != "null" {
            return .finishReason(finishReason == "tool_calls" ? .toolUse : .stop)
        }
        guard let delta = choice["delta"] as? [String: Any] else { return nil }
        if let content = delta["content"] as? String { return .textDelta(content) }
        if let toolCalls = delta["tool_calls"] as? [[String: Any]], let first = toolCalls.first {
            let index = first["index"] as? Int ?? 0
            let id = first["id"] as? String
            let fn = first["function"] as? [String: Any]
            let name = fn?["name"] as? String
            let argsDelta = fn?["arguments"] as? String ?? ""
            return .toolCallDelta(index: index, id: id, name: name, argumentsDelta: argsDelta)
        }
        return nil
    }
}
