# Anchor 🎯

**AI-Powered Emotional Support at Your Fingertips**

Anchor is an iOS mobile application that provides immediate, private, and accessible emotional support through AI-powered voice conversations. Designed for adults experiencing mild-to-moderate mental health challenges, Anchor offers a judgment-free space to talk through your emotions anytime, anywhere.

---

## 🌟 Overview

**App Name:** Anchor  
**Platform:** iOS (17.0+)  
**Language:** English  
**Model:** Subscription-based  
**Status:** Active Development (MVP Phase)

### Vision
To create a safe, private, and accessible emotional support companion that empowers individuals to navigate their emotional challenges with confidence and care.

### Target Audience
- Adults (18+) with mild-to-moderate mental health challenges
- Individuals seeking immediate emotional support
- People who value privacy and accessibility in mental health care

---

## ✨ Key Features

### MVP Features (Q1 2026)
- **🎙️ Voice Conversations:** Natural, AI-powered voice conversations for emotional support
- **🔒 Privacy-First:** All conversations stored locally on your device, never in the cloud
- **🚨 Crisis Detection:** Automatic detection of crisis situations with immediate access to emergency resources
- **📊 Session History:** Track your emotional journey with session summaries and insights
- **💳 Subscription Model:** 7-day free trial, then affordable monthly/annual plans
- **⚠️ Safety Features:** Clear disclaimers, emergency resources, and professional boundaries

### Future Features (Post-MVP)
- Mood tracking and trend analysis
- Multi-language support (Spanish, French, etc.)
- Guided exercises (breathing, meditation, journaling)
- Progress milestones and achievements
- Professional therapist referral network

---

## 🏗️ Technical Architecture

### Tech Stack
- **Frontend:** SwiftUI
- **Data Persistence:** SwiftData
- **AI Integration:** OpenAI API (or similar)
- **Voice Processing:** Apple Speech Framework + AVSpeech Synthesis
- **Payments:** StoreKit 2
- **Security:** CryptoKit for local encryption

### Architecture Pattern
- **Design Pattern:** MVVM (Model-View-ViewModel)
- **Data Storage:** Privacy-first local storage with SwiftData
- **Security:** End-to-end encryption for all user data

### Project Structure
```
Anchor/
├── Anchor/                    # Main app target
│   ├── AnchorApp.swift       # App entry point
│   ├── Models/               # Data models
│   ├── Views/                # SwiftUI views
│   ├── ViewModels/           # View models
│   ├── Services/             # AI, Voice, Storage services
│   ├── Utilities/            # Helpers and extensions
│   └── Assets.xcassets/      # Images and resources
├── AnchorTests/              # Unit tests
├── AnchorUITests/            # UI tests
└── PRD.md                    # Product Requirements Document
```

---

## 🚀 Getting Started

### Prerequisites
- **Xcode:** 15.0 or later
- **iOS:** 17.0 or later
- **macOS:** Sonoma (14.0) or later
- **Swift:** 5.9 or later

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/Sleping-in/Anchor.git
   cd Anchor
   ```

2. Open the project in Xcode:
   ```bash
   open Anchor/Anchor.xcodeproj
   ```

3. Build and run on simulator or device:
   - Select your target device/simulator
   - Press `Cmd + R` to build and run

### Configuration
1. **API Keys:** Add your AI service API key to the project (instructions TBD)
2. **StoreKit:** Configure in-app purchases in App Store Connect
3. **Capabilities:** Ensure microphone and speech recognition permissions are enabled

---

## 🧪 Testing

### Run Unit Tests
```bash
# From Xcode
Cmd + U

# From command line (requires xcodebuild)
xcodebuild test -scheme Anchor -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Run UI Tests
```bash
# From Xcode
Select AnchorUITests scheme and press Cmd + U
```

---

## 🔒 Privacy & Security

Anchor is built with privacy at its core:

- ✅ **Local Storage Only:** All conversations stored on-device, never in the cloud
- ✅ **End-to-End Encryption:** All data encrypted at rest
- ✅ **No Tracking:** No analytics, no third-party SDKs
- ✅ **User Control:** Export or delete all data anytime
- ✅ **GDPR Ready:** Designed for compliance with privacy regulations
- ✅ **Transparent:** Clear privacy policy and terms of service

### What Data We Collect
- **On Device:** Conversation history, session data, user preferences
- **Server-Side:** Only anonymous AI inference requests (no personal data)

---

## ⚠️ Safety & Ethics

### Critical Safety Features
- **Crisis Detection:** Real-time monitoring for crisis keywords (suicide, self-harm)
- **Emergency Resources:** Immediate access to crisis hotlines and emergency services
- **Professional Boundaries:** Clear disclaimers that app is not a replacement for therapy
- **User Consent:** Explicit consent for all data storage

### Ethical Guidelines
1. **Do No Harm:** User safety is the top priority
2. **Transparency:** Honest about AI capabilities and limitations
3. **Privacy:** User data is sacred and protected
4. **Accessibility:** Designed for all users
5. **Accountability:** Clear feedback channels

### Important Disclaimers
⚠️ **Anchor is NOT a replacement for professional mental health care.**  
⚠️ **If you are in crisis, please contact emergency services immediately.**  
⚠️ **For immediate help:** Call 988 (Suicide & Crisis Lifeline) or your local emergency number.

---

## 💰 Business Model

### Subscription Plans
- **Free Trial:** 7 days, full feature access (no credit card required)
- **Monthly:** $9.99/month
- **Annual:** $79.99/year (save 33%)

### Value Proposition
- Unlimited conversations 24/7
- Complete privacy and security
- No scheduling, no waiting
- Significantly more affordable than traditional therapy ($100-200/session)

---

## 📊 Roadmap

### Q1 2026 - MVP Launch ✅ (In Progress)
- [x] Project setup
- [ ] Voice conversation feature
- [ ] AI integration
- [ ] Local data storage
- [ ] Crisis detection system
- [ ] Subscription integration
- [ ] Beta testing
- [ ] App Store launch

### Q2 2026 - Enhancement
- [ ] Mood tracking
- [ ] Enhanced insights
- [ ] Personalization
- [ ] Guided exercises
- [ ] Performance optimization

### Q3 2026 - Expansion
- [ ] Spanish language support
- [ ] Journal feature
- [ ] Progress milestones
- [ ] Widget support

### Q4 2026 - V2.0
- [ ] Android version
- [ ] Additional languages
- [ ] Therapist referrals
- [ ] Advanced personalization

---

## 🤝 Contributing

This is currently a closed-source project under active development. Contributions are not accepted at this time.

### Feedback & Bug Reports
If you're part of our beta testing program, please report issues to:
- **Email:** support@anchor-app.com
- **Beta Portal:** [TBD]

---

## 📄 License

Copyright © 2026 Anchor. All rights reserved.

This is proprietary software. Unauthorized copying, distribution, or modification is prohibited.

---

## 📞 Contact & Support

### General Inquiries
- **Email:** info@anchor-app.com
- **Website:** [Coming Soon]

### Support
- **Email:** support@anchor-app.com
- **Response Time:** <24 hours

### Emergency Resources
If you're in crisis:
- **US:** 988 (Suicide & Crisis Lifeline)
- **Crisis Text Line:** Text HOME to 741741
- **International:** [findahelpline.com](https://findahelpline.com)

---

## 🙏 Acknowledgments

Built with care for mental health and wellbeing.

Special thanks to:
- Mental Health America for guidelines and best practices
- Crisis Text Line for safety protocols
- Apple Developer Community for SwiftUI resources

---

## 📚 Additional Resources

- [Product Requirements Document (PRD)](./PRD.md)
- [Privacy Policy](./PRIVACY.md) _(Coming Soon)_
- [Terms of Service](./TERMS.md) _(Coming Soon)_
- [Safety Guidelines](./SAFETY.md) _(Coming Soon)_

---

**Made with ❤️ for mental health support**

*Remember: You are not alone. Help is always available.*
