import SwiftUI
import Core

public struct AgentTraceView: View {
    let steps: [AgentStep]

    public init(steps: [AgentStep]) {
        self.steps = steps
    }

    public var body: some View {
        NavigationStack {
            List(steps) { step in
                AgentStepRow(step: step)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .navigationTitle("Agent Trace")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
