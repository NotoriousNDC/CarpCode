#if canImport(SwiftUI) && os(iOS)
import SwiftUI
import Core
import CoreUI

@main
public struct WristShellPhoneApp: App {
    // WristShell defaults to STRICT, not Balanced.
    @State private var privacy = PrivacyConfig(mode: .strict)

    public init() {}

    public var body: some Scene {
        WindowGroup {
            VStack(alignment: .leading, spacing: 12) {
                Text("WristShell")
                    .font(.largeTitle.bold())
                Text("Voice-controlled ops, Tailscale-private by default.")
                    .foregroundStyle(.secondary)
                Spacer()
                PrivacyBadge(mode: privacy.mode)
            }
            .padding()
        }
    }
}
#endif
