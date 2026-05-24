import XCTest
@testable import WhisperNoteCore
import Core

final class NoteProcessorTests: XCTestCase {
    func testStrictModeReturnsRawTranscript() async throws {
        let processor = NoteProcessor(
            model: NeverProvider(),
            privacy: PrivacyConfig(mode: .strict)
        )
        let transcript = Transcript(text: "hello world", durationSeconds: 2)
        let note = try await processor.process(transcript: transcript)
        XCTAssertEqual(note.transcript, "hello world")
        XCTAssertNil(note.cleanedBody)
        XCTAssertTrue(note.actionItems.isEmpty)
    }

    func testParsesCleanJSON() throws {
        let processor = NoteProcessor(
            model: NeverProvider(),
            privacy: PrivacyConfig(mode: .balanced)
        )
        let parsed = try processor.parseResponse(#"""
            {"title": "Groceries", "body": "Buy bread and milk", "actions": ["Buy bread", "Buy milk"]}
            """#)
        XCTAssertEqual(parsed.title, "Groceries")
        XCTAssertEqual(parsed.actions.count, 2)
    }

    func testParsesFencedJSON() throws {
        let processor = NoteProcessor(
            model: NeverProvider(),
            privacy: PrivacyConfig(mode: .balanced)
        )
        let parsed = try processor.parseResponse("```json\n{\"title\":\"X\",\"body\":\"y\",\"actions\":[]}\n```")
        XCTAssertEqual(parsed.title, "X")
    }
}

/// Stub provider that should never actually be called in these tests.
struct NeverProvider: ModelProvider {
    let id = "test/never"
    let displayName = "Never"
    let supportsTools = false

    func complete(messages: [Message], tools: [ToolDefinition], config: InferenceConfig) async throws -> AsyncThrowingStream<CompletionChunk, Error> {
        XCTFail("Should not call the model in this test")
        return AsyncThrowingStream { _ in }
    }
}
