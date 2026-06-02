import Foundation
import Firebase
import FirebaseAuth

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: User?
    @Published var isSignedIn = false

    private var stateListener: AuthStateDidChangeListenerHandle?

    private init() {
        stateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isSignedIn = user != nil
        }
    }

    // MARK: - Email / Password

    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func signUp(email: String, password: String, displayName: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()

        // Store user profile in Firestore for invite lookups
        try await registerUserProfile(user: result.user, displayName: displayName, email: email)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    // MARK: - Firestore profile

    private func registerUserProfile(user: User, displayName: String, email: String) async throws {
        let db = Firestore.firestore()
        try await db.collection("users").document(user.uid).setData([
            "email": email,
            "displayName": displayName
        ], merge: true)
    }
}
