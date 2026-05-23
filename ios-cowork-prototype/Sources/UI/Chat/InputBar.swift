import SwiftUI

public struct InputBar: View {
    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void
    let onCancel: () -> Void

    @FocusState private var isFocused: Bool

    public init(text: Binding<String>, isLoading: Bool, onSend: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self._text = text
        self.isLoading = isLoading
        self.onSend = onSend
        self.onCancel = onCancel
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Ask anything or give a task…", text: $text, axis: .vertical)
                .lineLimit(1...6)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .focused($isFocused)
                .disabled(isLoading)
                .onSubmit {
                    if !isLoading { onSend() }
                }

            Group {
                if isLoading {
                    Button(action: onCancel) {
                        Image(systemName: "stop.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.red)
                    }
                } else {
                    Button(action: onSend) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial)
    }
}
