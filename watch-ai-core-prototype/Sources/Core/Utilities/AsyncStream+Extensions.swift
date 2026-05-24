import Foundation

extension AsyncThrowingStream where Element: Sendable, Failure == Error {
    /// Collects all values from a stream into an array. Useful for tests.
    public func collect() async throws -> [Element] {
        var results: [Element] = []
        for try await element in self { results.append(element) }
        return results
    }
}

extension AsyncThrowingStream where Element == CompletionChunk, Failure == Error {
    /// Concatenates all `textDelta` chunks into a single string.
    /// Discards tool-call chunks. (For apps that don't use tools — Mom does;
    /// AskBand does not.)
    public func joinedText() async throws -> String {
        var out = ""
        for try await chunk in self {
            if case .textDelta(let t) = chunk { out += t }
        }
        return out
    }
}
