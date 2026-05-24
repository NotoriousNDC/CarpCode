#if canImport(SwiftUI) && os(iOS)
import SwiftUI
import Core
import WhisperNoteCore

@main
public struct WhisperNotePhoneApp: App {
    @State private var privacy = PrivacyConfig(mode: .balanced)
    @State private var store: NoteStoreBackend = LocalFileNoteStore()

    public init() {}

    public var body: some Scene {
        WindowGroup {
            NoteListView(model: NoteListViewModel(store: store, privacy: privacy))
        }
    }
}
#endif
