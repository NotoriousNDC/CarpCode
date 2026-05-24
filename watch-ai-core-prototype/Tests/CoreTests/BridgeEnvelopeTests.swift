import XCTest
@testable import Core

final class BridgeEnvelopeTests: XCTestCase {
    struct Payload: Codable, Equatable { let kind: String; let value: Int }

    func testRoundTrip() throws {
        let payload = Payload(kind: "habit.water", value: 1)
        let env = try BridgeEnvelope.make(kind: "mom.cue", payload)
        XCTAssertEqual(env.kind, "mom.cue")
        let decoded = try env.decode(as: Payload.self)
        XCTAssertEqual(decoded, payload)
    }

    func testEnvelopeIsCodable() throws {
        let payload = Payload(kind: "habit.walk", value: 2)
        let env = try BridgeEnvelope.make(kind: "mom.cue", payload)
        let data = try JSONCoder.encoder.encode(env)
        let decoded = try JSONCoder.decoder.decode(BridgeEnvelope.self, from: data)
        XCTAssertEqual(decoded.kind, "mom.cue")
        let inner = try decoded.decode(as: Payload.self)
        XCTAssertEqual(inner, payload)
    }
}
