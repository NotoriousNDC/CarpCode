#if canImport(SwiftUI)
import SwiftUI

/// Shared visual constants. Apps may override individual values; the suite
/// stays cohesive when they don't.
public enum WatchAITheme {
    public static let accent: Color = .accentColor
    public static let surface: Color = Color(white: 0.08)
    public static let danger: Color = .red
    public static let success: Color = .green

    public static let cornerRadius: CGFloat = 12
}
#endif
