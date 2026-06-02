import SwiftUI

struct StoryDetailView: View {
    let story: Story
    @StateObject private var vm: StoryDetailViewModel
    @State private var showInvite = false
    @State private var showAddChapter = false

    init(story: Story) {
        self.story = story
        _vm = StateObject(wrappedValue: StoryDetailViewModel(story: story))
    }

    var body: some View {
        List {
            ForEach(vm.chapters) { chapter in
                NavigationLink(value: chapter) {
                    ChapterRowView(chapter: chapter)
                }
            }

            if story.isAuthor(uid: AuthService.shared.currentUser?.uid ?? "") {
                Button {
                    showAddChapter = true
                } label: {
                    Label("Add Chapter", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle(story.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if story.isAuthor(uid: AuthService.shared.currentUser?.uid ?? "") {
                ToolbarItem(placement: .primaryAction) {
                    Button { showInvite = true } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
        }
        .navigationDestination(for: Chapter.self) { chapter in
            ProposalFeedView(story: story, chapter: chapter)
        }
        .sheet(isPresented: $showInvite) {
            InviteView(story: story)
        }
        .sheet(isPresented: $showAddChapter) {
            AddChapterView(story: story, nextNumber: (vm.chapters.map(\.number).max() ?? 0) + 1)
        }
        .task { await vm.load() }
    }
}

struct ChapterRowView: View {
    let chapter: Chapter

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Chapter \(chapter.number): \(chapter.title)")
                    .font(.headline)
                Spacer()
                StatusBadge(status: chapter.status)
            }
            if let canon = chapter.canonText {
                Text(canon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: ChapterStatus

    var body: some View {
        Text(label)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var label: String {
        switch status {
        case .open: return "Open"
        case .voting: return "Voting"
        case .closed: return "Done"
        }
    }

    private var color: Color {
        switch status {
        case .open: return .blue
        case .voting: return .orange
        case .closed: return .green
        }
    }
}
