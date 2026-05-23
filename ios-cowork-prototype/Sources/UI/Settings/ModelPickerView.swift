import SwiftUI
import Core

public struct ModelPickerView: View {
    @Environment(AppSettings.self) private var settings

    public init() {}

    public var body: some View {
        @Bindable var settings = settings
        Form {
            if settings.executionMode == .privacyOnDevice {
                onDeviceSection(settings: settings)
            } else {
                apiProviderSections(settings: settings)
            }
        }
        .navigationTitle("Select Model")
    }

    @ViewBuilder
    private func onDeviceSection(settings: AppSettings) -> some View {
        #if canImport(CoreML)
        let available = ModelBundleLoader.availableModels()
        if available.isEmpty {
            Section {
                ContentUnavailableView(
                    "No On-Device Models",
                    systemImage: "cpu.fill",
                    description: Text("Drop a .mlpackage into CoreMLModels/ — see the README.")
                )
            }
        } else {
            Section("Available Models") {
                ForEach(available) { descriptor in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(descriptor.displayName)
                            Text(formatBytes(descriptor.sizeBytes))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if settings.selectedOnDeviceModelID == descriptor.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        settings.selectedOnDeviceModelID = descriptor.id
                        settings.save()
                    }
                }
            }
        }
        #else
        Section {
            Text("Core ML not available on this platform.")
                .foregroundStyle(.secondary)
        }
        #endif
    }

    @ViewBuilder
    private func apiProviderSections(settings: AppSettings) -> some View {
        ForEach(ProviderDescriptor.all) { provider in
            Section(provider.displayName) {
                ForEach(provider.models) { model in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(model.displayName)
                            Text("\(formatContext(model.contextWindow)) context")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if !model.supportsTools {
                            Text("No tools")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.1), in: Capsule())
                        }
                        if settings.selectedProviderID == model.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        settings.selectedProviderID = model.id
                        settings.save()
                    }
                }
            }
        }
    }

    private func formatBytes(_ bytes: Int) -> String {
        let gb = Double(bytes) / 1_000_000_000
        if gb >= 1 { return String(format: "%.1f GB", gb) }
        let mb = Double(bytes) / 1_000_000
        return String(format: "%.0f MB", mb)
    }

    private func formatContext(_ tokens: Int) -> String {
        let k = tokens / 1000
        return k >= 1000 ? "\(k / 1000)M" : "\(k)K"
    }
}
