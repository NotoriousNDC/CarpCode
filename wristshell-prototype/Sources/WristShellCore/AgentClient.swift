import Foundation
import Core

/// Client for the VPS-side agent. Two modes:
///   - `.tailscale(endpoint)`: private, no public exposure. Default.
///   - `.publicMTLS(url, ...)`: standalone fallback for cellular watch.
public enum AgentTransport: Sendable {
    case tailscale(TailscaleEndpoint)
    case publicMTLS(URL, clientCertPEM: String, clientKeyPEM: String, bearerToken: String)
}

public struct AgentResponse: Codable, Sendable {
    public let stdout: String
    public let stderr: String
    public let exitCode: Int32
    public let durationMs: Int

    public init(stdout: String, stderr: String, exitCode: Int32, durationMs: Int) {
        self.stdout = stdout
        self.stderr = stderr
        self.exitCode = exitCode
        self.durationMs = durationMs
    }
}

public enum AgentError: Error, LocalizedError {
    case unreachable
    case rejected(String)
    case badResponse(String)

    public var errorDescription: String? {
        switch self {
        case .unreachable: "Agent unreachable. Check Tailscale connection."
        case .rejected(let r): "Agent rejected the request: \(r)"
        case .badResponse(let b): "Agent returned an invalid response: \(b)"
        }
    }
}

public struct AgentClient: Sendable {
    public let transport: AgentTransport
    public let http: HTTPClient

    public init(transport: AgentTransport, http: HTTPClient = HTTPClient()) {
        self.transport = transport
        self.http = http
    }

    public func execute(_ command: PlannedCommand) async throws -> AgentResponse {
        var request: URLRequest
        switch transport {
        case .tailscale(let endpoint):
            guard let url = endpoint.url?.appendingPathComponent("v1/exec") else {
                throw AgentError.unreachable
            }
            request = URLRequest(url: url)
        case .publicMTLS(let url, _, _, let token):
            request = URLRequest(url: url.appendingPathComponent("v1/exec"))
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONCoder.encoder.encode(command)

        let data = try await http.data(for: request, cloudPurpose: .userOwnedEndpoint)
        do {
            return try JSONCoder.decoder.decode(AgentResponse.self, from: data)
        } catch {
            throw AgentError.badResponse(String(data: data, encoding: .utf8) ?? "")
        }
    }
}
