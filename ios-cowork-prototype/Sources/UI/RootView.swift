import SwiftUI
import Core

public struct RootView: View {
    @Environment(AppSettings.self) private var settings

    public init() {}

    public var body: some View {
        TabView {
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
