import SwiftUI

struct InviteView: View {
    let story: Story
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isSubmitting = false
    @State private var successMessage: String?
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Invite by Email") {
                    TextField("Email address", text: $email)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    Button("Send Invite") { Task { await invite() } }
                        .disabled(email.isEmpty || isSubmitting)
                }

                if let msg = successMessage {
                    Text(msg).foregroundStyle(.green).font(.caption)
                }
                if let err = error {
                    Text(err).foregroundStyle(.red).font(.caption)
                }
            }
            .navigationTitle("Invite Collaborator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private func invite() async {
        guard let storyID = story.id else { return }
        isSubmitting = true
        error = nil
        successMessage = nil
        do {
            try await FirestoreService.shared.inviteUser(email: email, storyID: storyID)
            successMessage = "\(email) has been invited."
            email = ""
        } catch {
            self.error = error.localizedDescription
        }
        isSubmitting = false
    }
}
