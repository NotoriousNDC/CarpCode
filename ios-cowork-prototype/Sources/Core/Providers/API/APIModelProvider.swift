import Foundation

// Shared URLSession + SSE streaming logic for all remote providers.
open class APIModelProvider: @unchecked Sendable {
    public let model: String
    public let apiKey: String
    public let baseURL: URL
    public let isOnDevice: Bool = false

    private let session: URLSession

    public init(model: String, apiKey: String, baseURL: URL) {
        self.model = model
        self.apiKey = apiKey
        self.baseURL = baseURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 600
        self.session = URLSession(configuration: config)
    }

    // Stream raw SSE events from a URLRequest
    public func streamSSE(request: URLRequest) -> AsyncThrowingStream<SSEEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = self.session.dataTask(with: request) { _, _, error in
                if let error { continuation.finish(throwing: error) }
            }

            // Use URLSession delegate-based streaming via bytes API (iOS 15+)
            Task {
                do {
                    var parser = SSEParser()
                    let (bytes, response) = try await self.session.bytes(for: request)
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: ProviderError.networkError("No HTTP response"))
                        return
                    }
                    guard (200..<300).contains(httpResponse.statusCode) else {
                        continuation.finish(throwing: ProviderError.networkError("HTTP \(httpResponse.statusCode)"))
                        return
                    }
                    var lineBuffer = ""
                    for try await byte in bytes {
                        let char = Character(UnicodeScalar(byte))
                        lineBuffer.append(char)
                        if char == "\n" {
                            let events = parser.feed(lineBuffer)
                            lineBuffer = ""
                            for event in events where event.data != "[DONE]" {
                                continuation.yield(event)
                            }
                            if events.contains(where: { $0.data == "[DONE]" }) {
                                break
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            _ = task  // retained by URLSession
        }
    }

    public func fetchData(request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ProviderError.networkError("No HTTP response")
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw ProviderError.networkError("HTTP \(http.statusCode): \(body.prefix(200))")
        }
        return data
    }

    // Subclasses must override
    open var id: String { fatalError("Subclasses must override id") }
    open var displayName: String { fatalError("Subclasses must override displayName") }
    open var supportsTools: Bool { return true }
}
