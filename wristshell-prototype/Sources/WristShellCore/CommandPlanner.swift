import Foundation
import Core

/// Takes a transcribed natural-language ops request and converts it to a
/// `PlannedCommand` via the LLM. The LLM is constrained to emit only template
/// calls present in the supplied registry.
public struct CommandPlanner: Sendable {
    public let model: ModelProvider
    public let registry: AllowlistRegistry

    public init(model: ModelProvider, registry: AllowlistRegistry = .default) {
        self.model = model
        self.registry = registry
    }

    public func plan(naturalRequest: String) async throws -> PlannedCommand {
        let templates = registry.templates.values.map { describe($0) }.joined(separator: "\n")
        let system = """
        You convert natural-language operations requests into one of the templates listed below.
        Output is JSON with EXACTLY this shape and nothing else:
        { "template": "<template_id>", "args": { "<argName>": "<value>", ... } }

        If the request does not match any template, return:
        { "template": "none", "args": {} }

        Available templates:
        \(templates)

        Rules:
        - Never invent a template name not in the list.
        - Never invent argument names not in the template's schema.
        - For enum args, only use a listed allowed value.
        - For int args, return a string representation of a base-10 integer.
        """

        let stream = try await model.complete(
            messages: [.user(naturalRequest)],
            tools: [],
            config: InferenceConfig(temperature: 0.0, maxTokens: 300, systemPrompt: system)
        )
        let raw = try await stream.joinedText()
        return try parse(raw)
    }

    func describe(_ template: CommandTemplate) -> String {
        let args = template.argSchema.map { spec -> String in
            switch spec.kind {
            case .enum:
                return "\(spec.name) (enum: \(spec.allowed?.joined(separator: ", ") ?? ""))"
            case .int:
                return "\(spec.name) (int)"
            case .string:
                return "\(spec.name) (string)"
            }
        }.joined(separator: ", ")
        return "- \(template.id): \(template.description). Args: [\(args)]"
    }

    func parse(_ raw: String) throws -> PlannedCommand {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8) else {
            throw ProviderError.invalidResponse("planner returned non-UTF8")
        }
        struct Envelope: Decodable {
            let template: String
            let args: [String: String]
        }
        let decoder = JSONDecoder()
        let env = try decoder.decode(Envelope.self, from: data)
        return PlannedCommand(template: env.template, args: env.args)
    }
}
