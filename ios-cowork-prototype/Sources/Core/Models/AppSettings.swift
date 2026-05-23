import Foundation

public enum ExecutionMode: String, Codable, CaseIterable, Sendable {
    case privacyOnDevice = "privacy"
    case api = "api"

    public var displayName: String {
        switch self {
        case .privacyOnDevice: return "Privacy (On-Device)"
        case .api: return "API (BYO Keys)"
        }
    }
}

public struct AgentConfig: Codable, Sendable {
    public var maxSteps: Int = 20
    public var enableWebSearch: Bool = true
    public var enableFileAccess: Bool = true
    public var enableShortcuts: Bool = false
    public var inferenceTemperature: Float = 0.7
    public var maxTokensPerStep: Int = 2048

    public init() {}
}

public struct AppSettings: Codable, Sendable {
    public var executionMode: ExecutionMode = .api
    public var selectedProviderID: String = "anthropic/claude-sonnet-4-5"
    public var selectedOnDeviceModelID: String = "nanoGPT-codeAssist-v1"
    public var agentConfig: AgentConfig = AgentConfig()

    public init() {}

    // Persists to UserDefaults
    public static let defaultsKey = "carpcowork.settings"

    public static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let settings = try? JSONCoder.decoder.decode(AppSettings.self, from: data)
        else { return AppSettings() }
        return settings
    }

    public func save() {
        guard let data = try? JSONCoder.encoder.encode(self) else { return }
        UserDefaults.standard.set(data, forKey: AppSettings.defaultsKey)
    }
}

// Known API provider descriptors
public struct ProviderDescriptor: Sendable, Identifiable {
    public let id: String        // e.g. "anthropic"
    public let displayName: String
    public let models: [ModelDescriptor]
    public let requiresAPIKey: Bool

    public struct ModelDescriptor: Sendable, Identifiable {
        public let id: String    // e.g. "anthropic/claude-sonnet-4-5"
        public let displayName: String
        public let contextWindow: Int
        public let supportsTools: Bool
    }
}

public extension ProviderDescriptor {
    static let all: [ProviderDescriptor] = [
        ProviderDescriptor(id: "anthropic", displayName: "Anthropic", requiresAPIKey: true, models: [
            .init(id: "anthropic/claude-opus-4-7",     displayName: "Claude Opus 4.7",    contextWindow: 200_000, supportsTools: true),
            .init(id: "anthropic/claude-sonnet-4-6",   displayName: "Claude Sonnet 4.6",  contextWindow: 200_000, supportsTools: true),
            .init(id: "anthropic/claude-haiku-4-5",    displayName: "Claude Haiku 4.5",   contextWindow: 200_000, supportsTools: true),
        ]),
        ProviderDescriptor(id: "openai", displayName: "OpenAI", requiresAPIKey: true, models: [
            .init(id: "openai/gpt-4o",      displayName: "GPT-4o",   contextWindow: 128_000, supportsTools: true),
            .init(id: "openai/gpt-4o-mini",  displayName: "GPT-4o mini", contextWindow: 128_000, supportsTools: true),
            .init(id: "openai/o1",          displayName: "o1",       contextWindow: 200_000, supportsTools: false),
        ]),
        ProviderDescriptor(id: "gemini", displayName: "Google Gemini", requiresAPIKey: true, models: [
            .init(id: "gemini/gemini-2.0-flash",     displayName: "Gemini 2.0 Flash",    contextWindow: 1_000_000, supportsTools: true),
            .init(id: "gemini/gemini-2.5-pro",       displayName: "Gemini 2.5 Pro",      contextWindow: 2_000_000, supportsTools: true),
        ]),
        ProviderDescriptor(id: "mistral", displayName: "Mistral", requiresAPIKey: true, models: [
            .init(id: "mistral/mistral-large-latest",  displayName: "Mistral Large",   contextWindow: 131_000, supportsTools: true),
            .init(id: "mistral/codestral-latest",      displayName: "Codestral",       contextWindow: 256_000, supportsTools: true),
        ]),
        ProviderDescriptor(id: "ollama", displayName: "Ollama (localhost)", requiresAPIKey: false, models: [
            .init(id: "ollama/llama3.2",    displayName: "Llama 3.2",   contextWindow: 128_000, supportsTools: true),
            .init(id: "ollama/codellama",   displayName: "CodeLlama",   contextWindow: 100_000, supportsTools: false),
            .init(id: "ollama/qwen2.5-coder", displayName: "Qwen 2.5 Coder", contextWindow: 128_000, supportsTools: true),
        ]),
    ]
}
