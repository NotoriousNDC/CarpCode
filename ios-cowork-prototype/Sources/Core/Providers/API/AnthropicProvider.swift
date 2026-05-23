import Foundation

public final class AnthropicProvider: APIModelProvider, ModelProvider {
    public override var id: String { "anthropic/\(model)" }
    public override var displayName: String { "Claude (\(model))" }
    public override var supportsTools: Bool { true }

    public init(model: String, apiKey: String) {
        super.init(model: model, apiKey: apiKey, baseURL: URL(string: "https://api.anthropic.com/v1")!)
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
            "stream": true,
            "messages": messages.filter { $0.role != .system }.map(anthropicMessage),
        ]
        if let system = config.systemPrompt ?? messages.first(where: { $0.role == .system })?.content.plainText {
            body["system"] = system
        }
        if !tools.isEmpty {
            body["tools"] = tools.map(anthropicTool)
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

    // MARK: - Anthropic-specific serialization

    private func anthropicMessage(_ msg: Message) -> [String: Any] {
        switch msg.content {
        case .text(let text):
            return ["role": msg.role.rawValue, "content": text]
        case .toolResult(let toolCallID, let content, _):
            return ["role": "user", "content": [["type": "tool_result", "tool_use_id": toolCallID, "content": content]]]
        case .toolUse(let id, let name, let input):
            return ["role": "assistant", "content": [["type": "tool_use", "id": id, "name": name, "input": (try? JSONCoder.object(from: input)) ?? [:]]]]
        case .multipart(let parts):
            return ["role": msg.role.rawValue, "content": parts.map { part -> [String: Any] in
                if case .text(let t) = part { return ["type": "text", "text": t] }
                if case .image(let b64, let mime) = part { return ["type": "image", "source": ["type": "base64", "media_type": mime, "data": b64]] }
                return [:]
            }]
        }
    }

    private func anthropicTool(_ def: ToolDefinition) -> [String: Any] {
        ["name": def.name, "description": def.description, "input_schema": [
            "type": "object",
            "properties": def.parameters.properties.mapValues { prop -> [String: Any] in
                var p: [String: Any] = ["type": prop.type, "description": prop.description]
                if let e = prop.enumValues { p["enum"] = e }
                return p
            },
            "required": def.parameters.required,
        ] as [String: Any]]
    }

    private func parseEvent(_ event: SSEEvent) -> CompletionChunk? {
        guard event.isDataLine,
              let data = event.data.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

        let type = json["type"] as? String ?? ""

        switch type {
        case "content_block_delta":
            guard let delta = json["delta"] as? [String: Any] else { return nil }
            let deltaType = delta["type"] as? String ?? ""
            if deltaType == "text_delta", let text = delta["text"] as? String {
                return .textDelta(text)
            }
            if deltaType == "input_json_delta", let partial = delta["partial_json"] as? String {
                let index = json["index"] as? Int ?? 0
                return .toolCallDelta(index: index, id: nil, name: nil, argumentsDelta: partial)
            }
        case "content_block_start":
            guard let block = json["content_block"] as? [String: Any] else { return nil }
            if block["type"] as? String == "tool_use" {
                let index = json["index"] as? Int ?? 0
                let id = block["id"] as? String
                let name = block["name"] as? String
                return .toolCallDelta(index: index, id: id, name: name, argumentsDelta: "")
            }
        case "message_delta":
            if let delta = json["delta"] as? [String: Any],
               let stopReason = delta["stop_reason"] as? String {
                return .finishReason(stopReason == "tool_use" ? .toolUse : .stop)
            }
        default: break
        }
        return nil
    }
}
