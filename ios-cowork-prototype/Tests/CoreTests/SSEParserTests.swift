import XCTest
@testable import Core

final class SSEParserTests: XCTestCase {
    func testParsesSimpleTextEvent() {
        var parser = SSEParser()
        let events = parser.feed("data: hello\n\n")
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].data, "hello")
        XCTAssertNil(events[0].event)
    }

    func testParsesNamedEvent() {
        var parser = SSEParser()
        let events = parser.feed("event: content_block_delta\ndata: {\"type\":\"text\"}\n\n")
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].event, "content_block_delta")
    }

    func testHandlesChunkedDelivery() {
        var parser = SSEParser()
        var events = parser.feed("data: par")
        XCTAssertTrue(events.isEmpty, "Partial event should not be emitted")
        events += parser.feed("tial\n\n")
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].data, "partial")
    }

    func testFiltersDataDone() {
        var parser = SSEParser()
        // [DONE] lines should not be emitted as events (they signal stream end)
        let events = parser.feed("data: [DONE]\n\n")
        XCTAssertTrue(events.isEmpty || !events[0].isDataLine)
    }

    func testMultipleEvents() {
        var parser = SSEParser()
        let raw = "data: first\n\ndata: second\n\n"
        let events = parser.feed(raw)
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events[0].data, "first")
        XCTAssertEqual(events[1].data, "second")
    }
}
