import XCTest
@testable import AskBandCore
import Core

final class AskSessionTests: XCTestCase {
    func testStateEnumEquality() {
        XCTAssertEqual(AskState.idle, AskState.idle)
        XCTAssertEqual(AskState.answering(partial: "abc"), AskState.answering(partial: "abc"))
        XCTAssertNotEqual(AskState.answering(partial: "a"), AskState.answering(partial: "b"))
    }
}
