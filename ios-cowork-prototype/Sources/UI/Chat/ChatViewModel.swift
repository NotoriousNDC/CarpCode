import SwiftUI
import Core

@Observable
@MainActor
public final class ChatViewModel {
    public var messages: [Message] = []
    public var steps: [AgentStep] = []
    public var isRunning: Bool = false
    public var inputText: String = ""
    public var showingTrace: Bool = false
    public var errorMessage: String?

    private var agentLoop: AgentLoop?
    private let registry: ProviderRegistry
    private var settings: AppSettings

    public init(settings: AppSettings, registry: ProviderRegistry = ProviderRegistry()) {
        self.settings = settings
        self.registry = registry
    }

    public func send() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let task = inputText
        inputText = ""
        isRunning = true
        errorMessage = nil
        steps = []

        messages.append(Message.user(task))
        let assistantID = UUID()
        messages.append(Message(id: assistantID, role: .assistant, content: .text("")))

        Task {
            do {
                let provider = try registry.provider(for: settings)
                let tools = ToolRegistry.defaultTools()
                let loop = AgentLoop(provider: provider, tools: tools, settings: settings)
                self.agentLoop = loop

                var assistantText = ""
                for try await step in await loop.run(task: task) {
                    steps.append(step)
                    // Accumulate final response text
                    if case .responding = step.phase, step.status == .completed, let detail = step.detail {
                        assistantText = detail
                    }
                    // Update running step in-place
                    if let idx = steps.firstIndex(where: { $0.id == step.id }) {
                        steps[idx] = step
                    }
                }
                // Update the placeholder assistant message
                if let idx = messages.firstIndex(where: { $0.id == assistantID }) {
                    messages[idx] = Message(id: assistantID, role: .assistant, content: .text(assistantText))
                }
            } catch let providerError as ProviderError {
                errorMessage = providerError.errorDescription
                messages.removeLast()  // remove empty assistant placeholder
            } catch {
                errorMessage = error.localizedDescription
                messages.removeLast()
            }
            isRunning = false
            agentLoop = nil
        }
    }

    public func cancel() {
        Task { await agentLoop?.cancel() }
        isRunning = false
    }

    public func clearConversation() {
        messages = []
        steps = []
        errorMessage = nil
    }
}
