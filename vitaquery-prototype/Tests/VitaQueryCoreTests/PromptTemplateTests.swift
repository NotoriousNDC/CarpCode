import XCTest
@testable import VitaQueryCore

final class PromptTemplateTests: XCTestCase {
    func testSystemPromptForbidsDiagnosis() {
        let p = VitaPromptTemplate.systemPrompt
        XCTAssertTrue(p.contains("NOT a doctor"))
        XCTAssertTrue(p.contains("clinician"))
        XCTAssertTrue(p.contains("Do not diagnose"))
    }

    func testUserPromptIncludesSummary() throws {
        let summary = HealthSummary(
            windowDays: 7,
            hrv: VitalStat(mean: 50, stddev: 5, weekDelta: -0.1, latestPercentile: 0.25)
        )
        let prompt = try VitaPromptTemplate.userPrompt(question: "How's my HRV?", summary: summary)
        XCTAssertTrue(prompt.contains("How's my HRV?"))
        XCTAssertTrue(prompt.contains("50"))
        XCTAssertTrue(prompt.contains("7"))
    }

    func testHeuristicReturnsTextWithoutLLM() {
        let summary = HealthSummary(
            windowDays: 7,
            resting: VitalStat(mean: 60, stddev: 4, weekDelta: 0.05, latestPercentile: 0.6),
            hrv: VitalStat(mean: 50, stddev: 5, weekDelta: -0.1, latestPercentile: 0.25),
            sleep: SleepStat(averageHoursPerNight: 6.8, stddevHours: 0.7, weekDelta: -0.05, shortNights: 2)
        )
        let out = VitaQueryEngine.heuristicAnswer(question: "How am I doing?", summary: summary)
        XCTAssertTrue(out.contains("Strict mode"))
        XCTAssertTrue(out.contains("HRV"))
        XCTAssertTrue(out.contains("Sleep"))
    }
}
