import Foundation
import Combine

@MainActor
final class ProposalFeedViewModel: ObservableObject {
    @Published var proposals: [Proposal] = []
    @Published var chapter: Chapter

    private let story: Story
    private var cancellables = Set<AnyCancellable>()

    var isAuthor: Bool {
        story.authorUID == AuthService.shared.currentUser?.uid
    }

    init(story: Story, chapter: Chapter) {
        self.story = story
        self.chapter = chapter
    }

    func load() async {
        guard let storyID = story.id, let chapterID = chapter.id else { return }

        FirestoreService.shared.observeProposals(storyID: storyID, chapterID: chapterID)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] in self?.proposals = $0 })
            .store(in: &cancellables)

        // Keep the chapter's status / canon in sync when the author picks a winner.
        FirestoreService.shared.observeChapter(storyID: storyID, chapterID: chapterID)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] in self?.chapter = $0 })
            .store(in: &cancellables)
    }

    func vote(on proposal: Proposal) async {
        guard let storyID = story.id, let chapterID = chapter.id,
              let uid = AuthService.shared.currentUser?.uid else { return }
        try? await FirestoreService.shared.toggleVote(on: proposal, storyID: storyID, chapterID: chapterID, uid: uid)
    }

    /// Author locks in a proposal as the chapter's canon and closes voting.
    func chooseWinner(_ proposal: Proposal) async {
        guard let storyID = story.id, let chapterID = chapter.id else { return }
        try? await FirestoreService.shared.closeChapter(storyID: storyID, chapterID: chapterID, winningProposal: proposal)
    }
}
