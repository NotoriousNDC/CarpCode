import SwiftUI
import Core

public struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    public init() {}

    public var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            Form {
                Section("Execution Mode") {
                    ModeToggleView()
                }

                if settings.executionMode == .api {
                    Section("API Keys") {
                        ForEach(ProviderDescriptor.all.filter(\.requiresAPIKey)) { provider in
                            NavigationLink {
                                APIKeyEntryView(providerID: provider.id, providerName: provider.displayName)
                            } label: {
                                HStack {
                                    Text(provider.displayName)
                                    Spacer()
                                    KeychainStatusIndicator(service: provider.id)
                                }
                            }
                        }
                    }

                    Section("Model") {
                        NavigationLink("Select Model") {
                            ModelPickerView()
                        }
                    }
                }

                if settings.executionMode == .privacyOnDevice {
                    Section("On-Device Model") {
                        NavigationLink("Select Model") {
                            ModelPickerView()
                        }
                    }
                }

                Section("Agent") {
                    Stepper("Max steps: \(settings.agentConfig.maxSteps)",
                            value: $settings.agentConfig.maxSteps,
                            in: 1...50)
                    Toggle("Web search", isOn: $settings.agentConfig.enableWebSearch)
                    Toggle("File access", isOn: $settings.agentConfig.enableFileAccess)
                    Toggle("Shortcuts integration", isOn: $settings.agentConfig.enableShortcuts)
                }

                Section("About") {
                    LabeledContent("Version", value: "0.1.0-prototype")
                    LabeledContent("Model layer", value: "Karpathy nanoGPT / Core ML")
                }
            }
            .navigationTitle("Settings")
            .onChange(of: settings.executionMode) { _, _ in settings.save() }
            .onChange(of: settings.selectedProviderID) { _, _ in settings.save() }
            .onChange(of: settings.agentConfig.maxSteps) { _, _ in settings.save() }
        }
    }
}

private struct KeychainStatusIndicator: View {
    let service: String
    private var hasKey: Bool { KeychainStore().hasKey(service: service) }

    var body: some View {
        Image(systemName: hasKey ? "checkmark.circle.fill" : "xmark.circle")
            .foregroundStyle(hasKey ? .green : .red)
            .font(.caption)
    }
}
