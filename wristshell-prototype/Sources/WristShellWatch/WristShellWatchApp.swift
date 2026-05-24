#if canImport(SwiftUI) && os(watchOS)
import SwiftUI
import Core
import CoreUI

// Annotate with @main in your Xcode watchOS app target.
public struct WristShellWatchApp: App {
    public init() {}

    public var body: some Scene {
        WindowGroup { ShellView() }
    }
}

public struct ShellView: View {
    @State private var meter: Float = 0
    @State private var isRecording = false
    @State private var output = ""

    public init() {}

    public var body: some View {
        VStack(spacing: 8) {
            ScrollView {
                Text(output.isEmpty ? "Say a command" : output)
                    .font(.system(.caption, design: .monospaced))
                    .multilineTextAlignment(.leading)
            }
            RecordingOrb(meter: meter, isActive: isRecording)
                .onTapGesture { isRecording.toggle() }
        }
        .padding()
    }
}
#endif
