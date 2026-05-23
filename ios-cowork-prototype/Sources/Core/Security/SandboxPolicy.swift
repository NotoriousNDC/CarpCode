import Foundation

public enum SandboxError: Error, LocalizedError {
    case outsideAllowedRoot(URL)
    case pathTraversal(String)

    public var errorDescription: String? {
        switch self {
        case .outsideAllowedRoot(let url): return "Path '\(url.path)' is outside the allowed sandbox."
        case .pathTraversal(let path): return "Path traversal attempt detected: '\(path)'"
        }
    }
}

public struct SandboxPolicy: Sendable {
    public let allowedRoots: [URL]

    public static let `default` = SandboxPolicy(allowedRoots: [
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!,
        FileManager.default.temporaryDirectory,
    ])

    public init(allowedRoots: [URL]) {
        self.allowedRoots = allowedRoots
    }

    public func validate(path: URL) throws {
        // Block path traversal
        if path.path.contains("..") {
            throw SandboxError.pathTraversal(path.path)
        }

        let resolved = path.standardizedFileURL
        for root in allowedRoots {
            if resolved.path.hasPrefix(root.standardizedFileURL.path) {
                return
            }
        }
        throw SandboxError.outsideAllowedRoot(path)
    }
}
