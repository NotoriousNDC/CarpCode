import XCTest
@testable import Core

final class RedactorTests: XCTestCase {
    let redactor = Redactor()

    func testRedactsEmail() {
        let s = redactor.redact("User noahc@trcadvisory.com signed in")
        XCTAssertTrue(s.contains("[REDACTED_EMAIL]"))
        XCTAssertFalse(s.contains("noahc@"))
    }

    func testRedactsApiKey() {
        let s = redactor.redact("Authorization: Bearer sk-proj-AAAAAAAAAAAAAAAAAAAA")
        XCTAssertTrue(s.contains("[REDACTED_KEY]"))
    }

    func testRedactsPhone() {
        let s = redactor.redact("Call me at +1-555-123-4567 tomorrow")
        XCTAssertTrue(s.contains("[REDACTED_PHONE]"))
    }
}
