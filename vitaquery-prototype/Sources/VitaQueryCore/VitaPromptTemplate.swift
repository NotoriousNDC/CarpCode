import Foundation
import Core

public enum VitaPromptTemplate {
    /// System prompt enforcing the non-clinical posture. Kept as a separate
    /// constant so reviewers (and Apple's HealthKit reviewers) can audit it.
    public static let systemPrompt: String = """
    You are an athletic-performance assistant interpreting summarized HealthKit data.

    HARD RULES — DO NOT VIOLATE:
    1. You are NOT a doctor. Do not diagnose. Do not prescribe.
    2. For ANY pattern that could plausibly indicate a medical issue
       (arrhythmia hints, sustained fever, fainting risk, chest pain, etc.),
       your reply must include a clear sentence recommending they consult a
       clinician. Do not soften this with "but probably it's fine."
    3. If the question is a flat-out medical question ("do I have X?"), refuse
       and direct them to a clinician.
    4. Speak in plain language. Avoid medical jargon unless the user used it first.
    5. Use the data provided in the JSON. Do not invent metrics that aren't there.
       If the JSON lacks the relevant field, say so.

    Style:
    - Lead with the answer in one sentence.
    - Follow with the key data point that supports it.
    - Keep total length under 120 words.
    """

    public static func userPrompt(question: String, summary: HealthSummary) throws -> String {
        let summaryJSON = try JSONCoder.encoder.encode(summary)
        let summaryString = String(data: summaryJSON, encoding: .utf8) ?? "{}"
        return """
        Question: \(question)

        Summary (last \(summary.windowDays) days, aggregated — raw samples never leave the device):
        \(summaryString)
        """
    }
}

public struct VitaQueryEngine: Sendable {
    public let model: ModelProvider
    public let privacy: PrivacyConfig

    public init(model: ModelProvider, privacy: PrivacyConfig) {
        self.model = model
        self.privacy = privacy
    }

    public func ask(_ question: String, summary: HealthSummary) async throws -> String {
        guard privacy.allowsCloudLLM else {
            return Self.heuristicAnswer(question: question, summary: summary)
        }
        let stream = try await model.complete(
            messages: [.user(VitaPromptTemplate.userPrompt(question: question, summary: summary))],
            tools: [],
            config: InferenceConfig(
                temperature: 0.3,
                maxTokens: 400,
                systemPrompt: VitaPromptTemplate.systemPrompt
            )
        )
        return try await stream.joinedText()
    }

    /// Strict-mode template fallback — deterministic facts, no judgment.
    public static func heuristicAnswer(question: String, summary: HealthSummary) -> String {
        var lines: [String] = ["Strict mode is on, so I can only quote stats — no AI interpretation."]
        if let hrv = summary.hrv {
            lines.append(String(format: "HRV: %.1f ms mean, week-over-week %+.0f%%, latest in %.0fth percentile.",
                                hrv.mean, hrv.weekDelta * 100, hrv.latestPercentile * 100))
        }
        if let resting = summary.resting {
            lines.append(String(format: "Resting HR: %.0f bpm mean, week-over-week %+.0f%%.",
                                resting.mean, resting.weekDelta * 100))
        }
        if let sleep = summary.sleep {
            lines.append(String(format: "Sleep: %.1f h/night avg, %d short nights (< 6.5 h).",
                                sleep.averageHoursPerNight, sleep.shortNights))
        }
        return lines.joined(separator: "\n")
    }
}
