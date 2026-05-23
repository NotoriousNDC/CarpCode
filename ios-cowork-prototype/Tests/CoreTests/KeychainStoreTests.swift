import XCTest
@testable import Core

// Note: Keychain tests require a signed app target; they will skip on Linux/CI without entitlements.
final class KeychainStoreTests: XCTestCase {
    let store = KeychainStore()
    let testService = "carpcowork.test.keychain"

    override func tearDown() async throws {
        try? store.delete(service: testService)
    }

    func testWriteAndRead() throws {
        #if os(Linux)
        throw XCTSkip("Keychain not available on Linux")
        #endif
        let value = "sk-test-\(UUID().uuidString)"
        try store.write(service: testService, value: value)
        let retrieved = try store.read(service: testService)
        XCTAssertEqual(retrieved, value)
    }

    func testReadMissingKeyThrows() {
        #if os(Linux)
        return
        #endif
        XCTAssertThrowsError(try store.read(service: "no-such-service-\(UUID().uuidString)")) { error in
            if case KeychainError.notFound = error { return }
            XCTFail("Expected KeychainError.notFound, got \(error)")
        }
    }

    func testHasKey() throws {
        #if os(Linux)
        return
        #endif
        XCTAssertFalse(store.hasKey(service: testService))
        try store.write(service: testService, value: "test")
        XCTAssertTrue(store.hasKey(service: testService))
    }

    func testOverwriteExistingKey() throws {
        #if os(Linux)
        return
        #endif
        try store.write(service: testService, value: "original")
        try store.write(service: testService, value: "updated")
        let retrieved = try store.read(service: testService)
        XCTAssertEqual(retrieved, "updated")
    }
}
