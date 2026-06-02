import Foundation
import Combine

@MainActor
final class WriteProposalViewModel: ObservableObject {
    @Published var proposalText = ""
    @Published var aiInstruction = ""
    @Published var isGenerating = false
    @Published var isSubmitting = false
    @Published var error: String?
    @Published var wasAIGenerated = false

    private let story: Story
    private let chapter: Chapter

    init(story: Story, chapter: Chapter) {
        self.story = story
        self.chapter = chapter
    }

    func generateAIProposal() async {
        guard let storyID = story.id else { return }
        isGenerating = true
        error = nil

        // Build canon text from closed chapters
        let canonSoFar = await buildCanonText(storyID: storyID)

        do {
            let text = try await AIService.shared.generateProposal(
                story: story,
                canonSoFar: canonSoFar,
                chapterTitle: chapter.title,
                userInstruction: aiInstruction
            )
            proposalText = text
            wasAIGenerated = true
        } catch {
            self.error = error.localizedDescription
        }
        isGenerating = false
    }

    func submit() async -> Bool {
        guard let storyID = story.id, let chapterID = chapter.id,
              let user = AuthService.shared.currentUser else { return false }
        isSubmitting = true
        let proposal = Proposal(
            text: proposalText,
            authorUID: user.uid,
            authorDisplayName: user.displayName ?? "Anonymous",
            isAIGenerated: wasAIGenerated,
            voteCount: 0,
            voterUIDs: [],
            createdAt: Date()
        )
        do {
            try await FirestoreService.shared.submitProposal(proposal, storyID: storyID, chapterID: chapterID)
            isSubmitting = false
            return true
        } catch {
            self.error = error.localizedDescription
            isSubmitting = false
            return false
        }
    }

    /// Assembles the canon text of all chapters that already have a chosen winner,
    /// so the AI continues from the real story so far.
    private func buildCanonText(storyID: String) async -> String {
        do {
            let chapters = try await FirestoreService.shared.fetchChapters(storyID: storyID)
            return chapters
                .filter { ($0.canonText?.isEmpty == false) && $0.number < chapter.number }
                .sorted { $0.number < $1.number }
                .map { "Chapter \($0.number): \($0.title)\n\($0.canonText ?? "")" }
                .joined(separator: "\n\n")
        } catch {
            return ""
        }
    }
}
