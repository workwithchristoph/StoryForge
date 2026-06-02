import SwiftUI

struct CreateStoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var synopsis = ""
    @State private var isSubmitting = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Story Details") {
                    TextField("Title", text: $title)
                    TextField("Synopsis", text: $synopsis, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                }
                if let error {
                    Text(error).foregroundStyle(.red).font(.caption)
                }
            }
            .navigationTitle("New Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { Task { await create() } }
                        .disabled(title.isEmpty || synopsis.isEmpty || isSubmitting)
                }
            }
        }
    }

    private func create() async {
        guard let uid = AuthService.shared.currentUser?.uid else { return }
        isSubmitting = true
        let story = Story(
            title: title,
            synopsis: synopsis,
            authorUID: uid,
            invitedUIDs: [uid],
            createdAt: Date()
        )
        do {
            _ = try await FirestoreService.shared.createStory(story)
            dismiss()
        } catch {
            self.error = error.localizedDescription
            isSubmitting = false
        }
    }
}
