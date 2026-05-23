import XCTest
@testable import Core

final class ToolRegistryTests: XCTestCase {
    func testDispatchUnknownToolReturnsError() async {
        let registry = ToolRegistry(tools: [])
        let call = ToolCall(id: "test-1", name: "nonexistent_tool", input: "{}")
        let result = await registry.dispatch(call: call)
        XCTAssertTrue(result.isError)
        XCTAssertTrue(result.content.contains("nonexistent_tool"))
    }

    func testDispatchKnownTool() async {
        let registry = ToolRegistry(tools: [WebSearchTool()])
        let call = ToolCall(id: "test-2", name: "web_search", input: "{\"query\": \"test\"}")
        // Just check it doesn't crash and returns something
        let result = await registry.dispatch(call: call)
        XCTAssertFalse(result.content.isEmpty)
    }

    func testDefinitionsListsAllTools() {
        let tools: [any AgentTool] = [FileReadTool(), FileWriteTool(), WebSearchTool()]
        let registry = ToolRegistry(tools: tools)
        XCTAssertEqual(registry.definitions.count, 3)
    }
}
