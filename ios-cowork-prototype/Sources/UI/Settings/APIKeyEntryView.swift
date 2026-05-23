import SwiftUI
import Core

public struct APIKeyEntryView: View {
    let providerID: String
    let providerName: String

    @State private var keyText: String = ""
    @State private var isSaved = false
    @State private var errorMessage: String?
    private let keychain = KeychainStore()

    public init(providerID: String, providerName: String) {
        self.providerID = providerID
        self.providerName = providerName
    }

    public var body: some View {
        Form {
            Section {
                SecureField("Paste API key here", text: $keyText)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } header: {
                Text("\(providerName) API Key")
            } footer: {
                Text("Keys are stored in the iOS Keychain and never leave your device.")
                    .font(.caption)
            }

            Section {
                Button("Save Key") {
                    save()
                }
                .disabled(keyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if keychain.hasKey(service: providerID) {
                    Button("Remove Key", role: .destructive) {
                        remove()
                    }
                }
            }

            if isSaved {
                Label("Key saved to Keychain", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
            }
            if let error = errorMessage {
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
        .navigationTitle(providerName)
        .onAppear {
            // Show masked existing key hint
            if keychain.hasKey(service: providerID) {
                keyText = ""  // don't pre-fill for security
            }
        }
    }

    private func save() {
        let trimmed = keyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            try keychain.write(service: providerID, value: trimmed)
            isSaved = true
            errorMessage = nil
            keyText = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func remove() {
        do {
            try keychain.delete(service: providerID)
            isSaved = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
