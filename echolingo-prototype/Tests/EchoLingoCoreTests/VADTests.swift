import XCTest
@testable import EchoLingoCore

final class VADTests: XCTestCase {
    func testDetectsSpeechStart() {
        let vad = VoiceActivityDetector(activeThreshold: 0.2, silenceThreshold: 0.05, minSilenceMs: 500)
        XCTAssertNil(vad.feed(meter: 0.0, deltaMs: 100))
        XCTAssertEqual(vad.feed(meter: 0.5, deltaMs: 100), .speechStart)
        XCTAssertNil(vad.feed(meter: 0.4, deltaMs: 100))
    }

    func testDetectsSpeechEndAfterSilence() {
        let vad = VoiceActivityDetector(activeThreshold: 0.2, silenceThreshold: 0.05, minSilenceMs: 500)
        XCTAssertEqual(vad.feed(meter: 0.5, deltaMs: 100), .speechStart)
        for _ in 0..<4 {
            XCTAssertNil(vad.feed(meter: 0.0, deltaMs: 100))
        }
        XCTAssertEqual(vad.feed(meter: 0.0, deltaMs: 200), .speechEnd)
    }

    func testIntermittentNoiseDoesNotEndSpeech() {
        let vad = VoiceActivityDetector(activeThreshold: 0.2, silenceThreshold: 0.05, minSilenceMs: 500)
        XCTAssertEqual(vad.feed(meter: 0.5, deltaMs: 100), .speechStart)
        XCTAssertNil(vad.feed(meter: 0.0, deltaMs: 200))
        XCTAssertNil(vad.feed(meter: 0.3, deltaMs: 100))   // resets silence streak
        XCTAssertNil(vad.feed(meter: 0.0, deltaMs: 200))
        XCTAssertNil(vad.feed(meter: 0.0, deltaMs: 100))   // total < 500ms again
    }
}
