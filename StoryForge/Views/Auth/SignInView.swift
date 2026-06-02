import SwiftUI

struct SignInView: View {
    @EnvironmentObject var auth: AuthService
    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    enum Mode { case signIn, signUp, resetPassword }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo
            VStack(spacing: 8) {
                Image(systemName: "book.pages")
                    .font(.system(size: 60))
                    .foregroundStyle(.primary)
                Text("StoryForge")
                    .font(.largeTitle.bold())
                Text("Collaborate. Vote. Create.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 48)

            // Form
            VStack(spacing: 16) {
                if mode == .signUp {
                    TextField("Your name", text: $displayName)
                        .textContentType(.name)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if mode != .resetPassword {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    SecureField("Password", text: $password)
                        .textContentType(mode == .signUp ? .newPassword : .password)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await submit() }
                } label: {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(primaryButtonLabel)
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(isLoading || !isFormValid)
            }
            .padding(.horizontal, 32)

            // Mode switchers
            VStack(spacing: 12) {
                if mode == .signIn {
                    Button("Don't have an account? Sign Up") { withAnimation { mode = .signUp } }
                    Button("Forgot password?") { withAnimation { mode = .resetPassword } }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Button("Back to Sign In") { withAnimation { mode = .signIn } }
                }
            }
            .font(.subheadline)
            .padding(.top, 20)

            Spacer()
        }
    }

    private var primaryButtonLabel: String {
        switch mode {
        case .signIn: return "Sign In"
        case .signUp: return "Create Account"
        case .resetPassword: return "Send Reset Email"
        }
    }

    private var isFormValid: Bool {
        switch mode {
        case .signIn: return !email.isEmpty && !password.isEmpty
        case .signUp: return !email.isEmpty && !password.isEmpty && !displayName.isEmpty
        case .resetPassword: return !email.isEmpty
        }
    }

    private func submit() async {
        isLoading = true
        errorMessage = nil
        do {
            switch mode {
            case .signIn:
                try await auth.signIn(email: email, password: password)
            case .signUp:
                try await auth.signUp(email: email, password: password, displayName: displayName)
            case .resetPassword:
                try await auth.resetPassword(email: email)
                errorMessage = "Reset email sent — check your inbox."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
