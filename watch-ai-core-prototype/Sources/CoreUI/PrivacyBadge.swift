#if canImport(SwiftUI)
import SwiftUI
import Core

/// Small persistent footer/header chip showing the current privacy mode.
/// Every settings screen in every app should surface this.
public struct PrivacyBadge: View {
    public let mode: PrivacyMode

    public init(mode: PrivacyMode) { self.mode = mode }

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(mode.displayName)
        }
        .font(.caption2.weight(.semibold))
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(color.opacity(0.18))
        .foregroundColor(color)
        .clipShape(Capsule())
    }

    private var icon: String {
        switch mode {
        case .strict: "lock.shield.fill"
        case .balanced: "shield.lefthalf.filled"
        case .convenience: "shield"
        }
    }

    private var color: Color {
        switch mode {
        case .strict: .green
        case .balanced: .blue
        case .convenience: .orange
        }
    }
}
#endif
