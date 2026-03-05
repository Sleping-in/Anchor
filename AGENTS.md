# AGENTS.md - Anchor iOS Project

This document provides essential context for AI coding agents working on the Anchor project.

---

## Project Overview

**Anchor** is an iOS mobile application providing AI-powered emotional support through real-time voice conversations. It is designed for adults experiencing mild-to-moderate mental health challenges, offering immediate, private, and accessible emotional support.

- **Platform**: iOS 17.0+
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData (local-only, encrypted)
- **Architecture Pattern**: MVVM-style state management with SwiftUI
- **Bundle ID**: Sensh.Anchor (inferred from URL scheme)

---

## Project Structure

```
Anchor/
├── Anchor.xcodeproj/           # Xcode project (no Package.swift - vanilla project)
├── Anchor/                     # Main app target
│   ├── AnchorApp.swift         # App entry point (@main)
│   ├── ContentView.swift       # Root content wrapper
│   ├── Info.plist              # App configuration (URL schemes, background modes, permissions)
│   ├── PrivacyInfo.xcprivacy   # Privacy manifest (no tracking, minimal API usage)
│   ├── Anchor.entitlements     # App capabilities (NSFileProtectionComplete)
│   ├── InfoPlist.strings       # Localized permission descriptions
│   ├── Localizable.xcstrings   # String Catalog (English + Arabic localization)
│   ├── Models/                 # SwiftData @Model classes
│   │   ├── Session.swift           # Conversation session model
│   │   ├── UserSettings.swift      # User preferences & subscription state
│   │   ├── UserProfile.swift       # Learned user profile for personalization
│   │   ├── CrisisResources.swift   # Emergency helpline data
│   │   ├── ConversationMessage.swift # Individual message in conversation
│   │   ├── FlaggedResponse.swift   # For flagging problematic AI responses
│   │   ├── BookmarkedInsight.swift # Saved insights from sessions
│   │   ├── SessionFocus.swift      # Session focus categories
│   │   └── ConversationPersona.swift # AI persona options
│   ├── Views/                  # SwiftUI views (~11,000 lines total)
│   │   ├── HomeView.swift          # Main dashboard
│   │   ├── ConversationView.swift  # Voice conversation UI
│   │   ├── OnboardingView.swift    # First-launch onboarding flow
│   │   ├── SafetyDisclaimerView.swift # Crisis/safety disclaimers
│   │   ├── HistoryView.swift       # Session history & sharing
│   │   ├── InsightsView.swift      # Analytics & patterns dashboard
│   │   ├── SettingsView.swift      # App settings
│   │   ├── SubscriptionView.swift  # Subscription management UI
│   │   ├── EmergencyResourcesView.swift # Crisis help screen
│   │   ├── BreathingExerciseView.swift # Guided breathing exercises
│   │   ├── MoodCheckInView.swift   # Post-session mood tracking
│   │   ├── MoodTriggersView.swift  # Trigger tagging
│   │   ├── MoodChartView.swift     # Mood visualization
│   │   ├── AnchorMomentView.swift  # Daily micro-interactions
│   │   ├── HelpFAQView.swift       # Help documentation
│   │   ├── SupportViews.swift      # Reusable support UI components
│   │   └── SplashView.swift        # Launch splash screen
│   ├── Services/               # Business logic & integrations (~200K+ lines)
│   │   ├── AIServiceProtocol.swift      # AI provider abstraction
│   │   ├── GeminiLiveClient.swift       # Gemini Live API WebSocket client
│   │   ├── LiveAudioIO.swift            # Audio capture/playback (AVAudioEngine)
│   │   ├── LocalTranscriber.swift       # On-device speech recognition
│   │   ├── AnchorSystemPrompt.swift     # AI system prompts with personalization
│   │   ├── CrisisKeywordScanner.swift   # Crisis detection (22 keywords)
│   │   ├── CrisisResourceStore.swift    # Emergency resources management
│   │   ├── ThroughLineAPIClient.swift   # Regional helpline API client
│   │   ├── SessionSummarizer.swift      # AI-powered session notes generation
│   │   ├── SessionPDFExporter.swift     # Therapist-ready PDF export
│   │   ├── ProfileBuilder.swift         # User profile learning from sessions
│   │   ├── PatternAnalyzer.swift        # Pattern detection in user data
│   │   ├── DataExporter.swift           # JSON data export
│   │   ├── NotificationManager.swift    # Local notifications & smart reminders
│   │   ├── NotificationDelegate.swift   # Notification handling
│   │   ├── AmbientSoundPlayer.swift     # Background ambient audio
│   │   ├── VoiceStressTracker.swift     # Voice analysis for stress detection
│   │   ├── VoiceStressMLScorer.swift    # CoreML-based stress scoring
│   │   ├── WeeklySummaryBuilder.swift   # Weekly insights generation
│   │   ├── CheckInTimeEstimator.swift   # Smart notification timing
│   │   ├── DeepLinkRouter.swift         # URL scheme handling (anchor://)
│   │   ├── NetworkMonitor.swift         # Connectivity tracking
│   │   ├── KeychainHelper.swift         # Secure API key storage
│   │   ├── PersistenceError.swift       # Storage error types
│   │   ├── WidgetDataSync.swift         # Widget data sharing
│   │   └── SessionLiveActivityManager.swift # Live Activity coordination
│   ├── DesignSystem/           # UI components & theme
│   │   ├── AnchorTheme.swift   # Colors, typography, motion constants
│   │   ├── FontRegistrar.swift # Custom font registration (Playfair Display, Source Sans 3)
│   │   ├── VoiceStateController.swift   # Orb state bridge
│   │   ├── FlowLayout.swift    # Custom layout container
│   │   ├── BreathingPatterns.swift # Breathing exercise definitions
│   │   └── MoodEmoji.swift     # Mood emoji definitions
│   ├── Intents/                # App Intents for Shortcuts/Siri
│   │   ├── StartSessionIntent.swift
│   │   ├── StartBreathingIntent.swift
│   │   ├── LogMoodIntent.swift
│   │   ├── DeepLinkBridge.swift
│   │   └── AnchorShortcutsProvider.swift
│   ├── Assets.xcassets/        # Images, app icons, color sets
│   └── Resources/              # Additional resources
├── AnchorTests/                # Unit tests (Swift Testing framework)
│   ├── AnchorTests.swift       # Main test suite (72 tests)
│   ├── ProfileBuilderTests.swift
│   ├── SessionSummarizerTests.swift
│   ├── DataExporterTests.swift
│   ├── SessionPDFExporterTests.swift
│   └── ShareCardRenderTests.swift
├── AnchorUITests/              # UI tests (XCUITest)
│   ├── AnchorUITests.swift     # 9 UI tests
│   └── AnchorUITestsLaunchTests.swift
├── AnchorWidgets/              # iOS Home Screen widgets extension
│   ├── AnchorWidgetsBundle.swift
│   ├── MoodStreakWidget.swift
│   ├── WeeklyMoodTrendWidget.swift
│   ├── QuickCheckInWidget.swift
│   ├── BreathingShortcutWidget.swift
│   ├── LockScreenWidget.swift
│   ├── AnchorSessionLiveActivity.swift
│   ├── WidgetDataSync.swift
│   ├── WidgetShared.swift
│   ├── Assets.xcassets/
│   └── Info.plist
├── Shared/                     # Shared code between app and widgets
│   └── AnchorSessionActivityAttributes.swift
├── Source_Sans_3/              # Custom font files
├── Playfair_Display/           # Custom font files
├── PRD.md                      # Product Requirements Document
├── IMPLEMENTATION_SUMMARY.md   # Implementation status
├── README.md                   # Project documentation
└── AGENTS.md                   # This file
```

---

## Build and Run

### Prerequisites
- **Xcode**: 15.0 or later
- **iOS**: 17.0 or later (deployment target)
- **macOS**: Sonoma (14.0) or later

### No External Dependencies
This project uses **vanilla Swift/SwiftUI** with no external package managers (no Swift Package Manager, CocoaPods, or Carthage dependencies). All functionality is built using Apple's native frameworks.

### Build Commands

```bash
# Open project in Xcode
open Anchor/Anchor.xcodeproj

# Build from command line
xcodebuild -project Anchor/Anchor.xcodeproj -scheme Anchor -destination 'platform=iOS Simulator,name=iPhone 17' build

# Check available simulators
xcodebuild -project Anchor/Anchor.xcodeproj -scheme Anchor -showdestinations
```

### Xcode Build
1. Select target device/simulator
2. Press `Cmd + R` to build and run
3. Press `Cmd + U` to run tests

---

## Testing

### Test Structure
- **Unit Tests**: `AnchorTests/` - Uses Swift Testing framework (`@Test` attribute)
- **UI Tests**: `AnchorUITests/` - Uses XCUITest framework

### Running Tests
```bash
# In Xcode: Cmd + U
# Command line:
xcodebuild test -project Anchor/Anchor.xcodeproj -scheme Anchor -destination 'platform=iOS Simulator,name=iPhone 17'
```

### Test Coverage (81 tests total)
- **Session Model Tests**: Creation, duration formatting, default values, mood tracking
- **UserSettings Tests**: Defaults, trial/subscription logic, free tier usage, streak tracking
- **CrisisKeywordScanner Tests**: All 22 crisis keywords detection, case insensitivity, safe text handling
- **UserProfile Tests**: Empty profile handling, prompt context generation, content limits
- **FlaggedResponse Tests**: Creation, defaults, unique IDs
- **AnchorSystemPrompt Tests**: Base prompt content, personalization injection, context generation
- **DataExporter Tests**: JSON export, nil handling, profile inclusion, file location

### Adding Tests
- Use `@Test` attribute from Swift Testing framework
- Use `#expect()` for assertions (not XCTest's XCTAssert)
- Mark async tests with `async throws`
- Import `@testable import Anchor` to access internal members
- Test both success and failure paths

---

## Architecture

### MVVM Pattern
- **Models**: SwiftData `@Model` classes for persistence (Session, UserSettings, UserProfile, FlaggedResponse)
- **Views**: SwiftUI views using `@State`, `@Binding`, `@Query`, and `@Environment`
- **ViewModels**: No explicit ViewModel classes; state managed via `@StateObject` and `@ObservedObject` in Views

### Key Architectural Principles
1. **Privacy-First**: All data stored locally with `cloudKitDatabase: .none`. No cloud sync.
2. **File Protection**: SwiftData store uses `NSFileProtectionComplete` for encryption at rest
3. **Provider Abstraction**: `AIServiceProtocol` allows swapping AI providers (Gemini, OpenAI, local)
4. **Crisis Safety**: All user-facing text scanned through `CrisisKeywordScanner`

### Data Flow
```
User Input → View → Service Layer → AI/Local Processing
                ↓
           SwiftData (local encrypted storage)
```

### ModelContainer Setup (from AnchorApp.swift)
```swift
let schema = Schema([Session.self, UserSettings.self, UserProfile.self, FlaggedResponse.self])
let modelConfiguration = ModelConfiguration(
    schema: schema,
    url: URL.applicationSupportDirectory.appending(path: "Anchor.store"),
    allowsSave: true,
    cloudKitDatabase: .none  // No cloud sync
)
```

---

## Key Technologies & Frameworks

| Purpose | Framework |
|---------|-----------|
| UI | SwiftUI (iOS 17+) |
| Data Persistence | SwiftData |
| AI Integration | Google Gemini Live API (WebSocket) |
| Voice Processing | AVAudioEngine, LiveAudioIO |
| Speech Recognition | Speech framework (on-device) |
| Audio | AVFoundation, CoreHaptics |
| Security | Keychain (API keys), CryptoKit |
| Notifications | UserNotifications |
| Widgets | WidgetKit |
| Live Activities | ActivityKit |
| App Intents | AppIntents framework |
| Localization | String Catalog (.xcstrings) |

---

## Code Style Guidelines

### Swift Conventions
- Use **camelCase** for variables, functions; **PascalCase** for types
- Mark model classes with `@Model` for SwiftData
- Use `final class` for models (SwiftData requirement)
- Prefer `let` over `var` where possible
- Use explicit self only when required

### Documentation Style
- File headers include:
```swift
//
//  Filename.swift
//  Anchor
//
//  [Description of purpose]
//
```
- Public APIs documented with `///` doc comments
- Complex logic includes inline comments

### SwiftUI Patterns
- Views are structs conforming to `View`
- State managed via `@State`, `@Binding`, `@StateObject`, `@Query`
- Environment objects: `VoiceStateController`, `NetworkMonitor`, `DeepLinkRouter`
- Use `.task` for async initialization

### Error Handling
- Services use `PersistenceError` enum for storage errors
- AI service errors propagate via `AIServiceEvent.error(String)`
- Guard statements preferred for early exits

---

## Configuration

### API Keys (Required for AI Features)
- **Gemini API Key**: Set via `KeychainHelper.setGeminiAPIKey("...")` or environment
- Key lookup order: Keychain → Environment variable → Info.plist
- No keys committed to repository

### Environment Variables
```bash
# Primary AI (Gemini API / AI Studio)
GEMINI_API_KEY                    # Required for voice conversations
GEMINI_LIVE_MODEL                 # Optional override (default: gemini-2.0-flash-live-001)
GEMINI_SUMMARY_MODEL              # Optional override (default: gemini-2.5-flash)
GEMINI_SUMMARY_PROMPT_VERSION     # v1 or v2 (default: v2)

# Fallback AI (Vertex AI - used when Gemini API rate limited)
VERTEX_AI_PROJECT_ID              # GCP project ID (e.g., "my-project-123")
VERTEX_AI_LOCATION                # Default: "us-central1"
VERTEX_AI_MODEL                   # Optional override (default: gemini-2.5-flash)
VERTEX_AI_KEY_PATH                # Path to service account JSON key file
```

### Vertex AI Fallback Setup
When Gemini API (AI Studio) hits rate limits (429 errors), the app automatically falls back to Vertex AI:

1. **Create GCP Project** with Vertex AI API enabled
2. **Create Service Account** with "Vertex AI User" role
3. **Download JSON key** and add to app bundle or Documents
4. **Set environment variables** or add to Info.plist:
   ```xml
   <key>VERTEX_AI_PROJECT_ID</key>
   <string>your-project-id</string>
   <key>VERTEX_AI_LOCATION</key>
   <string>us-central1</string>
   <key>VERTEX_AI_KEY_PATH</key>
   <string>$(DOCUMENTS_DIR)/service-account-key.json</string>
   ```

**Note**: For production apps, use Google Sign-In SDK or Firebase Auth instead of service account keys for better security.

### Capabilities (from Info.plist)
- **Microphone access**: `NSMicrophoneUsageDescription`
- **Speech recognition**: `NSSpeechRecognitionUsageDescription`
- **Face ID**: `NSFaceIDUsageDescription` (for app lock)
- **Background modes**: audio, fetch, processing
- **Live Activities**: `NSSupportsLiveActivities`
- **URL scheme**: `anchor://` for deep links
- **App Intents**: Supported for Siri Shortcuts

---

## Security Considerations

### Data Privacy
- **No cloud storage**: Conversations never leave device
- **Encryption at rest**: SwiftData with `NSFileProtectionComplete`
- **API keys**: Stored in Keychain, never in code
- **Privacy manifest**: `PrivacyInfo.xcprivacy` declares no tracking
- **Accessed APIs**: UserDefaults (CA92.1), File timestamp (C617.1)

### Crisis Safety
- `CrisisKeywordScanner` detects crisis language (22 keywords)
- Automatic emergency resources presentation
- 988 Suicide & Crisis Lifeline integration
- Regional helpline data via ThroughLine API

### User Consent
- Safety disclaimer required on first launch
- Explicit acknowledgment of "not therapy" disclaimer
- Age verification (18+) enforced

---

## Localization

- **Primary Language**: English (en)
- **Secondary Language**: Arabic (ar) - partial coverage
- **Format**: String Catalog (`Localizable.xcstrings`)
- **Usage**: `String(localized: "key")` in code
- **Status**: Many strings still literal; ongoing localization effort

---

## Known Gaps & Deferred Features

### Current Gaps (Non-StoreKit)
1. **Localization coverage**: Many UI strings are still literal
2. **Accessibility audit**: Full VoiceOver, Dynamic Type pass needed
3. **CoreML voice stress model**: Pipeline wired but needs bundled model

### Intentionally Deferred
- **StoreKit 2 billing & receipts**: Awaiting Apple Developer account
  - UI and subscription flags exist
  - Billing integration pending

---

## Development Conventions

### Adding New Features
1. Create models in `Models/` if persistence needed
2. Add business logic in `Services/`
3. Create views in `Views/` using `AnchorTheme` design system
4. Update `AnchorApp.swift` if new environment objects needed
5. Add tests in `AnchorTests/` using Swift Testing framework

### Design System Usage
- **Colors**: `AnchorTheme.Colors.sageLeaf`, `etherBlue`, `softParchment`, etc.
- **Typography**: `AnchorTheme.Typography.title`, `.bodyText` (Playfair Display + Source Sans 3)
- **Motion**: `AnchorTheme.Motion.gentleSpring`, `.breathing`
- **Orb**: Use `OrbView(state:)` for presence indicator
- **Cards**: `.anchorCard()` modifier

### Widgets
- Widget extension in `AnchorWidgets/`
- Data shared via `WidgetDataSync` (App Groups)
- 5 widget types + Live Activity

---

## Important Implementation Notes

### Session Summarization (V2 Clinical Notes)

Anchor now uses **V2 Clinical Notes** by default—a comprehensive, therapist-grade summarization system.

#### Architecture
- **Dual-contract parser**: Accepts both legacy flat JSON (v1) and nested clinical schema (v2)
- **Hybrid persistence**: Mapped fields for UI/query + raw JSON snapshot for forward compatibility
- **Automatic fallback**: If v2 parsing fails, retries once with v1 prompt
- **Runtime toggle**: Controlled via `GEMINI_SUMMARY_PROMPT_VERSION` environment variable

#### V2 Schema (Nested Clinical Format)
```json
{
  "sessionMetadata": { "date": "...", "durationMinutes": 19, "sessionNumber": 8 },
  "summary": { "narrativeSummary": "...", "primaryFocus": "Work anxiety", "relatedThemes": [...] },
  "moodJourney": { "starting": {...}, "ending": {...}, "whatShifted": "..." },
  "insights": { "keyInsight": "...", "userQuotes": [...], "patternRecognized": "..." },
  "copingStrategies": { "attempted": [...], "whatWorked": [...], "whatDidntWork": [...] },
  "patterns": { "recurringTopics": [...], "alertForTherapist": "..." },
  "progressTracking": { "previousHomework": {...}, "therapyGoals": [...] },
  "actionItems": { "forUser": [...], "forTherapist": [...], "newHomework": "..." },
  "contextForContinuity": { "peoplesMentioned": [...], "upcomingEvents": [...], "environmentalFactors": [...] },
  "safetyAssessment": { "crisisRiskDetected": false, "crisisNotes": "...", "protectiveFactors": [...] },
  "clinicalObservations": { "dominantEmotions": [...], "primaryCopingStyle": "...", "sessionEffectiveness": 7 }
}
```

#### Prompt Context (V2)
The summarizer now receives rich context:
- Session date, duration, ordinal number
- Previous session topics (last 10)
- Active therapy goals (from UserProfile)
- Previous homework (from last 6 sessions)
- User profile context (learned patterns, triggers, preferences)

#### Key Files
- `SessionSummarizer.swift`: Core summarization logic, dual parser, V1/V2 prompt generation
- `Session.swift`: SwiftData model with 35+ V2 fields (mood intensity, coping outcomes, safety flags, etc.)
- `SessionSummaryPayload.swift`: Canonical internal type consumed by UI/export
- `SummaryDiagnostics.swift`: Runtime observability (v2 success/failure counts)

#### Rollout & Control
| Method | How |
|--------|-----|
| **Default** | V2 enabled by default (fallback to V1 on parse failure) |
| **Environment** | `GEMINI_SUMMARY_PROMPT_VERSION=v1` or `v2` |
| **Info.plist** | Add `GEMINI_SUMMARY_PROMPT_VERSION` key |

#### UI/UX Surfaces
V2 fields are exposed on detail surfaces (not compact cards):
- **Post-session sheet**: Full notes with collapsible sections
- **History detail**: All V2 fields rendered hierarchically
- **PDF export**: Therapist-ready report with V2 sections
- **Share cards**: Summary + notes variants with V2 data
- **JSON export**: Complete data including `summaryRawJSON`

#### Safety Features
- `crisisRiskDetectedByModel`: Boolean flag from model safety assessment
- `crisisNotes`: Detailed safety notes when risk detected
- `protectiveFactors`: Identified protective factors
- `safetyRecommendation`: Model-generated recommendation
- Merges with existing `CrisisKeywordScanner` for comprehensive safety coverage

### Voice Processing
- Real-time WebSocket connection to Gemini Live API
- Local transcription as fallback
- Voice stress tracking with rolling baseline calibration

### Crisis Detection
- 22 keywords/phrases monitored
- Case-insensitive matching
- Immediate UI transition to emergency resources

### Free Tier Limits
- 10 minutes (600 seconds) per day
- Tracked in `UserSettings.dailyUsageSeconds`
- Resets at midnight local time

---

## Resources

- **PRD.md**: Comprehensive product requirements
- **IMPLEMENTATION_SUMMARY.md**: Current implementation status
- **README.md**: Project overview and quick start

---

*Last Updated: February 12, 2026 (V2 Clinical Notes enabled)*
