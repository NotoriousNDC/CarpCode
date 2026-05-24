#if canImport(SwiftUI) && os(watchOS)
import SwiftUI
import Core
import CoreUI
import MomCore

public struct CueView: View {
    public let cue: ScheduledCue
    public let onDone: () -> Void
    public let onSnooze: (String?) -> Void

    public init(cue: ScheduledCue, onDone: @escaping () -> Void, onSnooze: @escaping (String?) -> Void) {
        self.cue = cue
        self.onDone = onDone
        self.onSnooze = onSnooze
    }

    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: cue.glyph.rawValue)
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.tint)
            Text(cue.title)
                .font(.headline)
                .multilineTextAlignment(.center)
            HStack(spacing: 16) {
                Button(action: { onSnooze(nil) }) {
                    Image(systemName: "zzz")
                }
                .buttonStyle(.bordered)
                Button(action: onDone) {
                    Image(systemName: "checkmark")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
#endif
