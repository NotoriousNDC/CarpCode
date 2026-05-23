import Foundation

public extension AsyncThrowingStream {
    // Collect all elements into an array
    static func collect(_ stream: AsyncThrowingStream<Element, Error>) async throws -> [Element] {
        var results: [Element] = []
        for try await element in stream {
            results.append(element)
        }
        return results
    }
}

public extension AsyncThrowingStream where Element == String {
    // Concatenate all string chunks into a single string
    static func joined(_ stream: AsyncThrowingStream<String, Error>) async throws -> String {
        var result = ""
        for try await chunk in stream {
            result += chunk
        }
        return result
    }
}

// Bridge a callback-based async operation to AsyncThrowingStream
public func makeAsyncStream<T: Sendable>(
    _ operation: @escaping (AsyncThrowingStream<T, Error>.Continuation) async throws -> Void
) -> AsyncThrowingStream<T, Error> {
    AsyncThrowingStream { continuation in
        Task {
            do {
                try await operation(continuation)
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}
