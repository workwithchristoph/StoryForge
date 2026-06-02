import SwiftUI

struct ProposalFeedView: View {
    let story: Story
    let chapter: Chapter
    @StateObject private var vm: ProposalFeedViewModel
    @State private var showWrite = false

    init(story: Story, chapter: Chapter) {
        self.story = story
        self.chapter = chapter
        _vm = StateObject(wrappedValue: ProposalFeedViewModel(story: story, chapter: chapter))
    }

    var body: some View {
        List {
            if let canon = vm.chapter.canonText, !canon.isEmpty {
                Section("Chosen Story") {
                    Text(canon)
                        .font(.body)
                        .foregroundStyle(.primary)
                }
            }

            Section {
                ForEach(vm.proposals) { proposal in
                    NavigationLink(value: proposal) {
                        ProposalRowView(
                            proposal: proposal,
                            onVote: { Task { await vm.vote(on: proposal) } }
                        )
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if vm.isAuthor && vm.chapter.status != .closed {
                            Button {
                                Task { await vm.chooseWinner(proposal) }
                            } label: {
                                Label("Make Canon", systemImage: "crown.fill")
                            }
                            .tint(.green)
                        }
                    }
                }
            } header: {
                Text("Proposals (\(vm.proposals.count))")
            } footer: {
                if vm.isAuthor && vm.chapter.status != .closed && !vm.proposals.isEmpty {
                    Text("Swipe a proposal left and tap Make Canon to lock it in as this chapter.")
                }
            }
        }
        .navigationTitle("Chapter \(chapter.number)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if vm.chapter.status != .closed {
                ToolbarItem(placement: .primaryAction) {
                    Button { showWrite = true } label: {
                        Label("Propose", systemImage: "pencil.and.outline")
                    }
                }
            }
        }
        .navigationDestination(for: Proposal.self) { proposal in
            ProposalDetailView(story: story, chapter: chapter, proposal: proposal)
        }
        .sheet(isPresented: $showWrite) {
            WriteProposalView(story: story, chapter: chapter)
        }
        .task { await vm.load() }
    }
}

struct ProposalRowView: View {
    let proposal: Proposal
    let onVote: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if proposal.isAIGenerated {
                    Label("AI", systemImage: "sparkles")
                        .font(.caption.bold())
                        .foregroundStyle(.purple)
                }
                Text(proposal.authorDisplayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            Text(proposal.text)
                .font(.body)
                .lineLimit(4)

            Button(action: onVote) {
                let voted = proposal.hasVoted(uid: AuthService.shared.currentUser?.uid ?? "")
                Label("\(proposal.voteCount)", systemImage: voted ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .font(.subheadline)
                    .foregroundStyle(voted ? .blue : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
