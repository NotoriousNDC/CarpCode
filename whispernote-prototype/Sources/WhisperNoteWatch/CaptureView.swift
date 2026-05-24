#if canImport(SwiftUI) && os(watchOS)
import SwiftUI
import Core
import CoreUI

/// Watch-side capture screen. Tap to start, tap again to stop, audio is
/// shipped to the phone for processing. The watch never displays the
/// finished note in this prototype — that's the phone's job — but it
/// shows a "sent" confirmation.
public struct CaptureView: View {
    @StateObject private var model = CaptureViewModel()

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            RecordingOrb(meter: model.meter, isActive: model.isRecording)
                .onTapGesture {
                    Task { await model.toggle() }
                }
            Text(model.statusLine)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .onAppear { model.activate() }
    }
}

@MainActor
public final class CaptureViewModel: ObservableObject {
    @Published public private(set) var isRecording = false
    @Published public private(set) var meter: Float = 0
    @Published public private(set) var statusLine = "Tap to record"

    private let recorder = AudioRecorder()
    private let bridge = WatchPhoneBridge()
    private var meterTask: Task<Void, Never>?

    public init() {}

    public func activate() {
        bridge.activate()
    }

    public func toggle() async {
        if isRecording {
            stopAndSend()
        } else {
            await start()
        }
    }

    private func start() async {
        guard await recorder.requestPermission() else {
            statusLine = "Microphone permission denied"
            return
        }
        do {
            let url = try recorder.start()
            isRecording = true
            statusLine = "Listening…"
            meterTask = Task {
                while !Task.isCancelled && isRecording {
                    meter = recorder.meter()
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
            }
            _ = url
        } catch {
            statusLine = "Couldn't start: \(error.localizedDescription)"
        }
    }

    private func stopAndSend() {
        meterTask?.cancel(); meterTask = nil
        guard let url = recorder.stop() else {
            statusLine = "No recording active"
            return
        }
        isRecording = false
        meter = 0
        statusLine = "Sending to phone…"

        do {
            let payload = WatchToPhonePayload(audioFilename: url.lastPathComponent)
            let envelope = try BridgeEnvelope.make(kind: "whispernote.recording", payload)
            bridge.send(envelope)
            // The audio file itself is transferred separately via
            // WCSession.transferFile in a fuller implementation.
            statusLine = "Sent"
        } catch {
            statusLine = "Send failed: \(error.localizedDescription)"
        }
    }
}

public struct WatchToPhonePayload: Codable, Sendable {
    public let audioFilename: String
    public init(audioFilename: String) { self.audioFilename = audioFilename }
}
#endif
