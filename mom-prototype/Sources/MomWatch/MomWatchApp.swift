#if canImport(SwiftUI) && os(watchOS)
import SwiftUI
import MomCore

// Annotate with @main in your Xcode watchOS app target.
public struct MomWatchApp: App {
    public init() {}

    public var body: some Scene {
        WindowGroup {
            // In a real implementation this would show the most-recent
            // scheduled cue and listen for incoming cue envelopes from the phone.
            Text("Waiting for cues…")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
#endif
