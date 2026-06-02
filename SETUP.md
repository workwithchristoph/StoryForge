# StoryForge — Setup Guide

## 1. Create Xcode Project

- Open Xcode → New Project → App
- Product Name: `StoryForge`
- Interface: SwiftUI, Language: Swift
- Drag the contents of `StoryForge/` into the Xcode project

## 2. Add Firebase via Swift Package Manager

In Xcode → File → Add Package Dependencies:
```
https://github.com/firebase/firebase-ios-sdk
```
Add these targets:
- FirebaseAuth
- FirebaseFirestore
- FirebaseFirestoreSwift
- FirebaseStorage

## 3. Firebase Console Setup

1. Go to console.firebase.google.com → New Project → "StoryForge"
2. Add an iOS app (bundle ID from Xcode)
3. Download `GoogleService-Info.plist` → drag into Xcode project root
4. Enable **Authentication** → Sign-in Methods → Apple
5. Enable **Firestore** → Start in production mode

### Firestore Security Rules
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /stories/{storyId} {
      allow read: if request.auth.uid in resource.data.invitedUIDs;
      allow create: if request.auth != null;
      allow update: if request.auth.uid == resource.data.authorUID;

      match /chapters/{chapterId} {
        allow read: if request.auth.uid in get(/databases/$(database)/documents/stories/$(storyId)).data.invitedUIDs;
        allow write: if request.auth.uid in get(/databases/$(database)/documents/stories/$(storyId)).data.invitedUIDs;

        match /proposals/{proposalId} {
          allow read, write: if request.auth.uid in get(/databases/$(database)/documents/stories/$(storyId)).data.invitedUIDs;

          match /comments/{commentId} {
            allow read, write: if request.auth.uid in get(/databases/$(database)/documents/stories/$(storyId)).data.invitedUIDs;
          }
        }
      }
    }

    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
  }
}
```

## 4. Apple Sign-In Setup

1. In Xcode → Target → Signing & Capabilities → + Capability → Sign in with Apple
2. In Apple Developer portal → Identifiers → your App ID → enable Sign In with Apple
3. In Firebase Console → Auth → Apple → add your Service ID

## 5. Anthropic API Key (stored in a git-ignored xcconfig)

The key is **not** committed. It lives in `Secrets.xcconfig` (git-ignored) and is
injected into the build via a build setting that `Info.plist` references as
`$(ANTHROPIC_API_KEY)`.

To set it up:
1. Get your key at console.anthropic.com
2. Copy the template: `cp Secrets.xcconfig.example Secrets.xcconfig`
3. Open `Secrets.xcconfig` and set `ANTHROPIC_API_KEY = sk-ant-...`
4. Run `xcodegen generate` (the `configFiles` entry in `project.yml` wires it in)

At build time Xcode substitutes the value into the app's Info.plist, and
`AIService` reads it via `Bundle.main.object(forInfoDictionaryKey:)`.
`Secrets.xcconfig` and `GoogleService-Info.plist` are both in `.gitignore`.

## 6. User Registration Flow

When a user first signs in, write their profile to Firestore so invite-by-email works:

```swift
// Call this after successful Apple Sign-In
func registerUserProfile() async {
    guard let user = Auth.auth().currentUser else { return }
    try? await Firestore.firestore().collection("users").document(user.uid).setData([
        "email": user.email ?? "",
        "displayName": user.displayName ?? "Anonymous"
    ], merge: true)
}
```

## Project Structure

```
StoryForge/
├── App/
│   ├── StoryForgeApp.swift      # Entry point, Firebase init
│   └── RootView.swift           # Auth gate
├── Models/
│   └── Story.swift              # Story, Chapter, Proposal, Comment
├── Services/
│   ├── AuthService.swift        # Apple Sign-In + Firebase Auth
│   ├── FirestoreService.swift   # All Firestore reads/writes
│   └── AIService.swift          # Claude API integration
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── StoryDetailViewModel.swift
│   ├── ProposalFeedViewModel.swift
│   ├── WriteProposalViewModel.swift
│   └── ProposalDetailViewModel.swift
└── Views/
    ├── Auth/SignInView.swift
    ├── Home/{HomeView, CreateStoryView}.swift
    ├── Story/{StoryDetailView, AddChapterView, InviteView}.swift
    └── Proposal/{ProposalFeedView, WriteProposalView, ProposalDetailView}.swift
```
