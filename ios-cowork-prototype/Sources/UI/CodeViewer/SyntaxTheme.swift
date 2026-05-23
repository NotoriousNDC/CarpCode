import SwiftUI

public struct SyntaxTheme {
    public let background: Color
    public let text: Color
    public let keyword: Color
    public let string: Color
    public let comment: Color
    public let number: Color

    public static let dark = SyntaxTheme(
        background: Color(red: 0.11, green: 0.11, blue: 0.13),
        text: Color(red: 0.85, green: 0.85, blue: 0.85),
        keyword: Color(red: 0.95, green: 0.4, blue: 0.55),
        string: Color(red: 0.55, green: 0.85, blue: 0.55),
        comment: Color(red: 0.5, green: 0.5, blue: 0.5),
        number: Color(red: 0.7, green: 0.55, blue: 0.95)
    )

    public static let light = SyntaxTheme(
        background: Color(red: 0.97, green: 0.97, blue: 0.98),
        text: Color(red: 0.1, green: 0.1, blue: 0.1),
        keyword: Color(red: 0.7, green: 0.1, blue: 0.3),
        string: Color(red: 0.1, green: 0.5, blue: 0.1),
        comment: Color(red: 0.4, green: 0.4, blue: 0.4),
        number: Color(red: 0.4, green: 0.1, blue: 0.7)
    )
}
