import Foundation
import FirebaseFirestore
import Combine

final class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    private init() {}

    // MARK: - Stories

    func storiesCollection() -> CollectionReference {
        db.collection("stories")
    }

    func createStory(_ story: Story) async throws -> String {
        let ref = try storiesCollection().addDocument(from: story)
        return ref.documentID
    }

    func observeStories(forUID uid: String) -> AnyPublisher<[Story], Error> {
        let subject = PassthroughSubject<[Story], Error>()
        let listener = storiesCollection()
            .whereField("invitedUIDs", arrayContains: uid)
            .addSnapshotListener { snapshot, error in
                if let error { subject.send(completion: .failure(error)); return }
                let stories = snapshot?.documents.compactMap { try? $0.data(as: Story.self) } ?? []
                subject.send(stories)
            }
        return subject
            .handleEvents(receiveCancel: { listener.remove() })
            .eraseToAnyPublisher()
    }

    func observeMyStories(authorUID: String) -> AnyPublisher<[Story], Error> {
        let subject = PassthroughSubject<[Story], Error>()
        let listener = storiesCollection()
            .whereField("authorUID", isEqualTo: authorUID)
            .addSnapshotListener { snapshot, error in
                if let error { subject.send(completion: .failure(error)); return }
                let stories = snapshot?.documents.compactMap { try? $0.data(as: Story.self) } ?? []
                subject.send(stories)
            }
        return subject
            .handleEvents(receiveCancel: { listener.remove() })
            .eraseToAnyPublisher()
    }

    // MARK: - Chapters

    func chaptersCollection(storyID: String) -> CollectionReference {
        storiesCollection().document(storyID).collection("chapters")
    }

    func observeChapters(storyID: String) -> AnyPublisher<[Chapter], Error> {
        let subject = PassthroughSubject<[Chapter], Error>()
        let listener = chaptersCollection(storyID: storyID)
            .order(by: "number")
            .addSnapshotListener { snapshot, error in
                if let error { subject.send(completion: .failure(error)); return }
                let chapters = snapshot?.documents.compactMap { try? $0.data(as: Chapter.self) } ?? []
                subject.send(chapters)
            }
        return subject
            .handleEvents(receiveCancel: { listener.remove() })
            .eraseToAnyPublisher()
    }

    func createChapter(_ chapter: Chapter, storyID: String) async throws {
        try chaptersCollection(storyID: storyID).addDocument(from: chapter)
    }

    /// One-shot fetch of all chapters (used to assemble the story-so-far for the AI).
    func fetchChapters(storyID: String) async throws -> [Chapter] {
        let snapshot = try await chaptersCollection(storyID: storyID).order(by: "number").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Chapter.self) }
    }

    /// Live updates for a single chapter document (status / canon changes).
    func observeChapter(storyID: String, chapterID: String) -> AnyPublisher<Chapter, Error> {
        let subject = PassthroughSubject<Chapter, Error>()
        let listener = chaptersCollection(storyID: storyID).document(chapterID)
            .addSnapshotListener { snapshot, error in
                if let error { subject.send(completion: .failure(error)); return }
                if let chapter = try? snapshot?.data(as: Chapter.self) {
                    subject.send(chapter)
                }
            }
        return subject
            .handleEvents(receiveCancel: { listener.remove() })
            .eraseToAnyPublisher()
    }

    func closeChapter(storyID: String, chapterID: String, winningProposal: Proposal) async throws {
        let ref = chaptersCollection(storyID: storyID).document(chapterID)
        try await ref.updateData([
            "canonText": winningProposal.text,
            "status": ChapterStatus.closed.rawValue
        ])
    }

    // MARK: - Proposals

    func proposalsCollection(storyID: String, chapterID: String) -> CollectionReference {
        chaptersCollection(storyID: storyID).document(chapterID).collection("proposals")
    }

    func observeProposals(storyID: String, chapterID: String) -> AnyPublisher<[Proposal], Error> {
        let subject = PassthroughSubject<[Proposal], Error>()
        let listener = proposalsCollection(storyID: storyID, chapterID: chapterID)
            .order(by: "voteCount", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error { subject.send(completion: .failure(error)); return }
                let proposals = snapshot?.documents.compactMap { try? $0.data(as: Proposal.self) } ?? []
                subject.send(proposals)
            }
        return subject
            .handleEvents(receiveCancel: { listener.remove() })
            .eraseToAnyPublisher()
    }

    func submitProposal(_ proposal: Proposal, storyID: String, chapterID: String) async throws {
        try proposalsCollection(storyID: storyID, chapterID: chapterID).addDocument(from: proposal)
    }

    func toggleVote(on proposal: Proposal, storyID: String, chapterID: String, uid: String) async throws {
        guard let proposalID = proposal.id else { return }
        let ref = proposalsCollection(storyID: storyID, chapterID: chapterID).document(proposalID)
        if proposal.hasVoted(uid: uid) {
            try await ref.updateData([
                "voteCount": FieldValue.increment(Int64(-1)),
                "voterUIDs": FieldValue.arrayRemove([uid])
            ])
        } else {
            try await ref.updateData([
                "voteCount": FieldValue.increment(Int64(1)),
                "voterUIDs": FieldValue.arrayUnion([uid])
            ])
        }
    }

    // MARK: - Comments

    func commentsCollection(storyID: String, chapterID: String, proposalID: String) -> CollectionReference {
        proposalsCollection(storyID: storyID, chapterID: chapterID).document(proposalID).collection("comments")
    }

    func observeComments(storyID: String, chapterID: String, proposalID: String) -> AnyPublisher<[StoryComment], Error> {
        let subject = PassthroughSubject<[StoryComment], Error>()
        let listener = commentsCollection(storyID: storyID, chapterID: chapterID, proposalID: proposalID)
            .order(by: "createdAt")
            .addSnapshotListener { snapshot, error in
                if let error { subject.send(completion: .failure(error)); return }
                let comments = snapshot?.documents.compactMap { try? $0.data(as: StoryComment.self) } ?? []
                subject.send(comments)
            }
        return subject
            .handleEvents(receiveCancel: { listener.remove() })
            .eraseToAnyPublisher()
    }

    func addComment(_ comment: StoryComment, storyID: String, chapterID: String, proposalID: String) async throws {
        try commentsCollection(storyID: storyID, chapterID: chapterID, proposalID: proposalID).addDocument(from: comment)
    }

    // MARK: - Invites

    func inviteUser(email: String, storyID: String) async throws {
        // Look up user by email, then add their UID to invitedUIDs
        let snapshot = try await db.collection("users").whereField("email", isEqualTo: email).getDocuments()
        guard let inviteeUID = snapshot.documents.first?.documentID else {
            throw InviteError.userNotFound
        }
        try await storiesCollection().document(storyID).updateData([
            "invitedUIDs": FieldValue.arrayUnion([inviteeUID])
        ])
    }
}

enum InviteError: LocalizedError {
    case userNotFound
    var errorDescription: String? { "No user found with that email." }
}
