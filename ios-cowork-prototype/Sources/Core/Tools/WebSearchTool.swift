import Foundation

public struct WebSearchTool: AgentTool {
    public let name = "web_search"
    public let description = "Search the web for current information. Returns titles, URLs, and snippets."

    public init() {}

    public var parameterSchema: JSONSchemaObject {
        JSONSchemaObject(
            properties: [
                "query": JSONSchemaProperty(type: "string", description: "The search query."),
                "max_results": JSONSchemaProperty(type: "integer", description: "Maximum number of results to return (default 5)."),
            ],
            required: ["query"]
        )
    }

    public func execute(input: String) async throws -> ToolResult {
        let args = try parseInput(input)
        guard let query = args["query"] as? String else {
            return .error("Missing required parameter: query")
        }
        let maxResults = args["max_results"] as? Int ?? 5

        // DuckDuckGo instant-answer API — no key required
        var components = URLComponents(string: "https://api.duckduckgo.com/")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "no_redirect", value: "1"),
            URLQueryItem(name: "no_html", value: "1"),
            URLQueryItem(name: "skip_disambig", value: "1"),
        ]
        guard let url = components.url else {
            return .error("Could not build search URL")
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .error("Invalid response from search API")
        }

        var results: [[String: String]] = []

        // Abstract (instant answer)
        if let abstract = json["AbstractText"] as? String, !abstract.isEmpty,
           let abstractURL = json["AbstractURL"] as? String {
            results.append(["title": json["Heading"] as? String ?? "Abstract", "url": abstractURL, "snippet": abstract])
        }

        // Related topics
        if let topics = json["RelatedTopics"] as? [[String: Any]] {
            for topic in topics.prefix(maxResults - results.count) {
                if let text = topic["Text"] as? String,
                   let firstURL = topic["FirstURL"] as? String {
                    results.append(["title": text.components(separatedBy: " - ").first ?? text, "url": firstURL, "snippet": text])
                }
            }
        }

        if results.isEmpty {
            return ToolResult(content: "No results found for: \(query)")
        }
        let jsonString = (try? JSONCoder.string(from: results)) ?? "[]"
        return ToolResult(content: jsonString, metadata: ["query": query, "count": "\(results.count)"])
    }
}
