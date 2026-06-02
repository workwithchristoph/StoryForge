import Foundation
import FirebaseFirestore

struct Story: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var title: String
    var synopsis: String
    var coverImageURL: String?
    var authorUID: String
    var invitedUIDs: [String]
    var createdAt: Date

    func isAuthor(uid: String) -> Bool {
        authorUID == uid
    }

    func isCollaborator(uid: String) -> Bool {
        invitedUIDs.contains(uid) || authorUID == uid
    }
}

struct Chapter: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var number: Int
    var title: String
    var canonText: String?
    var status: ChapterStatus
    var votingDeadline: Date?
    var createdAt: Date
}

enum ChapterStatus: String, Codable {
    case open       // accepting proposals
    case voting     // deadline set, voting in progress
    case closed     // winner chosen, canon text set
}

struct Proposal: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var text: String
    var authorUID: String
    var authorDisplayName: String
    var isAIGenerated: Bool
    var voteCount: Int
    var voterUIDs: [String]
    var createdAt: Date

    func hasVoted(uid: String) -> Bool {
        voterUIDs.contains(uid)
    }
}

struct StoryComment: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var text: String
    var authorUID: String
    var authorDisplayName: String
    var createdAt: Date
}
