#if canImport(SwiftUI) && os(watchOS)
import SwiftUI
import Core
import CoreUI

@main
public struct AskBandWatchApp: App {
    public init() {}

    public var body: some Scene {
        WindowGroup {
            AnswerView()
        }
    }
}

public struct AnswerView: View {
    @State private var meter: Float = 0
    @State private var isRecording = false
    @State private var answer: String = ""

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            ScrollView {
                Text(answer.isEmpty ? "Tap to ask" : answer)
                    .multilineTextAlignment(.center)
                    .font(.body)
            }
            RecordingOrb(meter: meter, isActive: isRecording)
                .onTapGesture {
                    // Real impl: wire to AskBandCore.AskSession via WatchPhoneBridge
                    isRecording.toggle()
                }
        }
        .padding()
    }
}
#endif
