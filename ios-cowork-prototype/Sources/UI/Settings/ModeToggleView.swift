import SwiftUI
import Core

public struct ModeToggleView: View {
    @Environment(AppSettings.self) private var settings

    public init() {}

    public var body: some View {
        @Bindable var settings = settings
        Picker("Mode", selection: $settings.executionMode) {
            ForEach(ExecutionMode.allCases, id: \.self) { mode in
                Label {
                    Text(mode.displayName)
                } icon: {
                    Image(systemName: mode == .privacyOnDevice ? "lock.shield" : "network")
                }
                .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))

        if settings.executionMode == .privacyOnDevice {
            Label {
                Text("All inference runs on-device. No network requests are made.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(.green)
            }
        }
    }
}
