import Foundation

public struct AllowlistRegistry: Sendable {
    public let templates: [String: CommandTemplate]

    public init(templates: [CommandTemplate]) {
        self.templates = Dictionary(uniqueKeysWithValues: templates.map { ($0.id, $0) })
    }

    /// The default set the prototype ships with. Anything not on this list
    /// can't be invoked, no matter what the LLM says.
    public static let `default`: AllowlistRegistry = AllowlistRegistry(templates: [
        CommandTemplate(
            id: "restart_service",
            description: "Restart a systemd service by name",
            argSchema: [
                ArgSpec(name: "name", kind: .enum, allowed: ["nginx", "redis", "postgresql", "docker"]),
            ],
            bashTemplate: "sudo systemctl restart {name}"
        ),
        CommandTemplate(
            id: "tail_log",
            description: "Show the last N lines of a service log",
            argSchema: [
                ArgSpec(name: "service", kind: .enum, allowed: ["nginx", "redis", "postgresql"]),
                ArgSpec(name: "lines", kind: .int),
            ],
            bashTemplate: "journalctl -u {service} -n {lines} --no-pager",
            requiresBiometric: false
        ),
        CommandTemplate(
            id: "disk_usage",
            description: "Show disk usage for the root partition",
            argSchema: [],
            bashTemplate: "df -h /",
            requiresBiometric: false
        ),
        CommandTemplate(
            id: "uptime",
            description: "Show server uptime and load averages",
            argSchema: [],
            bashTemplate: "uptime",
            requiresBiometric: false
        ),
    ])

    public func validate(_ command: PlannedCommand) -> ValidationResult {
        guard let template = templates[command.template] else {
            return .rejected("Unknown template: \(command.template)")
        }
        for spec in template.argSchema {
            guard let value = command.args[spec.name] else {
                return .rejected("Missing arg: \(spec.name)")
            }
            switch spec.kind {
            case .string:
                continue
            case .int:
                guard Int(value) != nil else {
                    return .rejected("Arg \(spec.name) must be an integer; got \(value)")
                }
            case .enum:
                guard let allowed = spec.allowed, allowed.contains(value) else {
                    return .rejected("Arg \(spec.name)=\(value) not in allowed list")
                }
            }
        }
        return .accepted(template)
    }

    public enum ValidationResult: Sendable {
        case accepted(CommandTemplate)
        case rejected(String)
    }
}
