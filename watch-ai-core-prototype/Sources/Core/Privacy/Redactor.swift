import Foundation

/// Best-effort redaction for log lines. Not a security boundary —
/// don't rely on this to protect anything that matters.
/// (Used to keep dev-time logs from accidentally capturing PII.)
public struct Redactor: Sendable {
    public init() {}

    private static let emailRegex = try! NSRegularExpression(
        pattern: #"[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}"#,
        options: .caseInsensitive
    )

    private static let phoneRegex = try! NSRegularExpression(
        pattern: #"\+?\d[\d\-\s().]{7,}\d"#
    )

    // Bearer / sk- / Bearer-Anthropic style keys, but conservative on length.
    private static let apiKeyRegex = try! NSRegularExpression(
        pattern: #"(?:sk-[a-zA-Z0-9_\-]{16,}|Bearer\s+[A-Za-z0-9_\-\.]{16,})"#
    )

    public func redact(_ input: String) -> String {
        var s = input
        s = replace(in: s, regex: Self.apiKeyRegex, with: "[REDACTED_KEY]")
        s = replace(in: s, regex: Self.emailRegex, with: "[REDACTED_EMAIL]")
        s = replace(in: s, regex: Self.phoneRegex, with: "[REDACTED_PHONE]")
        return s
    }

    private func replace(in input: String, regex: NSRegularExpression, with replacement: String) -> String {
        let range = NSRange(input.startIndex..., in: input)
        return regex.stringByReplacingMatches(
            in: input,
            options: [],
            range: range,
            withTemplate: replacement
        )
    }
}
