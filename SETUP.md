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

## 5. Anthropic API Key (stored server-side, never in the app)

The AI co-author runs through a Firebase Cloud Function (`functions/index.js`,
`generateProposal`). The Anthropic key is stored as a Cloud secret (Google Secret
Manager) and is **never bundled in the app**, so the app is safe to distribute.

To set it up:
1. Get your key at console.anthropic.com (add credits under Plans & Billing)
2. Upgrade the Firebase project to the **Blaze** plan — Cloud Functions require it
   (the free tier covers typical usage):
   https://console.firebase.google.com/project/_/usage/details
3. Store the key as a secret:
   `firebase functions:secrets:set ANTHROPIC_API_KEY`
4. Deploy the function:
   `firebase deploy --only functions`

The iOS app calls the function via the FirebaseFunctions SDK (`AIService.swift`);
only signed-in users can invoke it, and no API key ships in the app binary.

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
