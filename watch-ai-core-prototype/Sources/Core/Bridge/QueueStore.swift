import Foundation

/// Disk-backed FIFO queue for envelopes that need to be delivered later
/// (watch is offline, phone is unreachable, etc.). Persisted as JSON lines.
///
/// Not high-throughput; built for low-volume background sync.
public final class QueueStore: @unchecked Sendable {
    private let url: URL
    private let lock = NSLock()

    public init(name: String) {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("watch-ai-core/queues", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.url = dir.appendingPathComponent("\(name).jsonl")
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }
    }

    public func enqueue(_ envelope: BridgeEnvelope) throws {
        lock.lock(); defer { lock.unlock() }
        let line = try JSONCoder.encoder.encode(envelope) + Data("\n".utf8)
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: line)
    }

    /// Drain everything; returns the dequeued envelopes. Caller is responsible
    /// for re-enqueueing anything that fails to deliver.
    public func drain() throws -> [BridgeEnvelope] {
        lock.lock(); defer { lock.unlock() }
        let data = try Data(contentsOf: url)
        try Data().write(to: url)
        guard !data.isEmpty else { return [] }
        return data.split(separator: 0x0A).compactMap { line in
            try? JSONCoder.decoder.decode(BridgeEnvelope.self, from: Data(line))
        }
    }
}
