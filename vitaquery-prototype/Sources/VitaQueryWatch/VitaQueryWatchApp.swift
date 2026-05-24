#if canImport(SwiftUI) && os(watchOS)
import SwiftUI

// Annotate with @main in your Xcode watchOS app target.
public struct VitaQueryWatchApp: App {
    public init() {}

    public var body: some Scene {
        WindowGroup {
            VStack(spacing: 8) {
                Text("VitaQuery")
                    .font(.headline)
                Text("Ask about HRV, sleep, training load.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}
#endif
