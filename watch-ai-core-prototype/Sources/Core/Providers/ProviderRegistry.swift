import Foundation

/// Resolves a `ModelProvider` from settings. Apps store the active provider
/// id (e.g. "anthropic/claude-sonnet-4-6") plus API keys in Keychain;
/// `ProviderRegistry` turns that into a live provider instance.
public struct ProviderRegistry: Sendable {
    public enum Vendor: String, Sendable, CaseIterable {
        case anthropic
        case openai
    }

    public let keychain: KeychainStore
    public let http: HTTPClient

    public init(keychain: KeychainStore = KeychainStore(), http: HTTPClient = HTTPClient()) {
        self.keychain = keychain
        self.http = http
    }

    public func make(vendor: Vendor, model: String) throws -> ModelProvider {
        let key = try keychain.read(account: "apikey.\(vendor.rawValue)")
        switch vendor {
        case .anthropic:
            return AnthropicProvider(model: model, apiKey: key, http: http)
        case .openai:
            return OpenAIProvider(model: model, apiKey: key, http: http)
        }
    }
}
