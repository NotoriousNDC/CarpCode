import Foundation

/// Marker for an endpoint reachable only via the user's Tailscale tailnet.
/// Used by `wristshell-prototype` to differentiate "private mesh" endpoints
/// from public mTLS endpoints.
///
/// At runtime, `isReachable()` performs a best-effort reachability probe.
/// True positives prove the tailnet is up; the only way to truly know the
/// endpoint is reachable is to try the request.
public struct TailscaleEndpoint: Sendable, Codable {
    public let host: String     // e.g. "vps-1.tail-abc123.ts.net" or "100.x.y.z"
    public let port: Int

    public init(host: String, port: Int = 443) {
        self.host = host
        self.port = port
    }

    public var url: URL? {
        URL(string: "https://\(host):\(port)")
    }

    /// Heuristic probe: are we plausibly on the tailnet right now?
    /// Phone-side check; watch-side calls into phone via `WatchPhoneBridge`.
    public func isReachable(timeout: TimeInterval = 2) async -> Bool {
        guard let url else { return false }
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "HEAD"
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode != nil
        } catch {
            return false
        }
    }
}
