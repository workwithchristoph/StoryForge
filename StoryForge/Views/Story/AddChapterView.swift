import SwiftUI

struct AddChapterView: View {
    let story: Story
    let nextNumber: Int
    @Environment(\.dismiss) private var dismiss
    @State private var chapterTitle = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Chapter Title", text: $chapterTitle)
            }
            .navigationTitle("New Chapter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { Task { await add() } }
                        .disabled(chapterTitle.isEmpty || isSubmitting)
                }
            }
        }
    }

    private func add() async {
        guard let storyID = story.id else { return }
        isSubmitting = true
        let chapter = Chapter(
            number: nextNumber,
            title: chapterTitle,
            status: .open,
            createdAt: Date()
        )
        try? await FirestoreService.shared.createChapter(chapter, storyID: storyID)
        dismiss()
    }
}
