import SwiftUI
import Core
import UI

@main
struct CarpCoworkApp: App {
    @State private var settings = AppSettings.load()
    @State private var keychain = KeychainStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
        }
    }
}
