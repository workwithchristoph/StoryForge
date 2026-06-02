import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @State private var showCreateStory = false

    var body: some View {
        NavigationStack {
            List {
                if !vm.myStories.isEmpty {
                    Section("My Stories") {
                        ForEach(vm.myStories) { story in
                            NavigationLink(value: story) {
                                StoryRowView(story: story)
                            }
                        }
                    }
                }

                if !vm.invitedStories.isEmpty {
                    Section("Collaborating") {
                        ForEach(vm.invitedStories) { story in
                            NavigationLink(value: story) {
                                StoryRowView(story: story)
                            }
                        }
                    }
                }

                if vm.myStories.isEmpty && vm.invitedStories.isEmpty {
                    ContentUnavailableView(
                        "No Stories Yet",
                        systemImage: "book.closed",
                        description: Text("Create your first story or wait for an invite.")
                    )
                }
            }
            .navigationTitle("StoryForge")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showCreateStory = true } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button("Sign Out", role: .destructive) {
                        try? AuthService.shared.signOut()
                    }
                }
            }
            .navigationDestination(for: Story.self) { story in
                StoryDetailView(story: story)
            }
            .sheet(isPresented: $showCreateStory) {
                CreateStoryView()
            }
            .task { await vm.load() }
        }
    }
}

struct StoryRowView: View {
    let story: Story

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(story.title).font(.headline)
            Text(story.synopsis)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}
