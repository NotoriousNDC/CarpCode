#if canImport(SwiftUI)
import SwiftUI
import Core

/// Animated audio-level orb used by every voice-capture screen across the suite.
/// Drives a soft pulse from a `meter` value in [0, 1].
public struct RecordingOrb: View {
    public let meter: Float
    public let isActive: Bool

    public init(meter: Float, isActive: Bool) {
        self.meter = meter
        self.isActive = isActive
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(isActive ? Color.red.opacity(0.18) : Color.gray.opacity(0.18))
                .frame(width: 120, height: 120)
                .scaleEffect(1 + CGFloat(meter) * 0.4)
                .animation(.easeOut(duration: 0.1), value: meter)
            Circle()
                .fill(isActive ? Color.red : Color.gray)
                .frame(width: 60, height: 60)
        }
    }
}
#endif
