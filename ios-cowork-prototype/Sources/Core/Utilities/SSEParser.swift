import Foundation

public struct SSEEvent: Sendable {
    public let event: String?
    public let data: String
    public let id: String?

    public var isDataLine: Bool { !data.isEmpty && data != "[DONE]" }
}

// Stateful parser — feed it raw bytes as they arrive from URLSession.
// Returns any complete events accumulated since the last call.
public struct SSEParser: Sendable {
    private var buffer: String = ""

    public init() {}

    public mutating func feed(_ bytes: ArraySlice<UInt8>) -> [SSEEvent] {
        guard let chunk = String(bytes: bytes, encoding: .utf8) else { return [] }
        buffer += chunk
        return extractEvents()
    }

    public mutating func feed(_ string: String) -> [SSEEvent] {
        buffer += string
        return extractEvents()
    }

    // Call at stream end to flush any remaining partial event
    public mutating func flush() -> [SSEEvent] {
        guard !buffer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        buffer += "\n\n"
        return extractEvents()
    }

    private mutating func extractEvents() -> [SSEEvent] {
        var events: [SSEEvent] = []
        // Events are separated by blank lines
        while let range = buffer.range(of: "\n\n") {
            let block = String(buffer[buffer.startIndex..<range.lowerBound])
            buffer = String(buffer[range.upperBound...])
            if let event = parse(block: block) {
                events.append(event)
            }
        }
        return events
    }

    private func parse(block: String) -> SSEEvent? {
        var eventType: String? = nil
        var dataLines: [String] = []
        var id: String? = nil

        for line in block.components(separatedBy: "\n") {
            if line.hasPrefix("event:") {
                eventType = line.dropFirst(6).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("data:") {
                dataLines.append(String(line.dropFirst(5).trimmingCharacters(in: .init(charactersIn: " "))))
            } else if line.hasPrefix("id:") {
                id = line.dropFirst(3).trimmingCharacters(in: .whitespaces)
            }
            // retry and comment lines are ignored
        }

        guard !dataLines.isEmpty else { return nil }
        return SSEEvent(event: eventType, data: dataLines.joined(separator: "\n"), id: id)
    }
}
