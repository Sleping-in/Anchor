# Implementation Summary - Anchor

**Last Updated:** February 12, 2026 (WhisperKit added)  
**Status:** Feature-complete for MVP + V1.1/V1.2 additions (StoreKit deferred)

## Overview
Anchor is a voice-first emotional support app with local-only data storage, crisis safety, and session insights. The app now includes live voice conversations, summaries, breathing exercises, smart reminders, live activity, app lock, and expanded history/insights.

## Core Features Implemented

### Voice Conversations (MVP)
- Real-time Gemini Live voice sessions with streaming transcription and audio output.
- Voice activity detection + silence end-of-turn.
- Session pause/resume, interruption handling, and background/foreground reconnection.

### Safety & Crisis (MVP)
- Crisis keyword detection with safety disclaimers and localized emergency resources.
- Emergency resources view and quick SOS access from Home.

### Local Data & Privacy (MVP)
- SwiftData local-only storage with file protection.
- Export all data to JSON and delete individual/all sessions.
- No cloud sync.

### Onboarding & Consent (MVP)
- Guided onboarding with safety acknowledgment, preferences, and now optional Face ID app lock.

### History & Insights (MVP+)
- Session list with summaries, mood shifts, tags, and crisis indicators.
- History highlights card (sessions, streak, avg shift, top topics/triggers).
- Session sharing (summary text + shareable card).
- Insights dashboard: weekly stats, comparisons, mood heatmap, streaks, voice stress trends.

### Mood & Focus (V1.1)
- Post-session mood check-in with emoji scale.
- Mood triggers tagging.
- Session focus and conversation personas.

### Breathing & Anchor Moments (V1.1/V1.2)
- Multiple breathing patterns (box, 4-7-8, physiological sigh).
- Selection UI + guided exercise.
- Anchor Moments scheduled micro-interactions with ambient audio.

### Smart Reminders (V1.1)
- Check-in time estimator + notification scheduling with optional override.

### Live Activity (V1.2)
- Live Activity with time elapsed, orb status, focus badge, and deep links.
- End-session action from Live Activity.

### App Lock (V1.2)
- Optional Face ID / passcode gate on app return.
- Settings + onboarding toggle.

## STT Enhancements & Transcript Stability
- **Adaptive barge-in threshold** calibrated from ambient noise floor
- **4-stage audio preprocessing** (high-pass filter, noise gate, AGC, limiter)
- **150+ term domain vocabulary** with post-processing corrections
- **Echo suppression framework** (playback gating + spectral tracking)
- **STTDiagnostics** for real-time quality monitoring
- **Transcript merging fix** - 2-second grace period prevents long utterances from splitting when server `turnComplete` arrives before local STT finishes finalizing
- **STT restart detection** - Automatically appends new utterances to previous message when STT hits internal limits
- **Duplicate transcript filtering** - Skips processing identical text to prevent UI spam and "multiple updates per frame" warnings
- **Debounced clear timer** - Prevents duplicate scheduling of message ID cleanup
- **WhisperKit integration** - OpenAI Whisper-based on-device transcription with configurable model sizes (tiny/base/small/medium/large)

## Architecture & Data Models
**Models:** Session, UserSettings, UserProfile, CrisisResources, ConversationMessage, FlaggedResponse, BookmarkedInsight, SessionFocus, ConversationPersona.  
**Services:** GeminiLiveClient, LiveAudioIO, CrisisKeywordScanner, CrisisResourceStore, ThroughLineAPIClient, SessionSummarizer, ProfileBuilder, DataExporter, NotificationManager, VoiceStressTracker (CoreML-ready), WeeklySummaryBuilder, CheckInTimeEstimator, DeepLinkRouter, WidgetDataSync.

## Design System
- AnchorTheme with custom typography, colors, and motion.
- OrbView + VoiceStateController for presence feedback.

## Backend Infrastructure
- **Primary AI Provider**: Google Gemini API (AI Studio)
- **Fallback AI Provider**: Google Vertex AI API (activated on 429 rate limits)
- **Summary Model**: gemini-2.5-flash (configurable via GEMINI_SUMMARY_MODEL env var)
- **Rate Limiting**: Request deduplication + exponential backoff with automatic fallback

## Tests
- Unit tests: 72
- UI tests: 9
- All tests passing on physical device (mohammad’s iPhone).

## Gap Audit (Non-StoreKit)
The following are still needed to fully align with PRD and launch readiness:
1. **Localization coverage**  
   Many UI strings are still literal and not yet in `Localizable.xcstrings`.  
2. **Accessibility audit**  
   Full VoiceOver, Dynamic Type, and contrast pass still needed.
3. **App Store readiness**  
   Confirm privacy manifest coverage and required reasons; finalize metadata/screenshots.
4. **Optional CoreML voice stress model**  
   The pipeline is wired but needs a bundled model to enable ML scoring.

## Deferred (Intentional)
- **StoreKit 2 billing & receipts** (awaiting Apple Developer account).
