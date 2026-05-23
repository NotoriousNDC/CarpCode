import SwiftUI
import Core

public struct ChatView: View {
    @Environment(AppSettings.self) private var settings
    @State private var viewModel: ChatViewModel?

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let vm = viewModel {
                    messageList(vm: vm)
                    if let error = vm.errorMessage {
                        errorBanner(message: error)
                    }
                    InputBar(
                        text: Binding(get: { vm.inputText }, set: { vm.inputText = $0 }),
                        isLoading: vm.isRunning,
                        onSend: { vm.send() },
                        onCancel: { vm.cancel() }
                    )
                }
            }
            .navigationTitle("CarpCowork")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let vm = viewModel, !vm.steps.isEmpty {
                        Button {
                            vm.showingTrace = true
                        } label: {
                            Image(systemName: "list.bullet.indent")
                        }
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if let vm = viewModel, !vm.messages.isEmpty {
                        Button("Clear") { vm.clearConversation() }
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { viewModel?.showingTrace ?? false },
                set: { viewModel?.showingTrace = $0 }
            )) {
                if let vm = viewModel {
                    AgentTraceView(steps: vm.steps)
                }
            }
        }
        .task {
            viewModel = ChatViewModel(settings: settings)
        }
        .onChange(of: settings.executionMode) { _, _ in
            viewModel = ChatViewModel(settings: settings)
        }
    }

    @ViewBuilder
    private func messageList(vm: ChatViewModel) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(vm.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    if vm.isRunning {
                        agentStatusBanner(steps: vm.steps)
                    }
                }
                .padding()
            }
            .onChange(of: vm.messages.count) { _, _ in
                if let last = vm.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    @ViewBuilder
    private func agentStatusBanner(steps: [AgentStep]) -> some View {
        if let running = steps.last(where: { $0.status == .running }) {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text(running.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.regularMaterial, in: Capsule())
        }
    }

    @ViewBuilder
    private func errorBanner(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.caption)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
    }
}
