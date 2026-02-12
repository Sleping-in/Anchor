# Anchor

AI-powered emotional support app for iOS with real-time voice conversations, local-first privacy, and crisis-safe UX.

## Status
- Platform: iOS 17+
- Language/UI: Swift 5.9+, SwiftUI
- Persistence: SwiftData (local-only)
- Current phase: MVP + V1.1/V1.2 feature set
- StoreKit billing: Deferred (UI and flags exist, App Store billing integration pending)

## What Is Implemented
- Real-time voice sessions with Gemini Live (`GeminiLiveClient`) and streaming audio I/O (`LiveAudioIO`)
- On-device local transcription support (`LocalTranscriber`)
- Session save flow with fallback summary + async structured notes (`SessionSummarizer`)
- Session history, detail views, sharing cards, and therapist-ready PDF export
- Crisis keyword detection and emergency resources flow
- Mood check-in, mood triggers, session focus, and conversation personas
- Breathing exercise flows and Anchor Moment interactions
- Smart reminder scheduling (learned preferred check-in time)
- Widgets + Live Activity support
- Optional app lock flags and local privacy-first data export/delete

## Core Architecture
- Pattern: MVVM-style SwiftUI state management
- Models: SwiftData `@Model` types (`Session`, `UserSettings`, `UserProfile`, etc.)
- Services layer: AI, audio, crisis, export, notifications, routing, summaries
- No cloud sync for user records (`cloudKitDatabase: .none`)
- API-provider abstraction via `AIServiceProtocol`

## Project Layout
```text
Anchor/
├── Anchor.xcodeproj/
├── Anchor/
│   ├── AnchorApp.swift
│   ├── ContentView.swift
│   ├── Models/
│   ├── Views/
│   ├── Services/
│   ├── DesignSystem/
│   ├── Assets.xcassets/
│   └── Resources/
├── AnchorTests/
├── AnchorUITests/
├── AnchorWidgets/
├── Shared/
├── PRD.md
└── IMPLEMENTATION_SUMMARY.md
```

## Build
```bash
# Open in Xcode
open Anchor/Anchor.xcodeproj

# Build (CLI)
xcodebuild -project Anchor/Anchor.xcodeproj -scheme Anchor -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' build
```

If that simulator is unavailable, check supported destinations:
```bash
xcodebuild -project Anchor/Anchor.xcodeproj -scheme Anchor -showdestinations
```

## Test
```bash
xcodebuild test -project Anchor/Anchor.xcodeproj -scheme Anchor -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2'
```

## Configuration
- Gemini key is required for live + summary AI paths.
- Key lookup order is handled in `KeychainHelper`.
- Common env vars:
  - `GEMINI_API_KEY`
  - `GEMINI_LIVE_MODEL` (optional override)
  - `GEMINI_SUMMARY_MODEL` (optional override)

## Privacy & Safety
- Local-first storage in SwiftData
- Sensitive values in Keychain
- Crisis language scanning and emergency resource access in-app
- Not a therapy replacement; emergency escalation messaging is included in UX

## Known Gaps
- StoreKit 2 production integration (deferred)
- Full localization and accessibility audit still in progress

## Docs
- Product requirements: `PRD.md`
- Implementation status: `IMPLEMENTATION_SUMMARY.md`
