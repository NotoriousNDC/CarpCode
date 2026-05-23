import XCTest
@testable import Core
import MockProviders

final class AgentLoopTests: XCTestCase {
    func testRunEmitsSteps() async throws {
        let mock = MockModelProvider(
            supportsTools: false,
            responses: [
                // Plan response
                "{\"subtasks\": [\"Write hello world\"], \"reasoning\": \"Simple task\"}",
                // Act response (no tool calls)
                "Here is hello world: print('Hello, World!')",
                // Reflect response
                "{\"done\": true, \"summary\": \"Done.\"}",
                // Final response
                "The task is complete.",
            ]
        )
        let tools = ToolRegistry(tools: [])
        var settings = AppSettings()
        settings.agentConfig.maxSteps = 5
        let loop = AgentLoop(provider: mock, tools: tools, settings: settings)

        var collectedSteps: [AgentStep] = []
        for try await step in await loop.run(task: "Write hello world") {
            collectedSteps.append(step)
        }

        XCTAssertFalse(collectedSteps.isEmpty, "Should emit at least one step")
        XCTAssertTrue(collectedSteps.contains { if case .planning = $0.phase { return true }; return false },
                      "Should contain a planning step")
        XCTAssertTrue(collectedSteps.contains { if case .responding = $0.phase { return true }; return false },
                      "Should contain a responding step")
    }

    func testCancelStopsLoop() async throws {
        let mock = MockModelProvider(
            supportsTools: false,
            responses: Array(repeating: "{\"subtasks\": [\"step\"], \"reasoning\": \"\"}", count: 30)
        )
        let tools = ToolRegistry(tools: [])
        let loop = AgentLoop(provider: mock, tools: tools)

        var stepCount = 0
        let task = Task {
            for try await _ in await loop.run(task: "Long task") {
                stepCount += 1
                if stepCount == 2 { await loop.cancel() }
            }
        }
        try await task.value
        XCTAssertLessThan(stepCount, AgentLoop.maxIterations, "Cancel should stop the loop early")
    }
}
