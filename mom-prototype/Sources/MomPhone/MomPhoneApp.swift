#if canImport(SwiftUI) && os(iOS)
import SwiftUI
import Core
import CoreUI
import MomCore

@main
public struct MomPhoneApp: App {
    @State private var privacy = PrivacyConfig(mode: .balanced)

    public init() {}

    public var body: some Scene {
        WindowGroup {
            NavigationStack {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Mom")
                        .font(.largeTitle.bold())
                    Text("Habits + tasks that bend to your day.")
                        .foregroundStyle(.secondary)
                    Spacer()
                    PrivacyBadge(mode: privacy.mode)
                }
                .padding()
            }
        }
    }
}
#endif
