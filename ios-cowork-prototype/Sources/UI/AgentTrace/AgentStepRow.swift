import SwiftUI
import Core

public struct AgentStepRow: View {
    let step: AgentStep
    @State private var isExpanded = false

    public init(step: AgentStep) {
        self.step = step
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                if step.detail != nil { withAnimation { isExpanded.toggle() } }
            } label: {
                HStack(spacing: 10) {
                    phaseIcon
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.phase.displayName)
                            .font(.caption.bold())
                            .foregroundStyle(.primary)
                        Text(step.content)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Spacer()
                    statusBadge
                    if step.detail != nil {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .buttonStyle(.plain)

            if isExpanded, let detail = step.detail {
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(detail)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .padding(8)
                }
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var phaseIcon: some View {
        Image(systemName: step.phase.symbolName)
            .font(.callout)
            .foregroundStyle(iconColor)
            .frame(width: 24)
    }

    private var iconColor: Color {
        switch step.status {
        case .running: return .accentColor
        case .completed: return .green
        case .failed: return .red
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch step.status {
        case .running:
            ProgressView()
                .controlSize(.mini)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
        case .failed(let reason):
            Image(systemName: "xmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.red)
                .help(reason)
        }
    }
}
