import Foundation

/// Streaming Claude (Anthropic Messages API) client.
/// Default model is `claude-sonnet-4-6` — small enough to be fast on watch
/// round-trips, capable enough for habit-scheduling reasoning.
public final class AnthropicProvider: ModelProvider, @unchecked Sendable {
    public let id: String
    public let displayName: String
    public let supportsTools = true

    private let model: String
    private let apiKey: String
    private let baseURL: URL
    private let http: HTTPClient

    public init(
        model: String = "claude-sonnet-4-6",
        apiKey: String,
        baseURL: URL = URL(string: "https://api.anthropic.com/v1")!,
        http: HTTPClient = HTTPClient()
    ) {
        self.model = model
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.http = http
        self.id = "anthropic/\(model)"
        self.displayName = "Claude (\(model))"
    }

    public func complete(
        messages: [Message],
        tools: [ToolDefinition],
        config: InferenceConfig
    ) async throws -> AsyncThrowingStream<CompletionChunk, Error> {
        var request = URLRequest(url: baseURL.appendingPathComponent("messages"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        var body: [String: Any] = [
            "model": model,
            "max_tokens": config.maxTokens,
            "temperature": config.temperature,
            "stream": true,
            "messages": messages.filter { $0.role != .system }.map(anthropicMessage),
        ]
        if let system = config.systemPrompt {
            body["system"] = system
        } else if let sys = messages.first(where: { $0.role == .system }) {
            body["system"] = sys.content.plainText
        }
        if !tools.isEmpty {
            body["tools"] = tools.map(anthropicTool)
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    var currentToolIndex = -1
                    for try await event in self.http.streamSSE(request: request, cloudPurpose: .llm) {
                        guard let chunk = self.parseEvent(event, currentToolIndex: &currentToolIndex) else { continue }
                        continuation.yield(chunk)
                        if case .finishReason = chunk { break }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func anthropicMessage(_ msg: Message) -> [String: Any] {
        switch msg.content {
        case .text(let text):
            return ["role": msg.role.rawValue, "content": text]
        case .toolResult(let id, let content, let isError):
            return [
                "role": "user",
                "content": [["type": "tool_result", "tool_use_id": id, "content": content, "is_error": isError]],
            ]
        case .toolUse(let id, let name, let input):
            let inputObj = (try? JSONSerialization.jsonObject(with: Data(input.utf8))) ?? [:]
            return [
                "role": "assistant",
                "content": [["type": "tool_use", "id": id, "name": name, "input": inputObj]],
            ]
        case .multipart(let parts):
            let content = parts.map { part -> [String: Any] in
                if case .text(let t) = part { return ["type": "text", "text": t] }
                if case .image(let b64, let mime) = part {
                    return ["type": "image", "source": ["type": "base64", "media_type": mime, "data": b64]]
                }
                return [:]
            }
            return ["role": msg.role.rawValue, "content": content]
        }
    }

    private func anthropicTool(_ def: ToolDefinition) -> [String: Any] {
        [
            "name": def.name,
            "description": def.description,
            "input_schema": [
                "type": "object",
                "properties": def.parameters.properties.mapValues { p -> [String: Any] in
                    var dict: [String: Any] = ["type": p.type, "description": p.description]
                    if let e = p.enumValues { dict["enum"] = e }
                    return dict
                },
                "required": def.parameters.required,
            ] as [String: Any],
        ]
    }

    private func parseEvent(_ event: SSEEvent, currentToolIndex: inout Int) -> CompletionChunk? {
        guard event.isDataLine,
              let data = event.data.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return nil }

        switch type {
        case "content_block_start":
            if let block = json["content_block"] as? [String: Any],
               (block["type"] as? String) == "tool_use",
               let id = block["id"] as? String,
               let name = block["name"] as? String,
               let index = json["index"] as? Int {
                currentToolIndex = index
                return .toolCallDelta(index: index, id: id, name: name, argumentsDelta: "")
            }
            return nil
        case "content_block_delta":
            if let delta = json["delta"] as? [String: Any],
               let dtype = delta["type"] as? String {
                if dtype == "text_delta", let text = delta["text"] as? String {
                    return .textDelta(text)
                }
                if dtype == "input_json_delta", let partial = delta["partial_json"] as? String {
                    return .toolCallDelta(index: currentToolIndex, id: nil, name: nil, argumentsDelta: partial)
                }
            }
            return nil
        case "message_delta":
            if let delta = json["delta"] as? [String: Any],
               let stop = delta["stop_reason"] as? String {
                return .finishReason(stop == "tool_use" ? .toolUse : .stop)
            }
            return nil
        case "message_stop":
            return .finishReason(.stop)
        default:
            return nil
        }
    }
}
