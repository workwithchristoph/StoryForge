import SwiftUI

struct WriteProposalView: View {
    let story: Story
    let chapter: Chapter
    @StateObject private var vm: WriteProposalViewModel
    @Environment(\.dismiss) private var dismiss

    init(story: Story, chapter: Chapter) {
        self.story = story
        self.chapter = chapter
        _vm = StateObject(wrappedValue: WriteProposalViewModel(story: story, chapter: chapter))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Your Proposal") {
                    TextEditor(text: $vm.proposalText)
                        .frame(minHeight: 200)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI Direction (optional)")
                            .font(.subheadline.bold())
                        TextField("e.g. 'Add a plot twist involving the lighthouse keeper'", text: $vm.aiInstruction, axis: .vertical)
                            .lineLimit(3, reservesSpace: true)

                        Button {
                            Task { await vm.generateAIProposal() }
                        } label: {
                            HStack {
                                if vm.isGenerating {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text(vm.isGenerating ? "Generating…" : "Generate with AI")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                        .disabled(vm.isGenerating)
                    }
                } header: {
                    Text("AI Co-Author")
                }

                if let error = vm.error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Write Proposal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        Task {
                            if await vm.submit() { dismiss() }
                        }
                    }
                    .disabled(vm.proposalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isSubmitting)
                }
            }
        }
    }
}
