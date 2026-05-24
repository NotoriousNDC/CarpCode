#if canImport(SwiftUI) && os(watchOS)
import SwiftUI

@main
public struct WhisperNoteWatchApp: App {
    public init() {}

    public var body: some Scene {
        WindowGroup {
            CaptureView()
        }
    }
}
#endif
