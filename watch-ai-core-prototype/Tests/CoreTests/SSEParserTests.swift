import XCTest
@testable import Core

final class SSEParserTests: XCTestCase {
    func testSingleEvent() {
        var parser = SSEParser()
        let events = parser.feed("data: hello\n\n")
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].data, "hello")
    }

    func testEventWithType() {
        var parser = SSEParser()
        let events = parser.feed("event: ping\ndata: 1\n\n")
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].event, "ping")
        XCTAssertEqual(events[0].data, "1")
    }

    func testPartialChunks() {
        var parser = SSEParser()
        XCTAssertEqual(parser.feed("data: a").count, 0)
        XCTAssertEqual(parser.feed("bc\n").count, 0)
        let events = parser.feed("\n")
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].data, "abc")
    }

    func testMultilineData() {
        var parser = SSEParser()
        let events = parser.feed("data: line1\ndata: line2\n\n")
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].data, "line1\nline2")
    }
}
