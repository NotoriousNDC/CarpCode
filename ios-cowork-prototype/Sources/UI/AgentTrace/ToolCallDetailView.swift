import SwiftUI
import Core

public struct ToolCallDetailView: View {
    let call: ToolCall

    public init(call: ToolCall) {
        self.call = call
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(call.name, systemImage: "wrench.and.screwdriver.fill")
                .font(.headline)

            section("Input", content: call.input)

            if let result = call.result {
                section(result.isError ? "Error" : "Output", content: result.content)
                    .foregroundStyle(result.isError ? .red : .primary)
            }
        }
        .padding()
    }

    @ViewBuilder
    private func section(_ title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            ScrollView(.horizontal) {
                Text(content)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
            }
            .padding(8)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
