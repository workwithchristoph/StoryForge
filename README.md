<div align="center">
  <img src="StoryForge/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="120" alt="StoryForge icon"/>
  <h1>StoryForge</h1>
  <p><strong>Collaborate. Vote. Create.</strong></p>
  <p>An iOS app for invite-only collaborative storytelling, with an AI co-author.</p>
</div>

---

## What it is

StoryForge turns writing a story into a group game. A story grows **chapter by
chapter**, and instead of one person writing it all, invited collaborators
**propose** what happens next and the group **votes**. The winning proposal
becomes the chapter's canon, then the next chapter opens. Any member can also
summon an **AI co-author** (Claude) to draft a proposal that competes in the
same vote.

## Features

- 🔐 **Invite-only stories** — only people you invite can read and contribute
- ✍️ **Proposals & voting** — members submit competing continuations; the group votes
- 👑 **Author picks canon** — the story author locks in the winning proposal per chapter
- 🤖 **AI co-author** — generate a proposal with Claude, using the story so far as context
- 💬 **Threaded discussion** on every proposal
- ⚡ **Real-time sync** — votes, proposals, and comments update live via Firestore

## Architecture

| Layer | Tech |
|---|---|
| UI | SwiftUI (MVVM) |
| Auth | Firebase Auth (email/password) |
| Database | Cloud Firestore (real-time listeners) |
| AI backend | Firebase **Cloud Function** → Anthropic Claude API |
| Project gen | [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`project.yml`) |

```
stories/{id}
  └─ chapters/{id}
       └─ proposals/{id}
            └─ comments/{id}
```

### 🔒 The AI key never ships in the app

The Anthropic API key is **not** bundled in the client. The app calls an
authenticated Firebase Cloud Function (`functions/generateProposal`), which
reads the key from **Google Secret Manager** server-side and proxies the
request to Claude. Only signed-in users can invoke it. This is what makes the
app safe to distribute.

## Project structure

```
StoryForge/
├── App/            # entry point, auth gate
├── Models/         # Story, Chapter, Proposal, Comment
├── Services/       # AuthService, FirestoreService, AIService
├── ViewModels/     # MVVM view models
└── Views/          # Auth / Home / Story / Proposal screens
functions/          # Cloud Function (AI proposal proxy)
firestore.rules     # Security rules
project.yml         # XcodeGen project spec
```

## Setup

See **[SETUP.md](SETUP.md)** for full steps. In short:

1. `brew install xcodegen` then `xcodegen generate`
2. Add your own `GoogleService-Info.plist` from the Firebase console
3. Enable Firebase Auth (Email/Password) + Firestore
4. Deploy the function: `firebase deploy --only firestore,functions`
   (set the key first: `firebase functions:secrets:set ANTHROPIC_API_KEY`)
5. Open `StoryForge.xcodeproj` and run

> `GoogleService-Info.plist` and any local secrets are git-ignored.

## Sharing it (TestFlight)

1. Enroll in the [Apple Developer Program](https://developer.apple.com/programs/) ($99/yr)
2. In Xcode: set your team → **Product → Archive** → upload to App Store Connect
3. Add the build to **TestFlight** and invite testers by email or public link

## Status

MVP — the full create → propose → vote → canon → discuss loop works and syncs
in real time. AI generation requires Anthropic API credits.

---

<div align="center"><sub>Built with SwiftUI + Firebase + Claude.</sub></div>
