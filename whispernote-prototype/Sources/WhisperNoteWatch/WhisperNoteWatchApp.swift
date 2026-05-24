#if canImport(SwiftUI) && os(watchOS)
import SwiftUI

// Annotate with @main in your Xcode watchOS app target.
public struct WhisperNoteWatchApp: App {
    public init() {}

    public var body: some Scene {
        WindowGroup {
            CaptureView()
        }
    }
}
#endif
