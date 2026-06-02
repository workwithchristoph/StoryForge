import Foundation
import Combine

@MainActor
final class ProposalDetailViewModel: ObservableObject {
    @Published var comments: [StoryComment] = []

    private let story: Story
    private let chapter: Chapter
    private let proposal: Proposal
    private var cancellables = Set<AnyCancellable>()

    init(story: Story, chapter: Chapter, proposal: Proposal) {
        self.story = story
        self.chapter = chapter
        self.proposal = proposal
    }

    func load() async {
        guard let storyID = story.id, let chapterID = chapter.id, let proposalID = proposal.id else { return }
        FirestoreService.shared.observeComments(storyID: storyID, chapterID: chapterID, proposalID: proposalID)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] in self?.comments = $0 })
            .store(in: &cancellables)
    }

    func sendComment(_ text: String) async {
        guard let storyID = story.id, let chapterID = chapter.id, let proposalID = proposal.id,
              let user = AuthService.shared.currentUser else { return }
        let comment = StoryComment(
            text: text,
            authorUID: user.uid,
            authorDisplayName: user.displayName ?? "Anonymous",
            createdAt: Date()
        )
        try? await FirestoreService.shared.addComment(comment, storyID: storyID, chapterID: chapterID, proposalID: proposalID)
    }
}
