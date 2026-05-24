#if canImport(SwiftUI) && os(watchOS)
import SwiftUI
import EchoLingoCore

@main
public struct EchoLingoWatchApp: App {
    public init() {}

    public var body: some Scene {
        WindowGroup { ConversationView() }
    }
}

public struct ConversationView: View {
    @State private var direction: Direction = .aToB
    @State private var lastTranslation: String = ""

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("EN").opacity(direction == .aToB ? 1.0 : 0.4)
                Image(systemName: "arrow.left.arrow.right")
                Text("ES").opacity(direction == .bToA ? 1.0 : 0.4)
            }
            .font(.headline)
            Text(lastTranslation.isEmpty ? "Flip wrist to switch direction" : lastTranslation)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
#endif
