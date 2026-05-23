import Foundation

public final class ProviderRegistry: Sendable {
    private let keychain: KeychainStore

    public init(keychain: KeychainStore = KeychainStore()) {
        self.keychain = keychain
    }

    public func provider(for settings: AppSettings) throws -> any ModelProvider {
        switch settings.executionMode {
        case .privacyOnDevice:
            return makeOnDeviceProvider(modelID: settings.selectedOnDeviceModelID)
        case .api:
            return try makeAPIProvider(id: settings.selectedProviderID)
        }
    }

    private func makeOnDeviceProvider(modelID: String) -> any ModelProvider {
        #if canImport(CoreML)
        let descriptors = ModelBundleLoader.availableModels()
        if let descriptor = descriptors.first(where: { $0.id == modelID }) {
            return OnDeviceModelProvider(descriptor: descriptor)
        }
        #endif
        return OnDeviceModelProvider()
    }

    private func makeAPIProvider(id: String) throws -> any ModelProvider {
        let components = id.split(separator: "/", maxSplits: 1)
        guard components.count == 2 else { throw ProviderError.unknownVendor(id) }
        let vendor = String(components[0])
        let model = String(components[1])

        switch vendor {
        case "openai":
            let key = try keychain.read(service: "openai")
            return OpenAIProvider(model: model, apiKey: key)
        case "anthropic":
            let key = try keychain.read(service: "anthropic")
            return AnthropicProvider(model: model, apiKey: key)
        case "gemini":
            let key = try keychain.read(service: "gemini")
            return GeminiProvider(model: model, apiKey: key)
        case "mistral":
            let key = try keychain.read(service: "mistral")
            return MistralProvider(model: model, apiKey: key)
        case "ollama":
            return OllamaProvider(model: model)
        default:
            throw ProviderError.unknownVendor(vendor)
        }
    }
}
