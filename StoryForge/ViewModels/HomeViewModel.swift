import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var myStories: [Story] = []
    @Published var invitedStories: [Story] = []

    private var cancellables = Set<AnyCancellable>()
    private let db = FirestoreService.shared

    func load() async {
        guard let uid = AuthService.shared.currentUser?.uid else { return }

        db.observeMyStories(authorUID: uid)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] in self?.myStories = $0 })
            .store(in: &cancellables)

        db.observeStories(forUID: uid)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] stories in
                // Exclude stories the user authored — those already show under "My Stories".
                self?.invitedStories = stories.filter { $0.authorUID != uid }
            })
            .store(in: &cancellables)
    }
}
