import Foundation

public final class GeminiProvider: APIModelProvider, ModelProvider {
    public override var id: String { "gemini/\(model)" }
    public override var displayName: String { "Gemini (\(model))" }
    public override var supportsTools: Bool { true }

    public init(model: String, apiKey: String) {
        super.init(
            model: model,
            apiKey: apiKey,
            baseURL: URL(string: "https://generativelanguage.googleapis.com/v1beta")!
        )
    }

    public func complete(
        messages: [Message],
        tools: [ToolDefinition],
        config: InferenceConfig
    ) async throws -> AsyncThrowingStream<CompletionChunk, Error> {
        // Gemini streams newline-delimited JSON, not SSE
        let endpoint = baseURL
            .appendingPathComponent("models/\(model):streamGenerateContent")
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        guard let url = components.url else {
            throw ProviderError.networkError("Could not build Gemini URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "contents": messages.filter { $0.role != .system }.map(geminiContent),
            "generationConfig": ["temperature": config.temperature, "maxOutputTokens": config.maxTokens],
        ]
        if let system = config.systemPrompt ?? messages.first(where: { $0.role == .system })?.content.plainText {
            body["systemInstruction"] = ["parts": [["text": system]]]
        }
        if !tools.isEmpty {
            body["tools"] = [["functionDeclarations": tools.map(geminiTool)]]
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    // Gemini returns a JSON array streamed as newline-delimited objects
                    let (bytes, _) = try await URLSession.shared.bytes(for: request)
                    var lineBuffer = ""
                    for try await byte in bytes {
                        let char = Character(UnicodeScalar(byte))
                        if char == "\n" {
                            if let chunk = self.parseGeminiLine(lineBuffer) {
                                continuation.yield(chunk)
                            }
                            lineBuffer = ""
                        } else {
                            lineBuffer.append(char)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Gemini-specific serialization

    private func geminiContent(_ msg: Message) -> [String: Any] {
        let role = msg.role == .user ? "user" : "model"
        return ["role": role, "parts": [["text": msg.content.plainText]]]
    }

    private func geminiTool(_ def: ToolDefinition) -> [String: Any] {
        ["name": def.name, "description": def.description, "parameters": [
            "type": "object",
            "properties": def.parameters.properties.mapValues { prop -> [String: Any] in
                var p: [String: Any] = ["type": prop.type.uppercased(), "description": prop.description]
                if let e = prop.enumValues { p["enum"] = e }
                return p
            },
            "required": def.parameters.required,
        ] as [String: Any]]
    }

    private func parseGeminiLine(_ line: String) -> CompletionChunk? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != "[", trimmed != "]", trimmed != "," else { return nil }
        let jsonLine = trimmed.hasPrefix(",") ? String(trimmed.dropFirst()) : trimmed
        guard let data = jsonLine.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let candidate = candidates.first,
              let content = candidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let part = parts.first else { return nil }

        if let text = part["text"] as? String {
            return .textDelta(text)
        }
        if let fnCall = part["functionCall"] as? [String: Any],
           let name = fnCall["name"] as? String {
            let argsString = (try? JSONCoder.string(from: fnCall["args"] ?? [:])) ?? "{}"
            return .toolCallDelta(index: 0, id: UUID().uuidString, name: name, argumentsDelta: argsString)
        }
        return nil
    }
}
