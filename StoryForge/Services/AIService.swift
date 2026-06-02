import Foundation
import FirebaseFunctions

/// Talks to the `generateProposal` Cloud Function. The Anthropic API key lives
/// server-side as a Cloud secret — it is NEVER bundled in the app. Only
/// signed-in Firebase users can invoke the function.
final class AIService {
    static let shared = AIService()
    private init() {}

    // Must match the region the function is deployed to.
    private lazy var functions = Functions.functions(region: "europe-west3")

    func generateProposal(
        story: Story,
        canonSoFar: String,
        chapterTitle: String,
        userInstruction: String
    ) async throws -> String {
        let payload: [String: Any] = [
            "storyTitle": story.title,
            "synopsis": story.synopsis,
            "canonSoFar": canonSoFar,
            "chapterTitle": chapterTitle,
            "userInstruction": userInstruction
        ]

        do {
            let result = try await functions.httpsCallable("generateProposal").call(payload)
            guard
                let dict = result.data as? [String: Any],
                let text = dict["text"] as? String,
                !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else {
                throw AIError.apiError("The AI returned an empty response.")
            }
            return text
        } catch let error as NSError {
            // Cloud Functions surfaces the server-side message (e.g. low credit
            // balance) in localizedDescription.
            throw AIError.apiError(error.localizedDescription)
        }
    }
}

enum AIError: LocalizedError {
    case apiError(String)
    var errorDescription: String? {
        switch self {
        case .apiError(let message): return message
        }
    }
}
