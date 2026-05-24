#if canImport(SwiftUI) && os(iOS)
import SwiftUI
import Core
import CoreUI

@main
public struct EchoLingoPhoneApp: App {
    @State private var privacy = PrivacyConfig(mode: .balanced)

    public init() {}

    public var body: some Scene {
        WindowGroup {
            VStack(spacing: 12) {
                Text("EchoLingo")
                    .font(.largeTitle.bold())
                Text("Real-time voice translation from the wrist.")
                    .foregroundStyle(.secondary)
                Spacer()
                PrivacyBadge(mode: privacy.mode)
            }
            .padding()
        }
    }
}
#endif
