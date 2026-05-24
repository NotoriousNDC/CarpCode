import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif

public enum AudioRecorderError: Error, LocalizedError {
    case sessionSetupFailed(String)
    case recorderInitFailed(String)
    case permissionDenied
    case unsupportedPlatform

    public var errorDescription: String? {
        switch self {
        case .sessionSetupFailed(let m): "Audio session setup failed: \(m)"
        case .recorderInitFailed(let m): "Recorder init failed: \(m)"
        case .permissionDenied: "Microphone permission denied"
        case .unsupportedPlatform: "Audio recording unavailable on this platform"
        }
    }
}

/// Records m4a audio to a sandboxed file. Designed to be the same surface on
/// watchOS and iOS so app code is portable.
///
/// Files are written with Data Protection class
/// `completeUntilFirstUserAuthentication` so audio is encrypted at rest.
public final class AudioRecorder: NSObject, @unchecked Sendable {
#if canImport(AVFoundation)
    private var recorder: AVAudioRecorder?
#endif
    private let outputDirectory: URL

    public init(outputDirectory: URL? = nil) {
        let dir = outputDirectory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("audio-recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.outputDirectory = dir
        super.init()
    }

    public func requestPermission() async -> Bool {
#if canImport(AVFoundation)
        if #available(iOS 17.0, watchOS 10.0, *) {
            return await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        } else {
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
#else
        return false
#endif
    }

    @discardableResult
    public func start(name: String = ISO8601DateFormatter().string(from: Date())) throws -> URL {
#if canImport(AVFoundation)
        let url = outputDirectory.appendingPathComponent("\(name).m4a")
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            throw AudioRecorderError.sessionSetupFailed(error.localizedDescription)
        }
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
        ]
        do {
            let r = try AVAudioRecorder(url: url, settings: settings)
            r.isMeteringEnabled = true
            guard r.record() else { throw AudioRecorderError.recorderInitFailed("record() returned false") }
            self.recorder = r
            // Mark file with strong data protection.
            try? FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: url.path
            )
            return url
        } catch {
            throw AudioRecorderError.recorderInitFailed(error.localizedDescription)
        }
#else
        throw AudioRecorderError.unsupportedPlatform
#endif
    }

    public func stop() -> URL? {
#if canImport(AVFoundation)
        guard let r = recorder else { return nil }
        r.stop()
        let url = r.url
        recorder = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        return url
#else
        return nil
#endif
    }

    /// 0...1 normalized average power. Useful for the recording orb visual.
    public func meter() -> Float {
#if canImport(AVFoundation)
        guard let r = recorder else { return 0 }
        r.updateMeters()
        let db = r.averagePower(forChannel: 0)
        let minDb: Float = -60
        guard db > minDb else { return 0 }
        return min(1, (db - minDb) / -minDb)
#else
        return 0
#endif
    }
}
