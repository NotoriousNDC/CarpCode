import Foundation

/// Codable wrapper for messages exchanged between the watch app and its
/// paired iPhone over `WCSession`. Each app defines its own payload type
/// and serializes it as JSON inside this envelope so the bridge code itself
/// stays generic.
public struct BridgeEnvelope: Codable, Sendable {
    public let kind: String       // app-defined message kind, e.g. "mom.cue"
    public let payload: Data      // JSON-encoded payload
    public let timestamp: Date

    public init(kind: String, payload: Data, timestamp: Date = Date()) {
        self.kind = kind
        self.payload = payload
        self.timestamp = timestamp
    }

    public static func make<T: Encodable>(kind: String, _ payload: T) throws -> BridgeEnvelope {
        let data = try JSONCoder.encoder.encode(payload)
        return BridgeEnvelope(kind: kind, payload: data)
    }

    public func decode<T: Decodable>(as type: T.Type) throws -> T {
        try JSONCoder.decoder.decode(type, from: payload)
    }
}
