# Product Requirements Document (PRD)
# Anchor - AI-Powered Emotional Support App

**Version:** 1.1  
**Last Updated:** February 8, 2026  
**Document Owner:** Product Team  
**Status:** Active Development

---

## 1. Executive Summary

### 1.1 Product Overview
Anchor is a mobile application that provides AI-powered emotional support through voice-based conversations. The app is designed to help adults with mild-to-moderate mental health challenges by offering immediate, accessible, and judgment-free emotional support whenever they need it.

### 1.2 The Problem
The global mental health market is projected to reach $280B by 2030, yet a significant therapy gap persists: only 47% of U.S. adults with mental illness receive treatment. Four critical barriers prevent people from getting help:

1. **Cost:** Average therapy session costs $150–$250; insurance coverage is inconsistent
2. **Access:** Rural and underserved areas face severe therapist shortages
3. **Stigma:** Many avoid seeking help due to social stigma around mental health
4. **Availability:** Traditional therapy operates on limited schedules; crises don't wait for office hours

Anchor addresses all four barriers by providing an affordable, always-available, private, voice-first emotional support companion.

### 1.3 Vision Statement
To create a safe, private, and accessible emotional support companion that empowers individuals to navigate their emotional challenges with confidence and care.

### 1.4 Target Audience
- **Primary Users:** Adults (18+) experiencing mild-to-moderate mental health challenges
- **Secondary Users:** Individuals seeking emotional support during stressful life events
- **Geographic Focus:** Global, with initial launch in English-speaking markets

### 1.5 Key Success Metrics
- User retention rate (30-day, 90-day)
- Session completion rate
- User satisfaction score (NPS)
- Crisis prevention effectiveness
- Privacy compliance adherence

### 1.6 Competitive Landscape

| App | Approach | Strengths | Weaknesses | Anchor's Advantage |
|-----|----------|-----------|------------|--------------------|
| **Wysa** | CBT chatbot (text) | Evidence-based, affordable | Text-only, scripted feel | Voice-first, natural conversation |
| **Woebot** | CBT chatbot (text) | Clinical validation, structured programs | Rigid flows, no voice | Freeform voice, adapts to user |
| **Youper** | Mood tracking + CBT chat | Data-driven insights | Limited conversational depth | Deep voice conversations, learned profile |
| **Noah** | AI therapy companion | Conversational tone | New, limited track record | Mature crisis protocol, privacy-first |
| **Sonia** | AI therapist (voice) | Voice interaction | Cloud-stored data, subscription-heavy | 100% local storage, no cloud sync |
| **Bestie** | AI friend (chat) | Casual, approachable | Shallow support, gamified | Clinically-informed, no gamification |

**Anchor's Key Differentiators:**
1. **Voice-native:** Real-time voice conversation via Gemini Live API — not text-to-speech over a chatbot
2. **Complete privacy:** All data stored locally on-device with SwiftData encryption; conversations never leave the device
3. **Cumulative learning:** AI builds a persistent user profile across sessions (recurring topics, triggers, coping strategies, emotional patterns) without cloud sync
4. **No manipulation:** No gamification, no social features, no streaks-for-retention — just genuine support
5. **Crisis-aware:** Real-time crisis detection with immediate 988 Lifeline integration and localized emergency resources

---

## 2. Product Goals & Objectives

### 2.1 Primary Goals
1. Provide immediate, accessible emotional support 24/7
2. Ensure user privacy and data security
3. Maintain highest safety and ethical standards
4. Create a sustainable subscription-based business model
5. Scale to serve a global user base

### 2.2 Success Criteria
- **Q1 2026:** MVP launch with core voice conversation features
- **Q2 2026:** 10,000 active users, 80% session completion rate
- **Q3 2026:** Break-even on operational costs
- **Q4 2026:** 50,000 active users, expansion to additional languages

---

## 3. User Personas

### 3.1 Primary Persona: "Sarah" - The Anxious Professional
- **Age:** 28-35
- **Occupation:** Working professional
- **Pain Points:** 
  - Experiences anxiety and stress from work
  - Limited time for traditional therapy
  - Needs immediate support during anxiety episodes
- **Goals:** Quick access to emotional support, privacy, flexibility

### 3.2 Secondary Persona: "Michael" - The Isolated Remote Worker
- **Age:** 25-40
- **Occupation:** Remote worker
- **Pain Points:**
  - Social isolation
  - Difficulty connecting with others
  - Feels judged when sharing emotions
- **Goals:** Non-judgmental support, convenience, anonymity

---

## 4. Core Features

### 4.1 Voice-Based Conversations (MVP)
**Priority:** P0 (Must Have)

**Description:** Real-time voice conversations with AI-powered emotional support system

**User Stories:**
- As a user, I want to start a voice conversation with a tap so that I can quickly get support
- As a user, I want natural-sounding responses so that the experience feels authentic
- As a user, I want the AI to remember context within the session so that I don't have to repeat myself

**Acceptance Criteria:**
- User can initiate voice conversation with single tap
- AI responds within 2-3 seconds
- Conversation maintains context throughout session
- Voice quality is clear and natural

**Technical Requirements:**
- Voice-to-text transcription
- Natural language processing
- Text-to-speech output
- Real-time processing

### 4.2 Local Data Storage (MVP)
**Priority:** P0 (Must Have)

**Description:** All personal data and conversation history stored locally on device

**User Stories:**
- As a user, I want my conversations stored locally so that my privacy is protected
- As a user, I want to review past conversations so that I can track my emotional journey
- As a user, I want to delete my data anytime so that I maintain control

**Acceptance Criteria:**
- All data encrypted at rest
- No cloud backup of conversation content
- User can export or delete all data
- Data persists between app sessions

**Technical Requirements:**
- SwiftData for local storage
- End-to-end encryption
- Secure deletion mechanisms
- Export functionality

### 4.3 Crisis Detection & Safety Features (MVP)
**Priority:** P0 (Must Have)

**Description:** Automatic detection of crisis situations with appropriate interventions

**User Stories:**
- As a user in crisis, I want immediate access to emergency resources so that I can get appropriate help
- As a user, I want clear disclaimers about the app's limitations so that I understand it's not a replacement for professional care
- As a user, I want the app to recognize when I need more than it can provide

**Acceptance Criteria:**
- AI detects crisis keywords/patterns
- Emergency resources displayed immediately
- Clear disclaimers shown at first use and in settings
- Crisis hotline numbers provided (localized)

**Technical Requirements:**
- Crisis keyword detection algorithm
- Emergency contact integration
- Disclaimer management system
- Localized emergency resources

### 4.4 Session History & Insights (MVP)
**Priority:** P1 (Should Have)

**Description:** View past conversation summaries and emotional patterns

**User Stories:**
- As a user, I want to see my conversation history so that I can reflect on my progress
- As a user, I want privacy controls for my history so that I feel safe
- As a user, I want to understand my emotional patterns over time

**Acceptance Criteria:**
- List view of past sessions with timestamps
- Session summaries (not full transcripts)
- Ability to delete individual sessions
- Basic emotional trend visualization

**Technical Requirements:**
- SwiftUI list interface
- Local data querying
- Visualization components
- Privacy controls

### 4.5 Subscription Management (MVP)
**Priority:** P1 (Should Have)

**Description:** In-app subscription with free trial period

**User Stories:**
- As a user, I want to try the app free for 7 days so that I can evaluate it
- As a user, I want transparent pricing so that I can make informed decisions
- As a user, I want to manage my subscription easily

**Acceptance Criteria:**
- 7-day free trial (no credit card required)
- Clear pricing display
- Easy cancellation process
- StoreKit integration

**Technical Requirements:**
- StoreKit 2 integration
- Subscription status management
- Receipt validation
- Restore purchases functionality

### 4.6 Future Features (Post-MVP)
**Priority:** P2 (Nice to Have)

- **Mood tracking:** Daily mood check-ins with trend analysis
- **Personalization:** AI learns user's preferences and conversation style
- **Multi-language support:** Expand beyond English
- **Guided exercises:** Breathing exercises, meditation, journaling prompts
- **Progress milestones:** Celebrate user achievements
- **Professional resources:** Connect users with therapists when needed

---

## 5. User Experience (UX)

### 5.1 User Flow - First Time User
1. Launch app → Onboarding screens
2. View safety disclaimers and terms
3. Choose to start free trial or explore features
4. Complete brief setup (notification preferences)
5. Start first conversation

### 5.2 User Flow - Returning User
1. Launch app → Home screen
2. Tap "Start Conversation" button
3. Voice conversation with AI
4. End conversation → Session summary
5. Option to view history or settings

### 5.3 Navigation Structure
```
Home
├── Start Conversation (Primary Action)
├── History Tab
│   ├── Session List
│   └── Session Details
├── Insights Tab
│   └── Emotional Trends
└── Settings Tab
    ├── Subscription
    ├── Privacy & Data
    ├── Safety Resources
    └── About
```

### 5.4 Design Principles
- **Minimal & Calm:** Clean interface that doesn't overwhelm
- **Accessible:** Large touch targets, high contrast, VoiceOver support
- **Private:** No user tracking, no social features
- **Safe:** Clear disclaimers, easy access to emergency resources

---

## 6. Technical Architecture

### 6.1 Platform
- **iOS:** Swift + SwiftUI (iOS 17+)
- **Android:** (Future consideration)

### 6.2 Technology Stack
- **UI Framework:** SwiftUI (iOS 17+)
- **Data Persistence:** SwiftData with file-level encryption
- **AI Integration:**
  - **Primary:** Google Gemini Live API (WebSocket, real-time voice)
  - **Summarisation:** Google Gemini Flash (REST, session notes)
  - **Fallback:** AIServiceProtocol abstraction supports OpenAI Realtime and local offline mode
- **Voice Processing:**
  - AVAudioEngine (24kHz, Linear PCM)
  - Server-side VAD via Gemini Live
- **Payments:** StoreKit 2
- **Security:** Keychain (API keys), SwiftData encryption
- **Haptics:** CoreHaptics (breathing exercises)
- **Privacy:** PrivacyInfo.xcprivacy manifest, no tracking

### 6.3 Architecture Pattern
- **MVVM (Model-View-ViewModel)**
- **Privacy-First Design:** Local data storage, minimal cloud interaction
- **Modular Design:** Separate modules for voice, AI, storage, subscription

### 6.4 Data Model
```swift
// Core Data Models
- User: Preferences, subscription status
- Session: Timestamp, duration, summary, mood
- Message: Text, timestamp, sender (user/AI)
- Settings: Privacy preferences, notifications
```

### 6.5 API Integration
- **AI Service:** REST API for conversation processing
- **Voice Processing:** Local (Apple frameworks)
- **Subscription:** StoreKit (Apple)
- **Emergency Resources:** Embedded/local data

### 6.6 Security & Privacy
- **Local Encryption:** All conversation data encrypted at rest
- **No Cloud Storage:** Conversations never leave device
- **Secure Communication:** HTTPS for API calls
- **No Tracking:** No analytics, no third-party SDKs
- **GDPR/HIPAA Aware:** Design for compliance readiness

---

## 7. Safety & Ethical Considerations

### 7.1 Critical Safety Requirements

#### 7.1.1 Crisis Detection
- Real-time monitoring for crisis keywords (suicide, self-harm, violence)
- Immediate display of emergency resources
- Clear escalation paths to human help

#### 7.1.2 Professional Boundaries
- Clear disclaimers: "Not a replacement for professional therapy"
- App positions itself as support, not treatment
- Encourage professional help when appropriate

#### 7.1.3 User Consent & Transparency
- Clear privacy policy
- Explicit consent for data storage
- Transparent about AI limitations

#### 7.1.4 Data Privacy
- GDPR compliance
- User right to delete all data
- No data sharing with third parties
- No conversation data leaves device

### 7.2 Ethical Guidelines
1. **Do No Harm:** Prioritize user safety above all else
2. **Transparency:** Be honest about capabilities and limitations
3. **Privacy:** Treat user data as sacred
4. **Accessibility:** Ensure app is usable by all
5. **Accountability:** Clear channels for user feedback and concerns

### 7.3 Content Moderation
- AI trained to avoid harmful advice
- Flagging system for concerning patterns
- Regular review of AI responses (anonymized data)
- User reporting mechanism

### 7.4 System Prompt (Model Instruction)
Anchor uses a fixed base system instruction applied to every live session, with dynamic personalisation injected at session start.

**Base Prompt:** Defines ROLE & IDENTITY, CAPABILITIES, STRICT LIMITATIONS, CRISIS PROTOCOL, CONVERSATION STYLE, and PRIVACY boundaries. See `AnchorSystemPrompt.swift` for the verbatim text.

**Dynamic Personalisation (injected per-session):**
The `personalised()` function builds a context block from:
- User's name and communication style preference (gentle / listener / direct)
- Primary concerns from onboarding
- Total session count
- Recent mood check-in history (last 5 sessions, before → after)
- Recent session topic summaries (last 10)
- Crisis detection history count
- **Cumulative learned UserProfile** built by `ProfileBuilder` across all sessions:
  - Recurring topics & triggers
  - Effective coping strategies
  - Emotional patterns
  - Communication style notes
  - Mood baseline

This ensures the AI has relevant context without cloud storage — all profile data lives in on-device SwiftData.

**Key Behaviours:**
1. **Validate first** — acknowledge and reflect the user's emotions before exploring
2. **Explore gently** — use open-ended questions to help the user go deeper
3. **Support with evidence** — suggest coping strategies grounded in CBT, mindfulness, or grounding techniques
4. **Empower** — help the user identify their own strengths and next steps
5. **Mirror language** — adapt to the user's vocabulary and tone; avoid clinical jargon unless they use it first

---

## 8. Compliance & Legal

### 8.1 Regulatory Compliance
- **GDPR:** User data rights, privacy by design
- **CCPA:** California privacy requirements
- **COPPA:** Age restriction (18+)
- **Accessibility:** WCAG 2.1 AA standards

### 8.2 Terms of Service
- Clear limitation of liability
- Not medical advice disclaimer
- Age restrictions
- Acceptable use policy

### 8.3 Privacy Policy
- Data collection practices (minimal)
- Data storage (local only)
- User rights (access, deletion, export)
- Third-party services (AI API only)

---

## 9. Business Model

### 9.1 Monetization Strategy
**Two-Tier Subscription Model (Professional tier planned for future):**

| | Free | Premium |
|---|------|--------|
| **Price** | $0 | $9.99/mo ($79.99/yr) |
| **Daily usage** | 10 min/day | Unlimited |
| **Voice conversation** | ✓ | ✓ |
| **Crisis resources** | ✓ | ✓ |
| **Mood tracking** | Basic | Full history + trends |
| **Insights & streaks** | — | ✓ |
| **Breathing exercises** | — | ✓ |
| **Learned profile** | — | ✓ |
| **Data export** | — | JSON |

**Free Trial:** 7 days of Premium, no credit card required.

**Conversion Target:** Free → Premium: 15-20% within 30 days.

**Future Professional Tier** ($19.99/mo / $149.99/yr):
- PDF session summaries for sharing with therapists
- Therapist referral directory
- Priority support
- Advanced data export

> **Note:** StoreKit 2 integration deferred until Apple Developer account is obtained. Current implementation uses a local trial/subscription flag for development.

### 9.2 Value Proposition
- Unlimited conversations
- Complete privacy
- 24/7 availability
- No therapy scheduling needed
- Significantly cheaper than traditional therapy

### 9.3 Revenue Projections (Year 1)
- **Q1:** 1,000 paying users → $10K MRR
- **Q2:** 5,000 paying users → $50K MRR
- **Q3:** 15,000 paying users → $150K MRR
- **Q4:** 30,000 paying users → $300K MRR

### 9.4 Cost Structure
- **AI API Costs:** ~$2 per user/month
- **Infrastructure:** $500/month
- **App Store Fees:** 30% (first year), 15% (subsequent)
- **Development:** Internal team

---

## 10. Go-to-Market Strategy

### 10.1 Launch Plan
- **Phase 1 — Closed Beta (Weeks 1-4):**
  - 100 users via TestFlight, recruited from Reddit r/mentalhealth, r/anxiety
  - Selection criteria: diverse demographics, mix of therapy-experienced and never-tried
  - Weekly feedback surveys + in-app feedback button
  - Focus: safety validation, crisis detection accuracy, conversation quality
- **Phase 2 — Open Beta (Weeks 5-8):**
  - Expand to 1,000 users, open TestFlight link
  - A/B test onboarding flows and conversation starters
  - Iterate on retention-driving features (insights, streaks, breathing exercises)
- **Phase 3 — Public Launch (Week 9):**
  - App Store submission with ASO-optimised listing
  - Press kit distribution to tech + wellness publications
  - Launch-week social media campaign

### 10.2 Marketing Channels
- **Organic:** App Store Optimization (keywords: anxiety support, AI therapy, mental health companion)
- **Content Marketing:** Weekly blog posts (topics: coping strategies, mental health awareness, Anchor use cases)
- **Social Media:** Instagram (carousel tips), TikTok (60s "Anchor helped me" stories), Twitter/X (mental health threads)
- **Partnerships:** Mental Health America, NAMI local chapters, university counseling centres
- **PR:** Launch coverage in TechCrunch, The Verge, Mashable; wellness publications (Healthline, Verywell Mind)
- **Community:** Reddit AMAs, Discord mental health communities

### 10.3 User Acquisition
- **Target CAC:** $5 per user
- **Conversion Rate Goal:** 25% trial-to-paid
- **Referral Program:** (Future consideration)

---

## 11. Constraints & Limitations

### 11.1 Technical Constraints
- iOS 17+ requirement (SwiftData, latest SwiftUI)
- Device storage requirements (conversation history)
- Internet required for AI inference
- Voice input quality dependent on device microphone

### 11.2 Business Constraints
- Bootstrap/lean budget (minimal external funding)
- Small team (2-3 developers initially)
- Apple App Store guidelines compliance
- Subscription revenue dependency

### 11.3 Legal Constraints
- Cannot provide medical advice or diagnosis
- Cannot replace professional therapy
- Must comply with all privacy regulations
- Age restrictions (18+ only)

### 11.4 Ethical Constraints
- No social features (to avoid comparison/competition)
- No gamification (to avoid manipulation)
- No data monetization
- No third-party advertising

---

## 12. Success Metrics & KPIs

### 12.1 User Engagement Metrics
- **Daily Active Users (DAU)**
- **Monthly Active Users (MAU)**
- **DAU/MAU Ratio:** Target 30%+ (Wysa benchmark: ~25%, Woebot: ~20%)
- **Average Session Duration:** Target 10-15 minutes (industry average for AI mental health: 8 min)
- **Sessions per User per Week:** Target 3+ (Wysa reports ~2.5)
- **30-Day Retention:** Target 40%+ (mental health app average: 25-30%)
- **90-Day Retention:** Target 20%+ (industry average: 10-15%)

### 12.2 Business Metrics
- **Trial-to-Paid Conversion Rate:** Target 25% (industry average: 10-15%)
- **Monthly Recurring Revenue (MRR)**
- **Churn Rate:** Target <5% monthly (meditation apps: 8-12%)
- **Customer Lifetime Value (LTV):** Target $200+ (based on 20-month avg lifetime)
- **Customer Acquisition Cost (CAC):** Target $5 (Calm/Headspace: $30-50; Anchor targets organic-first)

### 12.3 Product Health Metrics
- **Crash Rate:** <0.1%
- **App Store Rating:** Target 4.5+
- **Net Promoter Score (NPS):** Target 50+
- **Session Completion Rate:** Target 85%+

### 12.4 Safety Metrics
- **Crisis Detection Accuracy:** Target 95%+
- **User Safety Reports:** Track and respond <24hr
- **Emergency Resource Access:** Monitor usage

---

## 13. Roadmap

### 13.1 MVP (Q1 2026) - Months 1-3
- [x] Project setup and architecture
- [x] Voice conversation interface (Gemini Live WebSocket)
- [x] AI integration (Gemini Live + Flash summariser)
- [x] Local data storage (SwiftData with encryption)
- [x] Crisis detection (keyword + pattern, 988 integration)
- [x] Safety disclaimer & onboarding flow
- [x] Session history with summaries
- [x] Mood tracking (pre/post session)
- [x] Insights dashboard with streaks
- [x] Guided breathing exercises (CoreHaptics)
- [x] Dark mode with adaptive colours
- [x] Cumulative user profile learning (ProfileBuilder)
- [x] Data export (JSON with learned profile)
- [x] Privacy manifest (PrivacyInfo.xcprivacy)
- [x] Localisation readiness (Localizable.xcstrings)
- [x] AIServiceProtocol abstraction layer
- [ ] Accessibility audit (VoiceOver, Dynamic Type, accessibilityHint)
- [ ] User reporting mechanism for problematic AI responses
- [ ] In-app help / FAQ screens
- [ ] Unit & UI test coverage expansion

### 13.2 V1.1 — Post Developer Account
- [ ] **StoreKit 2 subscription integration**
- [ ] Restore purchases
- [ ] Beta testing (TestFlight)
- [ ] App Store submission
- [ ] App Store metadata & ASO

### 13.3 V1.2 (Post-Launch)
- [ ] Home screen widgets (mood streak, weekly trend, quick check-in, breathing shortcut)
- [ ] Lock screen widget (streak count + last mood)
- [ ] Journal feature
- [ ] Enhanced insights and trend visualisations
- [ ] Spanish language support
- [ ] Enhanced crisis resources (localised per region)

### 13.4 V2.0 (Future)
- [ ] Professional tier ($19.99/mo) with PDF export & therapist referrals
- [ ] Additional languages
- [ ] Advanced personalisation (voice tone adaptation)
- [ ] Android version
- [ ] Community resources (carefully moderated)

---

## 14. Risks & Mitigation

### 14.1 Technical Risks
| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| AI API downtime | High | Medium | Text fallback mode; AIServiceProtocol abstraction allows future provider swap |
| Voice recognition accuracy | Medium | Medium | Text fallback mode, server-side VAD |
| Data loss | High | Low | SwiftData with encryption, export functionality |
| Performance issues | Medium | Medium | Optimization, testing |
| **AI hallucination / harmful response** | **Critical** | **Medium** | **Strict system prompt boundaries, crisis keyword detection, model temperature limits, session summarizer validates output** |
| **Single-provider dependency (Gemini)** | **High** | **Medium** | **AIServiceProtocol abstraction layer allows drop-in replacement when budget permits; text fallback available offline** |
| **Model output inappropriate for mental health** | **Critical** | **Low** | **Fixed system prompt with STRICT LIMITATIONS, CRISIS PROTOCOL; prompt tested against adversarial inputs; user reporting mechanism** |

### 14.2 Business Risks
| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Low conversion rate | High | Medium | Extended trial, better onboarding |
| High churn | High | Medium | Engagement features, value communication |
| AI costs exceed projections | Medium | Medium | Cost monitoring, optimization |
| Competition | Medium | High | Differentiation on privacy, voice-first, no gamification |
| **User claims AI caused harm** | **Critical** | **Low** | **Clear disclaimers at onboarding + settings, session-level safety reminders, legal review of ToS, incident response plan** |
| **Negative media coverage** | **High** | **Low** | **Proactive transparency blog, safety-first messaging, rapid response protocol** |

### 14.3 Legal/Compliance Risks
| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Privacy violation | Critical | Low | Privacy-first design, legal review |
| User harm | Critical | Low | Strong safety features, disclaimers |
| App Store rejection | High | Low | Guidelines compliance, legal review |
| Regulatory changes | Medium | Medium | Legal monitoring, adaptability |

---

## 15. Support & Documentation

### 15.1 User Support
- **In-App Help:** Context-sensitive help screens
- **FAQ:** Comprehensive FAQ in app and website
- **Email Support:** support@anchor-app.com
- **Response Time:** <24 hours

### 15.2 Documentation
- **User Guide:** In-app tutorial and tips
- **Privacy Policy:** Clear, accessible language
- **Terms of Service:** Comprehensive, fair
- **Safety Resources:** Emergency contacts, help lines

---

## 16. Appendices

### 16.1 Glossary
- **MVP:** Minimum Viable Product
- **NPS:** Net Promoter Score
- **CAC:** Customer Acquisition Cost
- **LTV:** Lifetime Value
- **MRR:** Monthly Recurring Revenue
- **ASO:** App Store Optimization

### 16.2 References
- Mental Health America guidelines
- NIMH (National Institute of Mental Health) resources
- Apple Human Interface Guidelines
- GDPR compliance documentation
- Crisis Text Line best practices

### 16.3 Version History
| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Feb 7, 2026 | Product Team | Initial PRD creation |
| 1.1 | Feb 8, 2026 | Product Team | Added competitive landscape, enhanced problem statement, 3-tier monetisation, competitive benchmarks, AI-specific risks, updated tech stack & system prompt to reflect implementation, updated roadmap with completed items |

---

## 17. Approval & Sign-off

**Product Owner:** _______________________  Date: __________

**Engineering Lead:** _______________________  Date: __________

**Legal/Compliance:** _______________________  Date: __________

**Executive Sponsor:** _______________________  Date: __________

---

**Document End**
