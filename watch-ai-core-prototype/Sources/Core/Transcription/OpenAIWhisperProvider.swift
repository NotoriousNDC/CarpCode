import Foundation

/// Uploads an audio file to OpenAI's `/v1/audio/transcriptions` endpoint.
/// Multipart-form, returns `verbose_json` so we can surface segments.
public final class OpenAIWhisperProvider: TranscriptionProvider, @unchecked Sendable {
    public let id = "openai/whisper-1"
    public let isOnDevice = false

    private let apiKey: String
    private let baseURL: URL
    private let http: HTTPClient
    private let model: String

    public init(
        apiKey: String,
        model: String = "whisper-1",
        baseURL: URL = URL(string: "https://api.openai.com/v1")!,
        http: HTTPClient = HTTPClient()
    ) {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
        self.http = http
    }

    public func transcribe(audioURL: URL, options: TranscriptionOptions) async throws -> Transcript {
        var request = URLRequest(url: baseURL.appendingPathComponent("audio/transcriptions"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = try buildMultipartBody(boundary: boundary, audioURL: audioURL, options: options)

        let data = try await http.data(for: request, cloudPurpose: .transcription)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ProviderError.invalidResponse("non-JSON whisper response")
        }
        guard let text = json["text"] as? String else {
            throw ProviderError.invalidResponse("whisper response missing 'text'")
        }
        let language = json["language"] as? String
        let duration = json["duration"] as? Double ?? 0
        var segments: [Transcript.Segment] = []
        if let arr = json["segments"] as? [[String: Any]] {
            segments = arr.compactMap { seg in
                guard let start = seg["start"] as? Double,
                      let end = seg["end"] as? Double,
                      let txt = seg["text"] as? String else { return nil }
                return Transcript.Segment(start: start, end: end, text: txt)
            }
        }
        return Transcript(text: text, language: language, segments: segments, durationSeconds: duration)
    }

    private func buildMultipartBody(boundary: String, audioURL: URL, options: TranscriptionOptions) throws -> Data {
        var body = Data()
        func append(_ s: String) { body.append(s.data(using: .utf8)!) }
        let crlf = "\r\n"

        append("--\(boundary)\(crlf)")
        append("Content-Disposition: form-data; name=\"model\"\(crlf)\(crlf)")
        append("\(model)\(crlf)")

        if let lang = options.languageHint {
            append("--\(boundary)\(crlf)")
            append("Content-Disposition: form-data; name=\"language\"\(crlf)\(crlf)")
            append("\(lang)\(crlf)")
        }
        if let prompt = options.prompt {
            append("--\(boundary)\(crlf)")
            append("Content-Disposition: form-data; name=\"prompt\"\(crlf)\(crlf)")
            append("\(prompt)\(crlf)")
        }
        append("--\(boundary)\(crlf)")
        append("Content-Disposition: form-data; name=\"response_format\"\(crlf)\(crlf)")
        append("\(options.withTimestamps ? "verbose_json" : "json")\(crlf)")

        let filename = audioURL.lastPathComponent
        let audioData = try Data(contentsOf: audioURL)
        append("--\(boundary)\(crlf)")
        append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\(crlf)")
        append("Content-Type: audio/m4a\(crlf)\(crlf)")
        body.append(audioData)
        append(crlf)
        append("--\(boundary)--\(crlf)")
        return body
    }
}
