#if canImport(SwiftUI) && os(iOS)
import SwiftUI
import Core
import CoreUI

@main
public struct VitaQueryPhoneApp: App {
    @State private var privacy = PrivacyConfig(mode: .balanced)

    public init() {}

    public var body: some Scene {
        WindowGroup {
            VStack(spacing: 12) {
                Text("VitaQuery")
                    .font(.largeTitle.bold())
                Text("Natural-language HealthKit queries.")
                    .foregroundStyle(.secondary)
                Spacer()
                PrivacyBadge(mode: privacy.mode)
            }
            .padding()
        }
    }
}
#endif
