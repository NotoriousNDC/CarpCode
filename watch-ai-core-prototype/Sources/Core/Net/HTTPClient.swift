import Foundation

public enum HTTPClientError: Error, LocalizedError {
    case noResponse
    case status(Int, body: String)
    case privacyBlocked(String)

    public var errorDescription: String? {
        switch self {
        case .noResponse: "No HTTP response"
        case .status(let code, let body): "HTTP \(code): \(body.prefix(200))"
        case .privacyBlocked(let reason): "Blocked by privacy config: \(reason)"
        }
    }
}

/// Thin URLSession wrapper. Centralizes timeouts, SSE streaming, and the
/// privacy gate on outbound cloud requests.
///
/// The privacy gate is intentionally coarse — features that need finer
/// control should consult `PrivacyConfig` directly.
public final class HTTPClient: @unchecked Sendable {
    public let privacy: PrivacyConfig
    private let session: URLSession

    public init(privacy: PrivacyConfig = .init(),
                requestTimeout: TimeInterval = 30,
                resourceTimeout: TimeInterval = 600) {
        self.privacy = privacy
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = requestTimeout
        config.timeoutIntervalForResource = resourceTimeout
        // Strict mode: don't keep request bodies around in URL cache.
        if privacy.mode == .strict {
            config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            config.urlCache = nil
        }
        self.session = URLSession(configuration: config)
    }

    public func data(for request: URLRequest, cloudPurpose: CloudPurpose) async throws -> Data {
        try gate(cloudPurpose)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw HTTPClientError.noResponse }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw HTTPClientError.status(http.statusCode, body: body)
        }
        return data
    }

    /// Stream Server-Sent Events from a request.
    public func streamSSE(request: URLRequest, cloudPurpose: CloudPurpose) -> AsyncThrowingStream<SSEEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    try self.gate(cloudPurpose)
                    var parser = SSEParser()
                    let (bytes, response) = try await self.session.bytes(for: request)
                    guard let http = response as? HTTPURLResponse else {
                        continuation.finish(throwing: HTTPClientError.noResponse); return
                    }
                    guard (200..<300).contains(http.statusCode) else {
                        continuation.finish(throwing: HTTPClientError.status(http.statusCode, body: "")); return
                    }
                    var lineBuffer = ""
                    for try await byte in bytes {
                        let char = Character(UnicodeScalar(byte))
                        lineBuffer.append(char)
                        if char == "\n" {
                            for event in parser.feed(lineBuffer) where event.data != "[DONE]" {
                                continuation.yield(event)
                            }
                            if lineBuffer.contains("[DONE]") { break }
                            lineBuffer = ""
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func gate(_ purpose: CloudPurpose) throws {
        switch purpose {
        case .transcription where !privacy.allowsCloudTranscription:
            throw HTTPClientError.privacyBlocked("cloud transcription disabled in Strict mode")
        case .llm where !privacy.allowsCloudLLM:
            throw HTTPClientError.privacyBlocked("cloud LLM disabled in Strict mode")
        default:
            break
        }
    }
}

public enum CloudPurpose: Sendable {
    case llm
    case transcription
    case translation
    /// User-initiated, already privacy-reviewed (e.g. WristShell to user's own VPS).
    case userOwnedEndpoint
}
