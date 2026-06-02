import Foundation
import Combine

@MainActor
final class StoryDetailViewModel: ObservableObject {
    @Published var chapters: [Chapter] = []

    private let story: Story
    private var cancellables = Set<AnyCancellable>()

    init(story: Story) {
        self.story = story
    }

    func load() async {
        guard let storyID = story.id else { return }
        FirestoreService.shared.observeChapters(storyID: storyID)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] in self?.chapters = $0 })
            .store(in: &cancellables)
    }
}
