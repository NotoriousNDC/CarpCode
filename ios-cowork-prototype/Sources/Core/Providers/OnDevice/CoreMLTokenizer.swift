import Foundation

// Minimal BPE tokenizer backed by vocab.json + merges.txt from the bundle.
// TODO: Replace with a full SentencePiece / tiktoken implementation for production.
public final class CoreMLTokenizer: Sendable {
    private let vocab: [String: Int]
    private let reverseVocab: [Int: String]
    private let merges: [(String, String)]

    public let eosTokenID: Int
    public let bosTokenID: Int

    public init(vocabURL: URL, mergesURL: URL) throws {
        let vocabData = try Data(contentsOf: vocabURL)
        guard let rawVocab = try JSONSerialization.jsonObject(with: vocabData) as? [String: Int] else {
            throw TokenizerError.invalidVocab
        }
        self.vocab = rawVocab
        self.reverseVocab = Dictionary(uniqueKeysWithValues: rawVocab.map { ($0.value, $0.key) })
        self.eosTokenID = rawVocab["<|endoftext|>"] ?? 50256
        self.bosTokenID = rawVocab["<|startoftext|>"] ?? self.eosTokenID

        let mergesText = try String(contentsOf: mergesURL, encoding: .utf8)
        self.merges = mergesText.components(separatedBy: "\n")
            .filter { !$0.hasPrefix("#") && !$0.isEmpty }
            .compactMap { line -> (String, String)? in
                let parts = line.components(separatedBy: " ")
                guard parts.count == 2 else { return nil }
                return (parts[0], parts[1])
            }
    }

    public func encode(_ text: String) -> [Int] {
        // Character-level fallback until full BPE merge pass is implemented
        // TODO: Implement full BPE merge loop using self.merges
        return text.unicodeScalars.compactMap { scalar -> Int? in
            let char = String(scalar)
            return vocab[char] ?? vocab["<|unk|>"] ?? 0
        }
    }

    public func decode(_ tokens: [Int]) -> String {
        tokens.compactMap { reverseVocab[$0] }.joined()
    }

    public enum TokenizerError: Error {
        case invalidVocab
        case invalidMerges
    }
}
