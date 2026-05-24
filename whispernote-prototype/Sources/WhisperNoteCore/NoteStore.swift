import Foundation
import Core

/// Persists notes. Default impl is a JSON file in Application Support; swap
/// for CloudKit by passing a different `Backend`.
public protocol NoteStoreBackend: Sendable {
    func save(_ note: Note) async throws
    func loadAll() async throws -> [Note]
    func delete(id: UUID) async throws
}

public actor LocalFileNoteStore: NoteStoreBackend {
    private let url: URL

    public init(filename: String = "whispernote-notes.json") {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("whispernote", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.url = dir.appendingPathComponent(filename)
    }

    public func save(_ note: Note) async throws {
        var notes = (try? load()) ?? []
        notes.removeAll { $0.id == note.id }
        notes.append(note)
        try write(notes)
    }

    public func loadAll() async throws -> [Note] {
        try load().sorted { $0.capturedAt > $1.capturedAt }
    }

    public func delete(id: UUID) async throws {
        var notes = (try? load()) ?? []
        notes.removeAll { $0.id == id }
        try write(notes)
    }

    private func load() throws -> [Note] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        guard !data.isEmpty else { return [] }
        return try JSONCoder.decoder.decode([Note].self, from: data)
    }

    private func write(_ notes: [Note]) throws {
        let data = try JSONCoder.encoder.encode(notes)
        try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}
