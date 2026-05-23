import SwiftUI
import Core

public struct MessageBubble: View {
    let message: Message

    public init(message: Message) {
        self.message = message
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .assistant || message.role == .tool {
                roleIcon
                    .frame(width: 28)
            }

            contentView
                .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .user {
                Spacer(minLength: 40)
            }
        }
    }

    @ViewBuilder
    private var roleIcon: some View {
        Image(systemName: message.role == .tool ? "wrench.and.screwdriver" : "cpu")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
    }

    @ViewBuilder
    private var contentView: some View {
        switch message.content {
        case .text(let text):
            textBubble(text: text, isUser: message.role == .user)
        case .toolResult(_, let content, let isError):
            toolResultBubble(content: content, isError: isError)
        case .toolUse(_, let name, let input):
            toolUseBubble(name: name, input: input)
        case .multipart:
            textBubble(text: message.content.plainText, isUser: message.role == .user)
        }
    }

    @ViewBuilder
    private func textBubble(text: String, isUser: Bool) -> some View {
        let parts = parseCodeBlocks(text)
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                if part.isCode {
                    CodeBlockView(code: part.text, language: part.language)
                } else {
                    Text(part.text)
                        .textSelection(.enabled)
                }
            }
        }
        .padding(10)
        .background(isUser ? Color.accentColor.opacity(0.15) : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func toolResultBubble(content: String, isError: Bool) -> some View {
        Text(content.prefix(300))
            .font(.caption.monospaced())
            .foregroundStyle(isError ? .red : .secondary)
            .padding(8)
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func toolUseBubble(name: String, input: String) -> some View {
        Label(name, systemImage: "wrench.and.screwdriver.fill")
            .font(.caption.bold())
            .foregroundStyle(.secondary)
    }

    // Simple code-block detector: splits on ```lang\n...\n```
    private struct TextPart {
        let text: String
        let isCode: Bool
        let language: String?
    }

    private func parseCodeBlocks(_ text: String) -> [TextPart] {
        var parts: [TextPart] = []
        let pattern = "```(\\w*)\\n([\\s\\S]*?)```"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [TextPart(text: text, isCode: false, language: nil)]
        }
        var lastEnd = text.startIndex
        let range = NSRange(text.startIndex..., in: text)
        for match in regex.matches(in: text, range: range) {
            guard let fullRange = Range(match.range, in: text) else { continue }
            let prefix = String(text[lastEnd..<fullRange.lowerBound])
            if !prefix.isEmpty { parts.append(TextPart(text: prefix, isCode: false, language: nil)) }

            let lang = Range(match.range(at: 1), in: text).map { String(text[$0]) }
            let code = Range(match.range(at: 2), in: text).map { String(text[$0]) } ?? ""
            parts.append(TextPart(text: code, isCode: true, language: lang?.isEmpty == true ? nil : lang))
            lastEnd = fullRange.upperBound
        }
        let tail = String(text[lastEnd...])
        if !tail.isEmpty { parts.append(TextPart(text: tail, isCode: false, language: nil)) }
        return parts.isEmpty ? [TextPart(text: text, isCode: false, language: nil)] : parts
    }
}
