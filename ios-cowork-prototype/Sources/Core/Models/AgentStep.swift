import Foundation

public struct AgentStep: Identifiable, Sendable {
    public let id: UUID
    public let phase: Phase
    public var status: Status
    public let startedAt: Date
    public var completedAt: Date?
    public var content: String        // human-readable summary shown in trace UI
    public var detail: String?        // full raw text (tool I/O, model output)

    public init(
        id: UUID = UUID(),
        phase: Phase,
        status: Status = .running,
        startedAt: Date = Date(),
        content: String,
        detail: String? = nil
    ) {
        self.id = id
        self.phase = phase
        self.status = status
        self.startedAt = startedAt
        self.content = content
        self.detail = detail
    }

    public enum Phase: Sendable, Equatable {
        case planning
        case acting(toolName: String)
        case observing
        case reflecting
        case responding

        public var displayName: String {
            switch self {
            case .planning: return "Planning"
            case .acting(let name): return "Using \(name)"
            case .observing: return "Observing"
            case .reflecting: return "Reflecting"
            case .responding: return "Responding"
            }
        }

        public var symbolName: String {
            switch self {
            case .planning: return "brain"
            case .acting: return "wrench.and.screwdriver"
            case .observing: return "eye"
            case .reflecting: return "arrow.triangle.2.circlepath"
            case .responding: return "checkmark.bubble"
            }
        }
    }

    public enum Status: Sendable, Equatable {
        case running
        case completed
        case failed(String)

        public var isTerminal: Bool {
            switch self {
            case .running: return false
            case .completed, .failed: return true
            }
        }
    }

    public mutating func complete(detail: String? = nil) {
        self.status = .completed
        self.completedAt = Date()
        if let d = detail { self.detail = d }
    }

    public mutating func fail(_ reason: String) {
        self.status = .failed(reason)
        self.completedAt = Date()
    }
}
