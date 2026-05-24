#if canImport(SwiftUI) && os(iOS)
import SwiftUI
import Core
import CoreUI

// Annotate with @main in your Xcode iOS app target.
public struct AskBandPhoneApp: App {
    @State private var privacy = PrivacyConfig(mode: .balanced)

    public init() {}

    public var body: some Scene {
        WindowGroup {
            NavigationStack {
                VStack(spacing: 12) {
                    Text("AskBand")
                        .font(.largeTitle.bold())
                    Text("Push-to-talk LLM Q&A from your wrist.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                    PrivacyBadge(mode: privacy.mode)
                }
                .padding()
            }
        }
    }
}
#endif
