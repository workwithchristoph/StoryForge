import Foundation

final class AIService {
    static let shared = AIService()
    private init() {}

    // Set your Anthropic API key in Info.plist as "ANTHROPIC_API_KEY"
    private var apiKey: String {
        Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String ?? ""
    }

    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    // MARK: - Generate story continuation

    func generateProposal(
        story: Story,
        canonSoFar: String,
        chapterTitle: String,
        userInstruction: String
    ) async throws -> String {
        let systemPrompt = """
        You are a creative co-author collaborating on a story titled "\(story.title)".
        Synopsis: \(story.synopsis)

        Your role is to propose the next chapter continuation based on the story so far.
        Write in a compelling narrative style. Keep proposals between 200-400 words.
        Match the tone and voice already established in the story.
        """

        let userMessage = """
        Story so far:
        \(canonSoFar.isEmpty ? "(Story is just beginning)" : canonSoFar)

        Chapter to continue: \(chapterTitle)

        Additional direction from collaborator: \(userInstruction.isEmpty ? "Surprise us!" : userInstruction)

        Write the next chapter proposal:
        """

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": 600,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userMessage]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AIError.apiError("No response from the server.")
        }
        guard http.statusCode == 200 else {
            // Surface the real Anthropic error message (e.g. low credit balance,
            // invalid key, rate limit) instead of a generic failure.
            if let apiErr = try? JSONDecoder().decode(AnthropicError.self, from: data) {
                throw AIError.apiError(apiErr.error.message)
            }
            throw AIError.apiError("Request failed (HTTP \(http.statusCode)).")
        }

        let decoded = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        return decoded.content.first?.text ?? ""
    }
}

// MARK: - Response models

private struct AnthropicResponse: Decodable {
    let content: [ContentBlock]
}

private struct ContentBlock: Decodable {
    let text: String
}

private struct AnthropicError: Decodable {
    struct Detail: Decodable { let message: String }
    let error: Detail
}

enum AIError: LocalizedError {
    case apiError(String)
    var errorDescription: String? {
        switch self {
        case .apiError(let message): return message
        }
    }
}
