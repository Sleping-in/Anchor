//
//  HelpFAQView.swift
//  Anchor
//
//  In-app help and frequently asked questions.
//

import SwiftUI

struct HelpFAQView: View {
    private let sections: [FAQSection] = [
        FAQSection(title: String(localized: "Getting Started"), items: [
            FAQItem(
                question: String(localized: "How do I start a conversation?"),
                answer: String(localized: "Tap the microphone button on the home screen. You'll do a quick mood check-in, then Anchor will start listening. Just speak naturally — Anchor responds in real time.")
            ),
            FAQItem(
                question: String(localized: "What should I talk about?"),
                answer: String(localized: "Anything on your mind. You can talk about stress, anxiety, relationships, sleep, work, or just how your day went. You can also tap one of the conversation starters if you're not sure where to begin.")
            ),
            FAQItem(
                question: String(localized: "Do I need an internet connection?"),
                answer: String(localized: "Yes, voice conversations require an internet connection. If you're offline, Anchor switches to a text-only mode so you can still check in.")
            ),
        ]),
        FAQSection(title: String(localized: "Privacy & Safety"), items: [
            FAQItem(
                question: String(localized: "Is my data stored in the cloud?"),
                answer: String(localized: "No. All your conversations, mood data, and personal information are stored locally on your device. Nothing is ever uploaded to a server or cloud storage.")
            ),
            FAQItem(
                question: String(localized: "Can I delete my data?"),
                answer: String(localized: "Yes. Go to Settings → Privacy & Data → Delete All My Data. You can also delete individual sessions from the History screen by swiping left.")
            ),
            FAQItem(
                question: String(localized: "Can I export my data?"),
                answer: String(localized: "Yes. Go to Settings → Privacy & Data → Export My Data, or use the menu in History. Your data is exported as a JSON file that you can save or share.")
            ),
            FAQItem(
                question: String(localized: "What happens if Anchor detects a crisis?"),
                answer: String(localized: "If Anchor detects language suggesting you may be in danger, it will pause the conversation and show you emergency resources including the 988 Suicide & Crisis Lifeline. You can choose to view resources, continue the conversation, or end the session.")
            ),
        ]),
        FAQSection(title: String(localized: "Features"), items: [
            FAQItem(
                question: String(localized: "What is the Learned Profile?"),
                answer: String(localized: "Over time, Anchor learns your recurring topics, coping strategies, emotional patterns, and communication preferences from your session summaries. This helps personalise conversations — and it all stays on your device.")
            ),
            FAQItem(
                question: String(localized: "How does mood tracking work?"),
                answer: String(localized: "Before and after each conversation, you'll rate how you're feeling on a 1–5 scale. Over time, you can see your mood trends in the Insights tab.")
            ),
            FAQItem(
                question: String(localized: "What are streaks?"),
                answer: String(localized: "Your streak counts consecutive days you've had a conversation with Anchor. It's shown on the home screen. Streaks reset if you miss a day.")
            ),
            FAQItem(
                question: String(localized: "How do breathing exercises work?"),
                answer: String(localized: "Tap the wind icon on the home screen. Follow the expanding and contracting circle — breathe in as it grows, hold, then breathe out as it shrinks. You'll feel gentle haptic feedback to guide your rhythm.")
            ),
        ]),
        FAQSection(title: String(localized: "Account & Subscription"), items: [
            FAQItem(
                question: String(localized: "What's included in the free tier?"),
                answer: String(localized: "Free users get 10 minutes of conversation time per day, with access to voice conversations and crisis resources. Premium unlocks unlimited conversations, insights, streaks, breathing exercises, and data export.")
            ),
            FAQItem(
                question: String(localized: "How do I manage my subscription?"),
                answer: String(localized: "Go to Settings → Manage Subscription. You can view your current plan, start a free trial, or change your subscription.")
            ),
        ]),
        FAQSection(title: String(localized: "Troubleshooting"), items: [
            FAQItem(
                question: String(localized: "Anchor isn't responding to my voice"),
                answer: String(localized: "Make sure microphone access is enabled in your device Settings → Anchor → Microphone. Also check that you have an internet connection. If the issue persists, try ending and restarting the conversation.")
            ),
            FAQItem(
                question: String(localized: "The audio sounds choppy"),
                answer: String(localized: "This can happen with a slow internet connection. Try moving to a location with better Wi-Fi or cellular signal. You can also adjust the voice speed in Settings → Preferences.")
            ),
            FAQItem(
                question: String(localized: "How do I report a problematic AI response?"),
                answer: String(localized: "During a conversation, long-press (or right-click) on any Anchor response to see a context menu with \"Report Response\". Select a reason and submit — the report is saved locally.")
            ),
        ]),
        FAQSection(title: String(localized: "Important Limitations"), items: [
            FAQItem(
                question: String(localized: "Is Anchor a replacement for therapy?"),
                answer: String(localized: "No. Anchor is an emotional support companion, not a therapist, counselor, or medical professional. It cannot diagnose conditions, recommend medications, or provide crisis intervention. If you need professional help, please reach out to a licensed therapist or counselor.")
            ),
            FAQItem(
                question: String(localized: "Where can I find emergency resources?"),
                answer: String(localized: "Tap the SOS button on the home screen, or go to Settings → Safety → Emergency Resources. In a crisis, call 988 (Suicide & Crisis Lifeline) or your local emergency number.")
            ),
        ]),
    ]

    var body: some View {
        List {
            ForEach(sections) { section in
                Section(header: Text(section.title)) {
                    ForEach(section.items) { item in
                        DisclosureGroup {
                            Text(item.answer)
                                .font(AnchorTheme.Typography.bodyText)
                                .anchorSecondaryText()
                                .padding(.vertical, 8)
                        } label: {
                            Text(item.question)
                                .font(AnchorTheme.Typography.subheadline)
                                .anchorPrimaryText()
                        }
                    }
                }
            }

            Section {
                Link(destination: SupportContact.mailtoURL) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(AnchorTheme.Colors.sageLeaf)
                        Text(String(localized: "Contact Support"))
                            .font(AnchorTheme.Typography.subheadline)
                            .anchorPrimaryText()
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .anchorSecondaryText()
                    }
                }
            }
        }
        .navigationTitle(String(localized: "Help & FAQ"))
        .navigationBarTitleDisplayMode(.large)
        .scrollContentBackground(.hidden)
        .background(AnchorTheme.Colors.softParchment)
    }
}

// MARK: - Models

private struct FAQSection: Identifiable {
    let id = UUID()
    let title: String
    let items: [FAQItem]
}

private struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

#Preview {
    NavigationStack {
        HelpFAQView()
    }
}
