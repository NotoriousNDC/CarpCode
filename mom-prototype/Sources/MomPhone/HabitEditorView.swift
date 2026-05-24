#if canImport(SwiftUI) && os(iOS)
import SwiftUI
import MomCore

public struct HabitEditorView: View {
    @State public var habit: Habit
    public let onSave: (Habit) -> Void

    public init(habit: Habit, onSave: @escaping (Habit) -> Void) {
        _habit = State(initialValue: habit)
        self.onSave = onSave
    }

    public var body: some View {
        Form {
            Section("Habit") {
                TextField("Name", text: $habit.name)
                Picker("Glyph", selection: $habit.glyph) {
                    ForEach(Glyph.allCases, id: \.self) { g in
                        Label(g.rawValue, systemImage: g.rawValue).tag(g)
                    }
                }
                Stepper("Target per day: \(habit.targetPerDay)", value: $habit.targetPerDay, in: 1...12)
            }
            Section {
                Button("Save") { onSave(habit) }
            }
        }
        .navigationTitle("Edit Habit")
    }
}
#endif
