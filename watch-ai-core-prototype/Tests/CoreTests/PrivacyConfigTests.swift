import XCTest
@testable import Core

final class PrivacyConfigTests: XCTestCase {
    func testStrictBlocksCloud() {
        let cfg = PrivacyConfig(mode: .strict)
        XCTAssertFalse(cfg.allowsCloudLLM)
        XCTAssertFalse(cfg.allowsCloudTranscription)
        XCTAssertTrue(cfg.requiresPerSessionConsent)
        XCTAssertFalse(cfg.allowsCalendarTitles)
        XCTAssertFalse(cfg.allowsPersistence)
    }

    func testBalancedAllowsCloud() {
        let cfg = PrivacyConfig(mode: .balanced)
        XCTAssertTrue(cfg.allowsCloudLLM)
        XCTAssertTrue(cfg.allowsCloudTranscription)
        XCTAssertFalse(cfg.requiresPerSessionConsent)
        XCTAssertFalse(cfg.allowsCalendarTitles)
    }

    func testConvenienceAllowsTitles() {
        let cfg = PrivacyConfig(mode: .convenience)
        XCTAssertTrue(cfg.allowsCalendarTitles)
        XCTAssertFalse(cfg.redactsLogs)
    }

    func testRawHealthSamplesNeverAllowed() {
        for mode in PrivacyMode.allCases {
            XCTAssertFalse(PrivacyConfig(mode: mode).allowsRawHealthSamples,
                           "Raw health samples must never leave the device, even in \(mode)")
        }
    }
}
