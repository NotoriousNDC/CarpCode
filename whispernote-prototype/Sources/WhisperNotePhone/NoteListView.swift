#if canImport(SwiftUI) && os(iOS)
import SwiftUI
import Core
import CoreUI
import WhisperNoteCore

public struct NoteListView: View {
    @StateObject var model: NoteListViewModel

    public init(model: NoteListViewModel) {
        _model = StateObject(wrappedValue: model)
    }

    public var body: some View {
        NavigationStack {
            List {
                ForEach(model.notes) { note in
                    NavigationLink(value: note.id) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.title).font(.headline)
                            Text(note.capturedAt, style: .relative)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    Task { await model.delete(at: offsets) }
                }
            }
            .navigationTitle("WhisperNote")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    PrivacyBadge(mode: model.privacy.mode)
                }
            }
            .navigationDestination(for: UUID.self) { id in
                if let note = model.notes.first(where: { $0.id == id }) {
                    NoteDetailView(note: note)
                }
            }
        }
        .task { await model.load() }
    }
}

public struct NoteDetailView: View {
    public let note: Note

    public init(note: Note) { self.note = note }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let body = note.cleanedBody {
                    Text(body)
                } else {
                    Text(note.transcript).foregroundStyle(.secondary)
                }
                if !note.actionItems.isEmpty {
                    Divider()
                    Text("Action items").font(.headline)
                    ForEach(note.actionItems, id: \.self) { item in
                        Label(item, systemImage: "checkmark.circle")
                    }
                }
            }
            .padding()
        }
        .navigationTitle(note.title)
    }
}

@MainActor
public final class NoteListViewModel: ObservableObject {
    @Published public private(set) var notes: [Note] = []
    public let privacy: PrivacyConfig
    private let store: NoteStoreBackend

    public init(store: NoteStoreBackend, privacy: PrivacyConfig) {
        self.store = store
        self.privacy = privacy
    }

    public func load() async {
        notes = (try? await store.loadAll()) ?? []
    }

    public func delete(at offsets: IndexSet) async {
        for index in offsets {
            try? await store.delete(id: notes[index].id)
        }
        await load()
    }
}
#endif
