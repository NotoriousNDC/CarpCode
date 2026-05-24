import Foundation
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

public enum BridgeReachability: Sendable {
    case unknown
    case unreachable
    case reachable
}

/// Wraps `WCSession` for the prototypes. Apps register a handler closure for
/// each `kind` they care about; the bridge dispatches incoming envelopes.
///
/// Both sides of the pair (watch + phone) use the same type. The bridge picks
/// up the appropriate role at activation time.
public final class WatchPhoneBridge: NSObject, @unchecked Sendable {
    public typealias Handler = @Sendable (BridgeEnvelope) -> Void

    private var handlers: [String: Handler] = [:]
    private let lock = NSLock()
    public private(set) var reachability: BridgeReachability = .unknown

    public override init() {
        super.init()
    }

    public func activate() {
#if canImport(WatchConnectivity)
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
#endif
    }

    public func register(kind: String, handler: @escaping Handler) {
        lock.lock(); defer { lock.unlock() }
        handlers[kind] = handler
    }

    /// Fire-and-forget message when reachable; falls back to `transferUserInfo`
    /// for queued delivery when not.
    public func send(_ envelope: BridgeEnvelope) {
#if canImport(WatchConnectivity)
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        let dict: [String: Any] = [
            "kind": envelope.kind,
            "payload": envelope.payload,
            "timestamp": envelope.timestamp.timeIntervalSince1970,
        ]
        if session.isReachable {
            session.sendMessage(dict, replyHandler: nil) { _ in
                session.transferUserInfo(dict)
            }
        } else {
            session.transferUserInfo(dict)
        }
#endif
    }

    private func dispatch(_ message: [String: Any]) {
        guard let kind = message["kind"] as? String,
              let payload = message["payload"] as? Data else { return }
        let env = BridgeEnvelope(
            kind: kind,
            payload: payload,
            timestamp: Date(timeIntervalSince1970: (message["timestamp"] as? TimeInterval) ?? 0)
        )
        lock.lock(); let handler = handlers[kind]; lock.unlock()
        handler?(env)
    }
}

#if canImport(WatchConnectivity)
extension WatchPhoneBridge: WCSessionDelegate {
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        reachability = session.isReachable ? .reachable : .unreachable
    }

    public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        dispatch(message)
    }

    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        dispatch(userInfo)
    }

    public func sessionReachabilityDidChange(_ session: WCSession) {
        reachability = session.isReachable ? .reachable : .unreachable
    }

#if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {}
    public func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
#endif
}
#endif
