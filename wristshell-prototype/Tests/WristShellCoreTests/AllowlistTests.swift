import XCTest
@testable import WristShellCore

final class AllowlistTests: XCTestCase {
    func testAcceptsKnownTemplate() {
        let registry = AllowlistRegistry.default
        let plan = PlannedCommand(template: "restart_service", args: ["name": "nginx"])
        if case .accepted(let template) = registry.validate(plan) {
            XCTAssertEqual(template.id, "restart_service")
        } else {
            XCTFail("Expected acceptance")
        }
    }

    func testRejectsUnknownTemplate() {
        let registry = AllowlistRegistry.default
        let plan = PlannedCommand(template: "format_disk", args: [:])
        if case .rejected(let msg) = registry.validate(plan) {
            XCTAssertTrue(msg.contains("Unknown template"))
        } else {
            XCTFail("Expected rejection")
        }
    }

    func testRejectsBadEnumValue() {
        let registry = AllowlistRegistry.default
        let plan = PlannedCommand(template: "restart_service", args: ["name": "rm-rf"])
        if case .rejected(let msg) = registry.validate(plan) {
            XCTAssertTrue(msg.contains("not in allowed list"))
        } else {
            XCTFail("Expected rejection")
        }
    }

    func testRejectsNonIntForIntArg() {
        let registry = AllowlistRegistry.default
        let plan = PlannedCommand(template: "tail_log", args: ["service": "nginx", "lines": "; rm -rf /"])
        if case .rejected(let msg) = registry.validate(plan) {
            XCTAssertTrue(msg.contains("integer"))
        } else {
            XCTFail("Expected rejection — non-int arg")
        }
    }

    func testRejectsMissingRequiredArg() {
        let registry = AllowlistRegistry.default
        let plan = PlannedCommand(template: "tail_log", args: ["service": "nginx"])
        if case .rejected(let msg) = registry.validate(plan) {
            XCTAssertTrue(msg.contains("Missing arg"))
        } else {
            XCTFail("Expected rejection — missing arg")
        }
    }
}
