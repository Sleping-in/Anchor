//
//  SupportViews.swift
//  Anchor
//
//  Created for Anchor - AI-Powered Emotional Support
//  Placeholder views for Terms, Privacy, Safety, and About
//

import SwiftUI
import UIKit

// MARK: - Privacy Policy View
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 16) {
                Text(String(localized: "Privacy Policy"))
                    .font(AnchorTheme.Typography.title)
                    .anchorPrimaryText()
                    .multilineTextAlignment(.center)

                Text(String(localized: "Last Updated: February 7, 2026"))
                    .font(AnchorTheme.Typography.caption)
                    .anchorSecondaryText()
                    .multilineTextAlignment(.center)

                PolicySection(
                    title: String(localized: "Your Privacy Matters"),
                    content: String(
                        localized:
                            "At Anchor, we take your privacy seriously. All your conversations are stored locally on your device and are never uploaded to the cloud."
                    )
                )

                PolicySection(
                    title: String(localized: "Data Collection"),
                    content: String(
                        localized:
                            "We collect minimal data:\n• Conversation history (stored locally)\n• User preferences (stored locally)\n• On-device voice stress signal (used to tune responses, not diagnostic)\n• Anonymous usage analytics (optional)"
                    )
                )

                PolicySection(
                    title: String(localized: "Data Storage"),
                    content: String(
                        localized:
                            "All personal data is encrypted and stored only on your device. We cannot access your conversations or personal information."
                    )
                )

                PolicySection(
                    title: String(localized: "Third-Party Services"),
                    content: String(
                        localized:
                            "We use AI services for conversation processing. Only anonymous conversation text is sent to our AI provider, never any identifying information."
                    )
                )

                PolicySection(
                    title: String(localized: "Your Rights"),
                    content: String(
                        localized:
                            "You have the right to:\n• Access your data\n• Export your data\n• Delete your data at any time"
                    )
                )
            }
            .padding(.horizontal, 24)
            .padding(.vertical)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle(String(localized: "Privacy Policy"))
        .navigationBarTitleDisplayMode(.inline)
        .anchorScreenBackground()
    }
}

// MARK: - Terms of Service View
struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 16) {
                Text(String(localized: "Terms of Service"))
                    .font(AnchorTheme.Typography.title)
                    .anchorPrimaryText()
                    .multilineTextAlignment(.center)

                Text(String(localized: "Last Updated: February 7, 2026"))
                    .font(AnchorTheme.Typography.caption)
                    .anchorSecondaryText()
                    .multilineTextAlignment(.center)

                PolicySection(
                    title: String(localized: "Acceptance of Terms"),
                    content: String(
                        localized: "By using Anchor, you agree to these terms of service.")
                )

                PolicySection(
                    title: String(localized: "Service Description"),
                    content: String(
                        localized:
                            "Anchor provides AI-powered emotional support through voice conversations. It is NOT a replacement for professional mental health care."
                    )
                )

                PolicySection(
                    title: String(localized: "Age Requirement"),
                    content: String(localized: "You must be 18 years or older to use Anchor.")
                )

                PolicySection(
                    title: String(localized: "Disclaimer"),
                    content: String(
                        localized:
                            "Anchor is not a medical device and does not provide medical advice, diagnosis, or treatment. Always seek the advice of a qualified healthcare provider."
                    )
                )

                PolicySection(
                    title: String(localized: "Limitation of Liability"),
                    content: String(
                        localized:
                            "We are not liable for any decisions or actions taken based on conversations with Anchor."
                    )
                )

                PolicySection(
                    title: String(localized: "Subscription Terms"),
                    content: String(
                        localized:
                            "Subscriptions auto-renew unless cancelled. You can cancel anytime through your App Store account settings."
                    )
                )
            }
            .padding(.horizontal, 24)
            .padding(.vertical)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle(String(localized: "Terms of Service"))
        .navigationBarTitleDisplayMode(.inline)
        .anchorScreenBackground()
    }
}

// MARK: - Safety Guidelines View
struct SafetyGuidelinesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 16) {
                Text(String(localized: "Safety Guidelines"))
                    .font(AnchorTheme.Typography.title)
                    .anchorPrimaryText()
                    .multilineTextAlignment(.center)

                PolicySection(
                    title: String(localized: "When to Use Anchor"),
                    content: String(
                        localized:
                            "Anchor is designed for:\n• Emotional support during stressful times\n• Processing daily challenges\n• Exploring feelings and emotions\n• General mental wellness"
                    )
                )

                PolicySection(
                    title: String(localized: "When NOT to Use Anchor"),
                    content: String(
                        localized:
                            "Do NOT rely on Anchor for:\n• Medical emergencies\n• Crisis situations\n• Suicidal thoughts or self-harm urges\n• Severe mental health conditions"
                    )
                )

                PolicySection(
                    title: String(localized: "Crisis Resources"),
                    content: String(
                        localized:
                            "If you're in crisis, contact:\n• 988 - Suicide & Crisis Lifeline\n• 911 - Emergency services\n• Crisis Text Line: Text HOME to 741741"
                    )
                )

                PolicySection(
                    title: String(localized: "Seeking Professional Help"),
                    content: String(
                        localized:
                            "Consider professional help if you:\n• Have persistent symptoms\n• Feel unable to cope\n• Experience thoughts of self-harm\n• Need medication management"
                    )
                )

                PolicySection(
                    title: String(localized: "Best Practices"),
                    content: String(
                        localized:
                            "• Use Anchor in a quiet, private space\n• Be honest about your feelings\n• Take breaks if needed\n• Seek professional care when appropriate"
                    )
                )
            }
            .padding(.horizontal, 24)
            .padding(.vertical)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle(String(localized: "Safety Guidelines"))
        .navigationBarTitleDisplayMode(.inline)
        .anchorScreenBackground()
    }
}

// MARK: - About View
struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(AnchorTheme.Colors.sageLeaf)
                    .padding()
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text(String(localized: "Anchor"))
                        .font(AnchorTheme.Typography.title)
                        .anchorPrimaryText()

                    Text(String(localized: "Version 1.0.0"))
                        .font(AnchorTheme.Typography.subheadline)
                        .anchorSecondaryText()
                }

                Text(String(localized: "AI-Powered Emotional Support"))
                    .font(AnchorTheme.Typography.subheadline)
                    .anchorSecondaryText()
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 16) {
                    PolicySection(
                        title: String(localized: "Our Mission"),
                        content: String(
                            localized:
                                "To provide accessible, private, and immediate emotional support to anyone who needs it, anytime."
                        )
                    )

                    PolicySection(
                        title: String(localized: "Our Values"),
                        content: String(
                            localized:
                                "• Privacy First\n• User Safety\n• Accessibility\n• Ethical AI\n• Compassionate Care"
                        )
                    )

                    PolicySection(
                        title: String(localized: "Contact Us"),
                        content: String.localizedStringWithFormat(
                            String(localized: "Email: %@\n\nWe'd love to hear from you!"),
                            SupportContact.email
                        )
                    )
                }
                .padding(.horizontal)
            }
            .padding(.horizontal, 24)
            .padding(.vertical)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle(String(localized: "About"))
        .navigationBarTitleDisplayMode(.inline)
        .anchorScreenBackground()
    }
}

// MARK: - Helper Components
struct PolicySection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AnchorTheme.Typography.subheadline)
                .anchorPrimaryText()

            Text(content)
                .font(AnchorTheme.Typography.bodyText)
                .anchorSecondaryText()
        }
        .anchorCard()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Share Sheet (UIActivityViewController wrapper)
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Previews
#Preview("Privacy Policy") {
    NavigationStack {
        PrivacyPolicyView()
    }
}

#Preview("Terms of Service") {
    NavigationStack {
        TermsOfServiceView()
    }
}

// MARK: - Post-Session Reflection View
struct PostSessionReflectionView: View {
    let prompt: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(AnchorTheme.Colors.warmStone)
                .frame(width: 36, height: 5)
                .padding(.top, 12)

            Image(systemName: "leaf.fill")
                .font(.system(size: 32))
                .foregroundStyle(AnchorTheme.Colors.sageLeaf)
                .accessibilityHidden(true)

            Text(String(localized: "A moment to reflect"))
                .font(AnchorTheme.Typography.headline)
                .anchorPrimaryText()

            Text(prompt)
                .font(AnchorTheme.Typography.bodyText)
                .anchorSecondaryText()
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)

            Text(
                String(
                    localized:
                        "You don't need to write anything down — just sit with it for a moment.")
            )
            .font(AnchorTheme.Typography.caption)
            .anchorSecondaryText()
            .multilineTextAlignment(.center)
            .padding(.horizontal)

            Spacer()

            Button(action: onDismiss) {
                Text(String(localized: "Done"))
                    .font(AnchorTheme.Typography.bodyText.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AnchorTheme.Colors.sageLeaf)
                    .foregroundStyle(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AnchorTheme.Colors.softParchment.ignoresSafeArea())
    }
}

// MARK: - Crisis Interruption View
struct CrisisInterruptionView: View {
    let onViewResources: () -> Void
    let onContinue: () -> Void
    let onEnd: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(AnchorTheme.Colors.warmStone)
                .frame(width: 36, height: 5)
                .padding(.top, 12)

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundStyle(AnchorTheme.Colors.crisisRed)
                .accessibilityHidden(true)

            Text(String(localized: "Your safety matters"))
                .font(AnchorTheme.Typography.headline)
                .anchorPrimaryText()

            Text(
                String(
                    localized:
                        "It sounds like you may be going through something intense. If you're in danger or need immediate help, please contact emergency services."
                )
            )
            .font(AnchorTheme.Typography.bodyText)
            .anchorSecondaryText()
            .multilineTextAlignment(.center)
            .padding(.horizontal)

            Button(action: onViewResources) {
                Text(String(localized: "View Emergency Resources"))
                    .font(AnchorTheme.Typography.subheadline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(
                AnchorPillButtonStyle(
                    background: AnchorTheme.Colors.crisisRed,
                    foreground: AnchorTheme.Colors.softParchment)
            )
            .padding(.horizontal, 24)
            .accessibilityLabel(String(localized: "View emergency resources"))
            .accessibilityHint(String(localized: "See crisis hotlines and support options"))
            .accessibilityIdentifier("crisis.viewResources")

            Button(action: onContinue) {
                Text(String(localized: "Continue Session"))
                    .font(AnchorTheme.Typography.subheadline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(
                AnchorPillButtonStyle(
                    background: AnchorTheme.Colors.warmStone,
                    foreground: AnchorTheme.Colors.quietInk)
            )
            .padding(.horizontal, 24)
            .accessibilityLabel(String(localized: "Continue session"))
            .accessibilityHint(String(localized: "Resume the conversation"))
            .accessibilityIdentifier("crisis.continue")

            Button(action: onEnd) {
                Text(String(localized: "End Session"))
                    .font(AnchorTheme.Typography.caption)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(
                AnchorPillButtonStyle(
                    background: AnchorTheme.Colors.warmSand.opacity(0.4),
                    foreground: AnchorTheme.Colors.quietInk)
            )
            .padding(.horizontal, 24)
            .accessibilityLabel(String(localized: "End session"))
            .accessibilityHint(String(localized: "End the conversation and save"))
            .accessibilityIdentifier("crisis.end")

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AnchorTheme.Colors.softParchment.ignoresSafeArea())
    }
}

// MARK: - Session Summary & Celebration
struct SessionSummaryPayload: Identifiable {
    let sessionID: UUID
    let date: Date
    let duration: TimeInterval
    let moodBefore: Int?
    let moodAfter: Int?
    var topics: [String]
    var takeaway: String
    var observedMood: String
    var copingStrategies: [String]
    var suggestedFollowUp: String

    // Expanded note fields
    var narrativeSummary: String
    var moodStartDescription: String
    var moodEndDescription: String
    var moodShiftDescription: String
    var keyInsight: String
    var userQuotes: [String]
    var copingStrategiesExplored: [String]
    var actionItemsForTherapist: [String]
    var recurringPatternAlert: String
    var homework: String = ""
    var homeworkItems: [String] = []
    var completedHomeworkItems: [String] = []

    // v2 metadata + continuity
    var summarySchemaVersion: Int? = nil
    var summaryRawJSON: String = ""
    var sessionOrdinal: Int? = nil
    var primaryFocus: String = ""
    var relatedThemes: [String] = []

    // v2 mood detail
    var moodStartIntensity: Int? = nil
    var moodEndIntensity: Int? = nil
    var moodStartPhysicalSymptoms: [String] = []
    var moodEndPhysicalSymptoms: [String] = []

    // v2 patterning
    var patternRecognized: String = ""
    var recurringTopicsSnapshot: [String] = []
    var recurringTopicsTrend: String = ""

    // v2 coping detail
    var copingStrategiesAttempted: [String] = []
    var copingStrategiesWorked: [String] = []
    var copingStrategiesDidntWork: [String] = []

    // v2 progress + continuity
    var previousHomeworkAssigned: String = ""
    var previousHomeworkCompletion: String = ""
    var previousHomeworkReflection: String = ""
    var therapyGoalProgress: [String] = []
    var actionItemsForUser: [String] = []
    var continuityPeopleMentioned: [String] = []
    var continuityUpcomingEvents: [String] = []
    var continuityEnvironmentalFactors: [String] = []

    // v2 safety + clinical
    var crisisRiskDetectedByModel: Bool? = nil
    var crisisNotes: String = ""
    var protectiveFactors: [String] = []
    var safetyRecommendation: String = ""
    var dominantEmotions: [String] = []
    var primaryCopingStyle: String = ""
    var sessionEffectivenessSelfRating: Int? = nil

    var id: UUID { sessionID }

    var hasNotes: Bool {
        !observedMood.isEmpty
            || !copingStrategies.isEmpty
            || !suggestedFollowUp.isEmpty
            || !narrativeSummary.isEmpty
            || !moodStartDescription.isEmpty
            || !moodEndDescription.isEmpty
            || !moodShiftDescription.isEmpty
            || !keyInsight.isEmpty
            || !userQuotes.isEmpty
            || !copingStrategiesExplored.isEmpty
            || !actionItemsForTherapist.isEmpty
            || !recurringPatternAlert.isEmpty
            || !homework.isEmpty
            || !homeworkItems.isEmpty
            || !primaryFocus.isEmpty
            || !relatedThemes.isEmpty
            || moodStartIntensity != nil
            || moodEndIntensity != nil
            || !moodStartPhysicalSymptoms.isEmpty
            || !moodEndPhysicalSymptoms.isEmpty
            || !patternRecognized.isEmpty
            || !recurringTopicsSnapshot.isEmpty
            || !recurringTopicsTrend.isEmpty
            || !copingStrategiesAttempted.isEmpty
            || !copingStrategiesWorked.isEmpty
            || !copingStrategiesDidntWork.isEmpty
            || !previousHomeworkAssigned.isEmpty
            || !previousHomeworkCompletion.isEmpty
            || !previousHomeworkReflection.isEmpty
            || !therapyGoalProgress.isEmpty
            || !actionItemsForUser.isEmpty
            || !continuityPeopleMentioned.isEmpty
            || !continuityUpcomingEvents.isEmpty
            || !continuityEnvironmentalFactors.isEmpty
            || crisisRiskDetectedByModel != nil
            || !crisisNotes.isEmpty
            || !protectiveFactors.isEmpty
            || !safetyRecommendation.isEmpty
            || !dominantEmotions.isEmpty
            || !primaryCopingStyle.isEmpty
            || sessionEffectivenessSelfRating != nil
    }
}

struct CelebrationContent {
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
}

enum SummaryStatus: Equatable {
    case idle
    case summarizing
    case ready
    case failed(String)
}

extension SessionSummaryPayload {
    init(session: Session) {
        self.sessionID = session.id
        self.date = session.timestamp
        self.duration = session.duration
        self.moodBefore = session.moodBefore
        self.moodAfter = session.moodAfter
        self.topics = session.tags
        self.takeaway =
            session.summary.isEmpty
            ? String(localized: "Conversation with Anchor") : session.summary
        self.observedMood = session.observedMood ?? ""
        self.copingStrategies = session.copingStrategies ?? []
        self.suggestedFollowUp = session.suggestedFollowUp ?? ""
        self.narrativeSummary = session.narrativeSummary ?? ""
        self.moodStartDescription = session.moodStartDescription ?? ""
        self.moodEndDescription = session.moodEndDescription ?? ""
        self.moodShiftDescription = session.moodShiftDescription ?? ""
        self.keyInsight = session.keyInsight ?? ""
        self.userQuotes = session.userQuotes ?? []
        self.copingStrategiesExplored = session.copingStrategiesExplored ?? []
        self.actionItemsForTherapist = session.actionItemsForTherapist ?? []
        self.recurringPatternAlert = session.recurringPatternAlert ?? ""
        self.homework = session.homework ?? ""
        self.homeworkItems = session.homeworkItems ?? []
        self.completedHomeworkItems = session.completedHomeworkItems ?? []
        self.summarySchemaVersion = session.summarySchemaVersion
        self.summaryRawJSON = session.summaryRawJSON ?? ""
        self.sessionOrdinal = session.sessionOrdinal
        self.primaryFocus = session.primaryFocus ?? ""
        self.relatedThemes = session.relatedThemes ?? []
        self.moodStartIntensity = session.moodStartIntensity
        self.moodEndIntensity = session.moodEndIntensity
        self.moodStartPhysicalSymptoms = session.moodStartPhysicalSymptoms ?? []
        self.moodEndPhysicalSymptoms = session.moodEndPhysicalSymptoms ?? []
        self.patternRecognized = session.patternRecognized ?? ""
        self.recurringTopicsSnapshot = session.recurringTopicsSnapshot ?? []
        self.recurringTopicsTrend = session.recurringTopicsTrend ?? ""
        self.copingStrategiesAttempted = session.copingStrategiesAttempted ?? []
        self.copingStrategiesWorked = session.copingStrategiesWorked ?? []
        self.copingStrategiesDidntWork = session.copingStrategiesDidntWork ?? []
        self.previousHomeworkAssigned = session.previousHomeworkAssigned ?? ""
        self.previousHomeworkCompletion = session.previousHomeworkCompletion ?? ""
        self.previousHomeworkReflection = session.previousHomeworkReflection ?? ""
        self.therapyGoalProgress = session.therapyGoalProgress ?? []
        self.actionItemsForUser = session.actionItemsForUser ?? []
        self.continuityPeopleMentioned = session.continuityPeopleMentioned ?? []
        self.continuityUpcomingEvents = session.continuityUpcomingEvents ?? []
        self.continuityEnvironmentalFactors = session.continuityEnvironmentalFactors ?? []
        self.crisisRiskDetectedByModel = session.crisisRiskDetectedByModel
        self.crisisNotes = session.crisisNotes ?? ""
        self.protectiveFactors = session.protectiveFactors ?? []
        self.safetyRecommendation = session.safetyRecommendation ?? ""
        self.dominantEmotions = session.dominantEmotions ?? []
        self.primaryCopingStyle = session.primaryCopingStyle ?? ""
        self.sessionEffectivenessSelfRating = session.sessionEffectivenessSelfRating
    }
}

struct SessionCelebrationView: View {
    let content: CelebrationContent
    let onDismiss: () -> Void

    @State private var isVisible = false

    var body: some View {
        ZStack {
            AnchorTheme.Colors.softParchment
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: content.icon)
                    .font(.system(size: 40))
                    .foregroundColor(content.accent)
                    .scaleEffect(isVisible ? 1.0 : 0.85)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(.spring(response: 0.7, dampingFraction: 0.7), value: isVisible)
                    .accessibilityHidden(true)

                Text(content.title)
                    .font(AnchorTheme.Typography.headline)
                    .anchorPrimaryText()
                    .multilineTextAlignment(.center)

                Text(content.subtitle)
                    .font(AnchorTheme.Typography.subheadline)
                    .anchorSecondaryText()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            isVisible = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                onDismiss()
            }
        }
    }
}

struct SessionSummarySheetView: View {
    let payload: SessionSummaryPayload
    let reflectionPrompt: String
    let summaryStatus: SummaryStatus
    let onDone: () -> Void

    @State private var shareImage: UIImage?
    @State private var showingShare = false
    @State private var shareURL: URL?
    @State private var preparingShare = false
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if summaryStatus != .ready && summaryStatus != .idle {
                        SummaryStatusBanner(status: summaryStatus)
                    }

                    SessionSummaryCardView(payload: payload, summaryStatus: summaryStatus)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "A moment to reflect"))
                            .font(AnchorTheme.Typography.subheadline)
                            .anchorPrimaryText()

                        Text(reflectionPrompt)
                            .font(AnchorTheme.Typography.bodyText)
                            .anchorSecondaryText()
                    }
                    .anchorCard()

                    SessionNotesCardView(
                        payload: payload,
                        summaryStatus: summaryStatus
                    )

                    HStack(spacing: 12) {
                        Button {
                            shareCard()
                        } label: {
                            Label(
                                String(localized: "Share Card"),
                                systemImage: "square.and.arrow.up"
                            )
                            .font(AnchorTheme.Typography.subheadline)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(
                            AnchorPillButtonStyle(
                                background: AnchorTheme.Colors.sageLeaf,
                                foreground: AnchorTheme.Colors.softParchment))
                        .disabled(preparingShare)

                        if payload.hasNotes {
                            Button {
                                sharePDF()
                            } label: {
                                Label(
                                    String(localized: "Export PDF"),
                                    systemImage: "arrow.down.doc"
                                )
                                .font(AnchorTheme.Typography.subheadline)
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(
                                AnchorPillButtonStyle(
                                    background: AnchorTheme.Colors.warmStone,
                                    foreground: AnchorTheme.Colors.quietInk))
                            .disabled(preparingShare)
                        }
                    }
                }
                .padding(24)
            }
            .navigationTitle(String(localized: "Session Summary"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "Done")) {
                        onDone()
                    }
                }
            }
        }
        .anchorScreenBackground()
        .sheet(isPresented: $showingShare) {
            if let shareURL {
                ShareSheet(activityItems: [shareURL])
            } else if let shareImage {
                ShareSheet(activityItems: [shareImage])
            }
        }
    }

    @MainActor
    private func shareCard() {
        shareURL = nil
        let card = SessionSummaryShareCardView(payload: payload, summaryStatus: summaryStatus)
            .frame(width: 380)
            .padding(20)
            .background(Color.white)

        let renderer = ImageRenderer(content: card)
        renderer.scale = max(displayScale, 3)
        shareImage = renderer.uiImage
        showingShare = shareImage != nil
    }

    @MainActor
    private func sharePDF() {
        guard !preparingShare else { return }
        preparingShare = true
        shareImage = nil
        shareURL = nil
        let currentPayload = payload
        DispatchQueue.global(qos: .userInitiated).async {
            let url = SessionPDFExporter.generatePDF(from: currentPayload)
            DispatchQueue.main.async {
                preparingShare = false
                shareURL = url
                showingShare = url != nil
            }
        }
    }
}

enum SessionCardRenderStyle {
    case inApp
    case export
}

struct BrandedShareCardContainer<Content: View>: View {
    let payload: SessionSummaryPayload
    let reportType: String
    @ViewBuilder let content: Content

    private var wordmarkImage: UIImage? {
        ExportBrandImageProvider.wordmarkImage()
    }

    private var markImage: UIImage? {
        ExportBrandImageProvider.markImage()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Rectangle()
                .fill(AnchorTheme.Colors.sageLeaf.opacity(0.55))
                .frame(height: 2)

            HStack(alignment: .top, spacing: 12) {
                Group {
                    if let wordmarkImage {
                        Image(uiImage: wordmarkImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 30, alignment: .leading)
                    } else {
                        Text(String(localized: "Anchor"))
                            .font(AnchorTheme.Typography.heading(size: 25))
                            .foregroundColor(AnchorTheme.Colors.sageLeaf)
                    }
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(reportType)
                        .font(AnchorTheme.Typography.subheadline)
                        .foregroundColor(AnchorTheme.Colors.quietInk)
                    .anchorSecondaryText()
                    Text(payload.date.formatted(date: .abbreviated, time: .shortened))
                        .font(AnchorTheme.Typography.caption)
                        .anchorSecondaryText()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AnchorTheme.Colors.softParchment)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AnchorTheme.Colors.warmStone, lineWidth: 1)
                )
            }

            Rectangle()
                .fill(AnchorTheme.Colors.warmStone.opacity(0.8))
                .frame(height: 1)

            content

            Rectangle()
                .fill(AnchorTheme.Colors.warmStone.opacity(0.8))
                .frame(height: 1)

            HStack(alignment: .top, spacing: 8) {
                Group {
                    if let markImage {
                        Image(uiImage: markImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AnchorTheme.Colors.sageLeaf)
                    }
                }
                .accessibilityHidden(true)

                Text(String(localized: "Supportive notes — not a clinical record."))
                    .font(AnchorTheme.Typography.smallCaption)
                    .anchorSecondaryText()

                Spacer()

                Text(String(localized: "(No transcripts included)"))
                    .font(AnchorTheme.Typography.smallCaption)
                    .anchorSecondaryText()
            }
        }
        .padding(22)
        .background(
            Color.white
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(AnchorTheme.Colors.warmStone, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct SessionSummaryShareCardView: View {
    let payload: SessionSummaryPayload
    var summaryStatus: SummaryStatus = .ready

    var body: some View {
        BrandedShareCardContainer(
            payload: payload,
            reportType: String(localized: "Therapist Support Report")
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Text(String(localized: "Session Summary"))
                    .font(AnchorTheme.Typography.heading(size: 38, weight: .semibold))
                    .foregroundColor(AnchorTheme.Colors.quietInk)

                HStack(spacing: 10) {
                    ReportMetricCell(
                        label: String(localized: "Duration"),
                        value: formattedDuration(payload.duration)
                    )
                    ReportMetricCell(
                        label: String(localized: "Mood"),
                        value: moodMetricText
                    )
                }

                ReportTextSection(
                    title: String(localized: "Topics discussed"),
                    bodyText: topicsText
                )

                ReportTextSection(
                    title: String(localized: "Takeaway"),
                    bodyText: takeawayText
                )

                ReportTextSection(
                    title: String(localized: "Next step"),
                    bodyText: nextStepText
                )
            }
        }
    }

    private var topicsText: String {
        guard !payload.topics.isEmpty else {
            return String(localized: "Topics will appear as Anchor learns your sessions.")
        }
        return payload.topics.prefix(6).joined(separator: " • ")
    }

    var moodMetricText: String {
        guard let before = payload.moodBefore, let after = payload.moodAfter else {
            return String(localized: "—")
        }
        return String.localizedStringWithFormat(
            String(localized: "%lld/5 → %lld/5"),
            Int64(before),
            Int64(after)
        )
    }

    private var takeawayText: String {
        if summaryStatus == .summarizing {
            return String(localized: "Generating your takeaway…")
        }
        if !payload.takeaway.isEmpty {
            return payload.takeaway
        }
        return String(localized: "Conversation with Anchor")
    }

    private var nextStepText: String {
        if !payload.suggestedFollowUp.isEmpty {
            return payload.suggestedFollowUp
        }
        return String(localized: "No next step recorded yet.")
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        if minutes > 0 {
            return String.localizedStringWithFormat(
                String(localized: "%lldm %llds"),
                Int64(minutes),
                Int64(remainingSeconds)
            )
        }
        return String.localizedStringWithFormat(String(localized: "%llds"), Int64(remainingSeconds))
    }
}

struct SessionNotesShareCardView: View {
    let payload: SessionSummaryPayload
    var summaryStatus: SummaryStatus = .ready

    var body: some View {
        BrandedShareCardContainer(
            payload: payload,
            reportType: String(localized: "Therapist Support Report")
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Text(String(localized: "Session Notes"))
                    .font(AnchorTheme.Typography.heading(size: 34, weight: .semibold))
                    .foregroundColor(AnchorTheme.Colors.quietInk)

                ReportTextSection(
                    title: String(localized: "What we discussed"),
                    bodyText: discussedText
                )

                if !payload.primaryFocus.isEmpty || !payload.relatedThemes.isEmpty {
                    ReportTextSection(
                        title: String(localized: "Primary focus"),
                        bodyText: focusText
                    )
                }

                if !moodJourneyText.isEmpty {
                    ReportTextSection(
                        title: String(localized: "Mood journey"),
                        bodyText: moodJourneyText
                    )
                }

                if !payload.keyInsight.isEmpty {
                    ReportTextSection(
                        title: String(localized: "Key insight"),
                        bodyText: payload.keyInsight
                    )
                }

                if !homePracticeText.isEmpty {
                    ReportTextSection(
                        title: String(localized: "Home practice"),
                        bodyText: homePracticeText
                    )
                }

                if !payload.actionItemsForUser.isEmpty {
                    ReportTextSection(
                        title: String(localized: "Action items for you"),
                        bodyText: payload.actionItemsForUser.map { "• \($0)" }.joined(separator: "\n")
                    )
                }

                if !payload.patternRecognized.isEmpty || !payload.recurringPatternAlert.isEmpty {
                    ReportTextSection(
                        title: String(localized: "Pattern insight"),
                        bodyText: patternText
                    )
                }

                if !payload.copingStrategiesWorked.isEmpty || !payload.copingStrategiesDidntWork.isEmpty {
                    ReportTextSection(
                        title: String(localized: "Coping outcomes"),
                        bodyText: copingOutcomeText
                    )
                }

                if payload.crisisRiskDetectedByModel != nil || !payload.safetyRecommendation.isEmpty {
                    ReportTextSection(
                        title: String(localized: "Safety"),
                        bodyText: safetyText
                    )
                }

                Text(String(localized: "View full notes in PDF export."))
                    .font(AnchorTheme.Typography.caption)
                    .foregroundColor(AnchorTheme.Colors.quietInkSecondary)
            }
        }
    }

    private var discussedText: String {
        if !payload.narrativeSummary.isEmpty {
            return payload.narrativeSummary
        }
        if !payload.takeaway.isEmpty {
            return payload.takeaway
        }
        return String(localized: "No notes available for this session.")
    }

    private var moodJourneyText: String {
        var lines: [String] = []
        if !payload.moodStartDescription.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Start: %@"),
                    payload.moodStartDescription
                )
            )
        }
        if !payload.moodEndDescription.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "End: %@"),
                    payload.moodEndDescription
                )
            )
        }
        if !payload.moodShiftDescription.isEmpty {
            lines.append(payload.moodShiftDescription)
        }
        if lines.isEmpty, !payload.observedMood.isEmpty {
            lines.append(payload.observedMood)
        }
        return lines.joined(separator: "\n")
    }

    private var focusText: String {
        var lines: [String] = []
        if !payload.primaryFocus.isEmpty {
            lines.append(payload.primaryFocus)
        }
        if !payload.relatedThemes.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Themes: %@"),
                    payload.relatedThemes.joined(separator: ", ")
                )
            )
        }
        return lines.joined(separator: "\n")
    }

    private var homePracticeText: String {
        if !payload.homeworkItems.isEmpty {
            let completedItems = Set(payload.completedHomeworkItems)
            return payload.homeworkItems.map { item in
                "\(completedItems.contains(item) ? "[done]" : "[ ]") \(item)"
            }.joined(separator: "\n")
        }
        return payload.homework
    }

    private var patternText: String {
        var lines: [String] = []
        if !payload.patternRecognized.isEmpty {
            lines.append(payload.patternRecognized)
        }
        if !payload.recurringPatternAlert.isEmpty {
            lines.append(payload.recurringPatternAlert)
        }
        if !payload.recurringTopicsSnapshot.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Recurring: %@"),
                    payload.recurringTopicsSnapshot.joined(separator: ", ")
                )
            )
        }
        if !payload.recurringTopicsTrend.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Trend: %@"),
                    payload.recurringTopicsTrend
                )
            )
        }
        return lines.joined(separator: "\n")
    }

    private var copingOutcomeText: String {
        var lines: [String] = []
        if !payload.copingStrategiesWorked.isEmpty {
            lines.append(String(localized: "Helped:"))
            lines.append(contentsOf: payload.copingStrategiesWorked.map { "• \($0)" })
        }
        if !payload.copingStrategiesDidntWork.isEmpty {
            if !lines.isEmpty {
                lines.append("")
            }
            lines.append(String(localized: "Did not help:"))
            lines.append(contentsOf: payload.copingStrategiesDidntWork.map { "• \($0)" })
        }
        return lines.joined(separator: "\n")
    }

    private var safetyText: String {
        var lines: [String] = []
        if let risk = payload.crisisRiskDetectedByModel {
            lines.append(
                risk ? String(localized: "Risk detected: Yes") : String(localized: "Risk detected: No")
            )
        }
        if !payload.safetyRecommendation.isEmpty {
            lines.append(payload.safetyRecommendation)
        }
        return lines.joined(separator: "\n")
    }
}

private struct ReportMetricCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AnchorTheme.Typography.caption)
                .foregroundColor(AnchorTheme.Colors.quietInkSecondary)
            Text(value)
                .font(AnchorTheme.Typography.body(size: 22, weight: .semibold, relativeTo: .title3))
                .foregroundColor(AnchorTheme.Colors.quietInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AnchorTheme.Colors.softParchment.opacity(0.65))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AnchorTheme.Colors.warmStone, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct ReportTextSection: View {
    let title: String
    let bodyText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AnchorTheme.Typography.caption)
                .foregroundColor(AnchorTheme.Colors.quietInkSecondary)
            Text(bodyText)
                .font(AnchorTheme.Typography.bodyText)
                .foregroundColor(AnchorTheme.Colors.quietInk)
        }
    }
}

struct SessionSummaryCardView: View {
    let payload: SessionSummaryPayload
    var summaryStatus: SummaryStatus = .ready
    var renderStyle: SessionCardRenderStyle = .inApp

    var body: some View {
        let content = VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(String(localized: "Session Summary"))
                    .font(AnchorTheme.Typography.headline)
                    .anchorPrimaryText()
                Spacer()
                Text(payload.date.formatted(date: .abbreviated, time: .shortened))
                    .font(AnchorTheme.Typography.caption)
                    .anchorSecondaryText()
            }

            HStack(spacing: 16) {
                SummaryStat(
                    label: String(localized: "Duration"), value: formattedDuration(payload.duration)
                )
                SummaryStat(label: String(localized: "Mood"), value: moodShiftText)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Topics discussed"))
                    .font(AnchorTheme.Typography.caption)
                    .anchorSecondaryText()

                if payload.topics.isEmpty {
                    Text(String(localized: "Topics will appear as Anchor learns your sessions."))
                        .font(AnchorTheme.Typography.bodyText)
                        .anchorSecondaryText()
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(payload.topics.prefix(6), id: \.self) { topic in
                            Text(topic)
                                .font(AnchorTheme.Typography.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AnchorTheme.Colors.warmStone)
                                .foregroundColor(AnchorTheme.Colors.quietInk)
                                .cornerRadius(14)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Takeaway"))
                    .font(AnchorTheme.Typography.caption)
                    .anchorSecondaryText()
                Text(
                    String.localizedStringWithFormat(
                        String(localized: "“%@”"),
                        takeawayText
                    )
                )
                .font(AnchorTheme.Typography.bodyText)
                .anchorPrimaryText()
            }

            if !payload.suggestedFollowUp.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Next step"))
                        .font(AnchorTheme.Typography.caption)
                        .anchorSecondaryText()
                    Text(payload.suggestedFollowUp)
                        .font(AnchorTheme.Typography.bodyText)
                        .anchorSecondaryText()
                }
            }
        }

        Group {
            if renderStyle == .inApp {
                content.anchorCard()
            } else {
                content
            }
        }
    }

    private var moodShiftText: String {
        guard let before = payload.moodBefore, let after = payload.moodAfter else {
            return String(localized: "—")
        }
        return String.localizedStringWithFormat(
            String(localized: "%@ → %@"),
            MoodEmoji.emoji(for: before),
            MoodEmoji.emoji(for: after)
        )
    }

    private var takeawayText: String {
        if summaryStatus == .summarizing {
            return String(localized: "Generating your takeaway…")
        }
        if !payload.takeaway.isEmpty {
            return payload.takeaway
        }
        return String(localized: "Conversation with Anchor")
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        if minutes > 0 {
            return String.localizedStringWithFormat(
                String(localized: "%lldm %llds"),
                Int64(minutes),
                Int64(remainingSeconds)
            )
        }
        return String.localizedStringWithFormat(String(localized: "%llds"), Int64(remainingSeconds))
    }
}

struct WeeklySummaryCardView: View {
    let payload: WeeklySummaryPayload

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(String(localized: "Weekly Check-in"))
                    .font(AnchorTheme.Typography.headline)
                    .anchorPrimaryText()
                Spacer()
                Text(weekLabel)
                    .font(AnchorTheme.Typography.caption)
                    .anchorSecondaryText()
            }

            HStack(spacing: 16) {
                SummaryStat(
                    label: String(localized: "Sessions"), value: String(payload.sessionCount))
                SummaryStat(label: String(localized: "Mood avg"), value: moodAverageText)
                SummaryStat(label: String(localized: "Streak"), value: streakText)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Top topics"))
                    .font(AnchorTheme.Typography.caption)
                    .anchorSecondaryText()

                if payload.topTopics.isEmpty {
                    Text(String(localized: "Top topics: —"))
                        .font(AnchorTheme.Typography.bodyText)
                        .anchorSecondaryText()
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(payload.topTopics, id: \.self) { topic in
                            Text(topic)
                                .font(AnchorTheme.Typography.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AnchorTheme.Colors.warmStone)
                                .foregroundColor(AnchorTheme.Colors.quietInk)
                                .cornerRadius(14)
                        }
                    }
                }
            }

            Text(String(localized: "(No transcripts included)"))
                .font(AnchorTheme.Typography.caption)
                .anchorSecondaryText()
        }
        .anchorCard()
    }

    private var weekLabel: String {
        let start = payload.weekStart.formatted(date: .abbreviated, time: .omitted)
        return String.localizedStringWithFormat(String(localized: "Week of %@"), start)
    }

    private var moodAverageText: String {
        if let before = payload.averageMoodBefore, let after = payload.averageMoodAfter {
            let beforeText = String(format: "%.1f", before)
            let afterText = String(format: "%.1f", after)
            return String.localizedStringWithFormat(
                String(localized: "%@ → %@"), beforeText, afterText)
        }
        if let after = payload.averageMoodAfter {
            let afterText = String(format: "%.1f", after)
            return afterText
        }
        return String(localized: "—")
    }

    private var streakText: String {
        guard let streak = payload.currentStreak, streak > 0 else {
            return String(localized: "—")
        }
        return String.localizedStringWithFormat(String(localized: "%lldd"), Int64(streak))
    }
}

struct SummaryStatusBanner: View {
    let status: SummaryStatus

    var body: some View {
        HStack(spacing: 12) {
            switch status {
            case .summarizing:
                ProgressView()
                    .tint(AnchorTheme.Colors.sageLeaf)
                Text(String(localized: "Finalizing your summary…"))
                    .font(AnchorTheme.Typography.caption)
                    .anchorSecondaryText()
            case .failed(let message):
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(AnchorTheme.Colors.warmSand)
                    .accessibilityHidden(true)
                Text(message)
                    .font(AnchorTheme.Typography.caption)
                    .anchorSecondaryText()
            default:
                EmptyView()
            }
            Spacer()
        }
        .anchorCard()
    }
}

struct SessionNotesCardView: View {
    let payload: SessionSummaryPayload
    var summaryStatus: SummaryStatus = .ready
    var renderStyle: SessionCardRenderStyle = .inApp

    private var hasAnyContent: Bool {
        !payload.narrativeSummary.isEmpty
            || !payload.observedMood.isEmpty
            || !payload.moodStartDescription.isEmpty
            || !payload.moodEndDescription.isEmpty
            || !payload.moodShiftDescription.isEmpty
            || payload.moodStartIntensity != nil
            || payload.moodEndIntensity != nil
            || !payload.moodStartPhysicalSymptoms.isEmpty
            || !payload.moodEndPhysicalSymptoms.isEmpty
            || !payload.keyInsight.isEmpty
            || !payload.userQuotes.isEmpty
            || !payload.copingStrategiesExplored.isEmpty
            || !payload.copingStrategies.isEmpty
            || !payload.copingStrategiesAttempted.isEmpty
            || !payload.copingStrategiesWorked.isEmpty
            || !payload.copingStrategiesDidntWork.isEmpty
            || !payload.actionItemsForTherapist.isEmpty
            || !payload.actionItemsForUser.isEmpty
            || !payload.recurringPatternAlert.isEmpty
            || !payload.patternRecognized.isEmpty
            || !payload.primaryFocus.isEmpty
            || !payload.relatedThemes.isEmpty
            || !payload.recurringTopicsSnapshot.isEmpty
            || !payload.recurringTopicsTrend.isEmpty
            || !payload.suggestedFollowUp.isEmpty
            || !payload.homework.isEmpty
            || !payload.homeworkItems.isEmpty
            || !payload.previousHomeworkAssigned.isEmpty
            || !payload.previousHomeworkCompletion.isEmpty
            || !payload.previousHomeworkReflection.isEmpty
            || !payload.therapyGoalProgress.isEmpty
            || !payload.continuityPeopleMentioned.isEmpty
            || !payload.continuityUpcomingEvents.isEmpty
            || !payload.continuityEnvironmentalFactors.isEmpty
            || payload.crisisRiskDetectedByModel != nil
            || !payload.crisisNotes.isEmpty
            || !payload.protectiveFactors.isEmpty
            || !payload.safetyRecommendation.isEmpty
            || !payload.dominantEmotions.isEmpty
            || !payload.primaryCopingStyle.isEmpty
            || payload.sessionEffectivenessSelfRating != nil
    }

    @State private var notesAppeared = false

    var body: some View {
        let content = VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "Session Notes"))
                .font(AnchorTheme.Typography.headline)
                .anchorPrimaryText()

            if hasAnyContent {
                noteSections
                    .opacity(notesAppeared ? 1 : 0)
                    .offset(y: notesAppeared ? 0 : 8)
                    .animation(.easeOut(duration: 0.35), value: notesAppeared)

                Text(String(localized: "Supportive notes — not a clinical record."))
                    .font(AnchorTheme.Typography.smallCaption)
                    .anchorSecondaryText()
            } else {
                Text(emptyStateText)
                    .font(AnchorTheme.Typography.caption)
                    .anchorSecondaryText()
            }
        }

        Group {
            if renderStyle == .inApp {
                content.anchorCard()
            } else {
                content
            }
        }
        .onAppear { notesAppeared = true }
    }

    @ViewBuilder
    private var noteSections: some View {
        // ── What We Discussed ───────────────────────────────
        if !payload.narrativeSummary.isEmpty {
            NoteSection(title: String(localized: "What we discussed"), icon: "text.quote") {
                CollapsibleNoteText(
                    payload.narrativeSummary,
                    collapsedLineLimit: 5
                )
            }
            NoteDivider()
        }

        // ── Focus & Themes ──────────────────────────────────
        if !payload.primaryFocus.isEmpty || !payload.relatedThemes.isEmpty {
            NoteSection(title: String(localized: "Primary focus"), icon: "scope") {
                VStack(alignment: .leading, spacing: 8) {
                    if !payload.primaryFocus.isEmpty {
                        Text(payload.primaryFocus)
                            .font(AnchorTheme.Typography.bodyText)
                            .anchorPrimaryText()
                    }
                    if !payload.relatedThemes.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(payload.relatedThemes, id: \.self) { theme in
                                Text(theme)
                                    .font(AnchorTheme.Typography.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(AnchorTheme.Colors.warmStone)
                                    .foregroundColor(AnchorTheme.Colors.quietInk)
                                    .cornerRadius(14)
                            }
                        }
                    }
                }
            }
            NoteDivider()
        }

        // ── Mood Journey ────────────────────────────────────
        if !payload.moodStartDescription.isEmpty || !payload.moodEndDescription.isEmpty {
            NoteSection(title: String(localized: "Mood journey"), icon: "heart.text.square") {
                VStack(alignment: .leading, spacing: 8) {
                    if !payload.moodStartDescription.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Text(String(localized: "Start"))
                                .font(AnchorTheme.Typography.caption)
                                .foregroundColor(AnchorTheme.Colors.warmSand)
                                .frame(width: 40, alignment: .leading)
                            CollapsibleNoteText(
                                payload.moodStartDescription,
                                collapsedLineLimit: 3
                            )
                        }
                        if let intensity = payload.moodStartIntensity {
                            Text(
                                String.localizedStringWithFormat(
                                    String(localized: "Start intensity: %lld/10"),
                                    Int64(intensity)
                                )
                            )
                            .font(AnchorTheme.Typography.caption)
                            .anchorSecondaryText()
                            .padding(.leading, 48)
                        }
                        if !payload.moodStartPhysicalSymptoms.isEmpty {
                            Text(
                                String.localizedStringWithFormat(
                                    String(localized: "Start physical cues: %@"),
                                    payload.moodStartPhysicalSymptoms.joined(separator: ", ")
                                )
                            )
                            .font(AnchorTheme.Typography.caption)
                            .anchorSecondaryText()
                            .padding(.leading, 48)
                        }
                    }
                    if !payload.moodEndDescription.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Text(String(localized: "End"))
                                .font(AnchorTheme.Typography.caption)
                                .foregroundColor(AnchorTheme.Colors.sageLeaf)
                                .frame(width: 40, alignment: .leading)
                            CollapsibleNoteText(
                                payload.moodEndDescription,
                                collapsedLineLimit: 3
                            )
                        }
                        if let intensity = payload.moodEndIntensity {
                            Text(
                                String.localizedStringWithFormat(
                                    String(localized: "End intensity: %lld/10"),
                                    Int64(intensity)
                                )
                            )
                            .font(AnchorTheme.Typography.caption)
                            .anchorSecondaryText()
                            .padding(.leading, 48)
                        }
                        if !payload.moodEndPhysicalSymptoms.isEmpty {
                            Text(
                                String.localizedStringWithFormat(
                                    String(localized: "End physical cues: %@"),
                                    payload.moodEndPhysicalSymptoms.joined(separator: ", ")
                                )
                            )
                            .font(AnchorTheme.Typography.caption)
                            .anchorSecondaryText()
                            .padding(.leading, 48)
                        }
                    }
                    if !payload.moodShiftDescription.isEmpty {
                        CollapsibleNoteText(
                            payload.moodShiftDescription,
                            collapsedLineLimit: 3,
                            useCaptionFont: true
                        )
                        .padding(.top, 4)
                    }
                }
            }
            NoteDivider()
        } else if !payload.observedMood.isEmpty {
            // Legacy fallback for old sessions
            NoteSection(title: String(localized: "Observed mood"), icon: "heart.text.square") {
                Text(payload.observedMood)
                    .font(AnchorTheme.Typography.bodyText)
                    .anchorPrimaryText()
            }
            NoteDivider()
        }

        // ── Key Insight ─────────────────────────────────────
        if !payload.keyInsight.isEmpty {
            NoteSection(title: String(localized: "Key insight"), icon: "lightbulb") {
                VStack(alignment: .leading, spacing: 8) {
                    CollapsibleNoteText(
                        payload.keyInsight,
                        collapsedLineLimit: 4
                    )

                    ForEach(payload.userQuotes, id: \.self) { quote in
                        CollapsibleNoteText(
                            String.localizedStringWithFormat(
                                String(localized: "\u{201C}%@\u{201D}"), quote),
                            collapsedLineLimit: 3,
                            italic: true
                        )
                    }
                }
            }
            NoteDivider()
        }

        // ── Coping Strategies ───────────────────────────────
        if !payload.copingStrategiesAttempted.isEmpty
            || !payload.copingStrategiesWorked.isEmpty
            || !payload.copingStrategiesDidntWork.isEmpty
        {
            NoteSection(title: String(localized: "Coping strategies"), icon: "shield.checkered") {
                VStack(alignment: .leading, spacing: 8) {
                    if !payload.copingStrategiesAttempted.isEmpty {
                        Text(String(localized: "Attempted"))
                            .font(AnchorTheme.Typography.caption)
                            .anchorSecondaryText()
                        ForEach(payload.copingStrategiesAttempted, id: \.self) { strategy in
                            Text("• \(strategy)")
                                .font(AnchorTheme.Typography.bodyText)
                                .anchorSecondaryText()
                        }
                    }
                    if !payload.copingStrategiesWorked.isEmpty {
                        Text(String(localized: "What helped"))
                            .font(AnchorTheme.Typography.caption)
                            .foregroundColor(AnchorTheme.Colors.sageLeaf)
                            .padding(.top, 4)
                        ForEach(payload.copingStrategiesWorked, id: \.self) { strategy in
                            Text("• \(strategy)")
                                .font(AnchorTheme.Typography.bodyText)
                                .anchorSecondaryText()
                        }
                    }
                    if !payload.copingStrategiesDidntWork.isEmpty {
                        Text(String(localized: "What did not help"))
                            .font(AnchorTheme.Typography.caption)
                            .foregroundColor(AnchorTheme.Colors.warmSand)
                            .padding(.top, 4)
                        ForEach(payload.copingStrategiesDidntWork, id: \.self) { strategy in
                            Text("• \(strategy)")
                                .font(AnchorTheme.Typography.bodyText)
                                .anchorSecondaryText()
                        }
                    }
                }
            }
            NoteDivider()
        } else if !payload.copingStrategiesExplored.isEmpty {
            NoteSection(title: String(localized: "Coping strategies"), icon: "shield.checkered") {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(payload.copingStrategiesExplored, id: \.self) { strategy in
                        Text(strategy)
                            .font(AnchorTheme.Typography.bodyText)
                            .anchorSecondaryText()
                    }
                }
            }
            NoteDivider()
        } else if !payload.copingStrategies.isEmpty {
            // Legacy fallback
            NoteSection(title: String(localized: "Coping strategies"), icon: "shield.checkered") {
                FlowLayout(spacing: 8) {
                    ForEach(payload.copingStrategies, id: \.self) { strategy in
                        Text(strategy)
                            .font(AnchorTheme.Typography.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AnchorTheme.Colors.warmStone)
                            .foregroundColor(AnchorTheme.Colors.quietInk)
                            .cornerRadius(14)
                    }
                }
            }
            NoteDivider()
        }

        // ── For Your Therapist ──────────────────────────────
        if !payload.actionItemsForTherapist.isEmpty {
            NoteSection(
                title: String(localized: "For your therapist"), icon: "person.crop.rectangle"
            ) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(payload.actionItemsForTherapist, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "arrow.right.circle")
                                .font(.system(size: 12))
                                .foregroundColor(AnchorTheme.Colors.sageLeaf)
                                .padding(.top, 3)
                                .accessibilityHidden(true)
                            Text(item)
                                .font(AnchorTheme.Typography.bodyText)
                                .anchorSecondaryText()
                        }
                    }
                }
            }
            NoteDivider()
        }

        // ── Pattern Alert ───────────────────────────────────
        if !payload.recurringPatternAlert.isEmpty
            || !payload.patternRecognized.isEmpty
            || !payload.recurringTopicsSnapshot.isEmpty
            || !payload.recurringTopicsTrend.isEmpty
        {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 14))
                    .foregroundColor(AnchorTheme.Colors.warmSand)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Recurring pattern"))
                        .font(AnchorTheme.Typography.caption)
                        .foregroundColor(AnchorTheme.Colors.warmSand)
                    if !payload.recurringPatternAlert.isEmpty {
                        Text(payload.recurringPatternAlert)
                            .font(AnchorTheme.Typography.bodyText)
                            .anchorSecondaryText()
                    }
                    if !payload.patternRecognized.isEmpty {
                        Text(
                            String.localizedStringWithFormat(
                                String(localized: "You noticed: %@"),
                                payload.patternRecognized
                            )
                        )
                        .font(AnchorTheme.Typography.caption)
                        .anchorSecondaryText()
                    }
                    if !payload.recurringTopicsSnapshot.isEmpty {
                        Text(
                            String.localizedStringWithFormat(
                                String(localized: "Recurring topics: %@"),
                                payload.recurringTopicsSnapshot.joined(separator: ", ")
                            )
                        )
                        .font(AnchorTheme.Typography.caption)
                        .anchorSecondaryText()
                    }
                    if !payload.recurringTopicsTrend.isEmpty {
                        Text(
                            String.localizedStringWithFormat(
                                String(localized: "Trend: %@"),
                                payload.recurringTopicsTrend
                            )
                        )
                        .font(AnchorTheme.Typography.caption)
                        .anchorSecondaryText()
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AnchorTheme.Colors.warmSand.opacity(0.1))
            )
            NoteDivider()
        }

        // ── Home Practice ─────────────────────────────────────
        if !payload.homeworkItems.isEmpty || !payload.homework.isEmpty {
            NoteSection(
                title: String(localized: "Home practice"),
                icon: "checklist"
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    if !payload.homeworkItems.isEmpty {
                        ForEach(payload.homeworkItems, id: \.self) { item in
                            let isDone = payload.completedHomeworkItems.contains(item)
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(
                                        isDone
                                            ? AnchorTheme.Colors.sageLeaf
                                            : AnchorTheme.Colors.quietInkSecondary
                                    )
                                    .padding(.top, 3)
                                    .accessibilityHidden(true)
                                CollapsibleNoteText(
                                    item,
                                    collapsedLineLimit: 3
                                )
                            }
                        }
                    } else {
                        CollapsibleNoteText(
                            payload.homework,
                            collapsedLineLimit: 4
                        )
                    }
                }
            }
            NoteDivider()
        }

        if !payload.previousHomeworkAssigned.isEmpty
            || !payload.previousHomeworkCompletion.isEmpty
            || !payload.previousHomeworkReflection.isEmpty
            || !payload.therapyGoalProgress.isEmpty
        {
            NoteSection(
                title: String(localized: "Progress tracking"),
                icon: "chart.line.uptrend.xyaxis"
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    if !payload.previousHomeworkAssigned.isEmpty {
                        Text(
                            String.localizedStringWithFormat(
                                String(localized: "Previous homework: %@"),
                                payload.previousHomeworkAssigned
                            )
                        )
                        .font(AnchorTheme.Typography.bodyText)
                        .anchorSecondaryText()
                    }
                    if !payload.previousHomeworkCompletion.isEmpty {
                        Text(
                            String.localizedStringWithFormat(
                                String(localized: "Completion: %@"),
                                payload.previousHomeworkCompletion
                            )
                        )
                        .font(AnchorTheme.Typography.caption)
                        .anchorSecondaryText()
                    }
                    if !payload.previousHomeworkReflection.isEmpty {
                        CollapsibleNoteText(
                            payload.previousHomeworkReflection,
                            collapsedLineLimit: 3
                        )
                    }
                    if !payload.therapyGoalProgress.isEmpty {
                        Text(String(localized: "Therapy goals"))
                            .font(AnchorTheme.Typography.caption)
                            .anchorSecondaryText()
                            .padding(.top, 4)
                        ForEach(payload.therapyGoalProgress, id: \.self) { goal in
                            Text("• \(goal)")
                                .font(AnchorTheme.Typography.bodyText)
                                .anchorSecondaryText()
                        }
                    }
                }
            }
            NoteDivider()
        }

        if !payload.actionItemsForUser.isEmpty {
            NoteSection(
                title: String(localized: "Action items for you"),
                icon: "person.fill.checkmark"
            ) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(payload.actionItemsForUser, id: \.self) { item in
                        Text("• \(item)")
                            .font(AnchorTheme.Typography.bodyText)
                            .anchorSecondaryText()
                    }
                }
            }
            NoteDivider()
        }

        if !payload.continuityPeopleMentioned.isEmpty
            || !payload.continuityUpcomingEvents.isEmpty
            || !payload.continuityEnvironmentalFactors.isEmpty
        {
            NoteSection(
                title: String(localized: "Context for continuity"),
                icon: "link"
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    if !payload.continuityPeopleMentioned.isEmpty {
                        Text(
                            String.localizedStringWithFormat(
                                String(localized: "People: %@"),
                                payload.continuityPeopleMentioned.joined(separator: "; ")
                            )
                        )
                        .font(AnchorTheme.Typography.bodyText)
                        .anchorSecondaryText()
                    }
                    if !payload.continuityUpcomingEvents.isEmpty {
                        Text(
                            String.localizedStringWithFormat(
                                String(localized: "Upcoming: %@"),
                                payload.continuityUpcomingEvents.joined(separator: "; ")
                            )
                        )
                        .font(AnchorTheme.Typography.bodyText)
                        .anchorSecondaryText()
                    }
                    if !payload.continuityEnvironmentalFactors.isEmpty {
                        Text(
                            String.localizedStringWithFormat(
                                String(localized: "Environment: %@"),
                                payload.continuityEnvironmentalFactors.joined(separator: "; ")
                            )
                        )
                        .font(AnchorTheme.Typography.bodyText)
                        .anchorSecondaryText()
                    }
                }
            }
            NoteDivider()
        }

        if payload.crisisRiskDetectedByModel != nil
            || !payload.crisisNotes.isEmpty
            || !payload.protectiveFactors.isEmpty
            || !payload.safetyRecommendation.isEmpty
        {
            NoteSection(
                title: String(localized: "Safety assessment"),
                icon: "exclamationmark.shield"
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    if let risk = payload.crisisRiskDetectedByModel {
                        Text(
                            risk
                                ? String(localized: "Risk detected: Yes")
                                : String(localized: "Risk detected: No")
                        )
                        .font(AnchorTheme.Typography.caption)
                        .foregroundColor(
                            risk ? AnchorTheme.Colors.crisisRed : AnchorTheme.Colors.sageLeaf
                        )
                    }
                    if !payload.crisisNotes.isEmpty {
                        CollapsibleNoteText(payload.crisisNotes, collapsedLineLimit: 4)
                    }
                    if !payload.protectiveFactors.isEmpty {
                        Text(
                            String.localizedStringWithFormat(
                                String(localized: "Protective factors: %@"),
                                payload.protectiveFactors.joined(separator: ", ")
                            )
                        )
                        .font(AnchorTheme.Typography.bodyText)
                        .anchorSecondaryText()
                    }
                    if !payload.safetyRecommendation.isEmpty {
                        Text(
                            String.localizedStringWithFormat(
                                String(localized: "Recommendation: %@"),
                                payload.safetyRecommendation
                            )
                        )
                        .font(AnchorTheme.Typography.bodyText)
                        .anchorSecondaryText()
                    }
                }
            }
            NoteDivider()
        }

        if !payload.dominantEmotions.isEmpty
            || !payload.primaryCopingStyle.isEmpty
            || payload.sessionEffectivenessSelfRating != nil
        {
            NoteSection(
                title: String(localized: "Clinical observations"),
                icon: "waveform.path.ecg"
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    if !payload.dominantEmotions.isEmpty {
                        Text(
                            String.localizedStringWithFormat(
                                String(localized: "Dominant emotions: %@"),
                                payload.dominantEmotions.joined(separator: ", ")
                            )
                        )
                        .font(AnchorTheme.Typography.bodyText)
                        .anchorSecondaryText()
                    }
                    if !payload.primaryCopingStyle.isEmpty {
                        Text(
                            String.localizedStringWithFormat(
                                String(localized: "Primary coping style: %@"),
                                payload.primaryCopingStyle
                            )
                        )
                        .font(AnchorTheme.Typography.bodyText)
                        .anchorSecondaryText()
                    }
                    if let rating = payload.sessionEffectivenessSelfRating {
                        Text(
                            String.localizedStringWithFormat(
                                String(localized: "Session effectiveness: %lld/10"),
                                Int64(rating)
                            )
                        )
                        .font(AnchorTheme.Typography.bodyText)
                        .anchorSecondaryText()
                    }
                }
            }
            NoteDivider()
        }

        // ── Suggested Follow-up ─────────────────────────────
        if !payload.suggestedFollowUp.isEmpty {
            NoteSection(
                title: String(localized: "Suggested follow-up"), icon: "arrow.forward.circle"
            ) {
                Text(payload.suggestedFollowUp)
                    .font(AnchorTheme.Typography.bodyText)
                    .anchorSecondaryText()
            }
        }
    }

    private var emptyStateText: String {
        switch summaryStatus {
        case .failed(let message):
            return message
        case .summarizing:
            return String(localized: "Finalizing notes…")
        default:
            return String(localized: "Notes will appear here once your session is summarized.")
        }
    }
}

/// Reusable note section with a title, icon, and content.
private struct NoteSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(title)
                    .font(AnchorTheme.Typography.caption)
                    .anchorSecondaryText()
            } icon: {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(AnchorTheme.Colors.sageLeaf)
            }
            content
        }
    }
}

/// Thin divider between note sections.
private struct NoteDivider: View {
    var body: some View {
        Rectangle()
            .fill(AnchorTheme.Colors.quietInk.opacity(0.08))
            .frame(height: 1)
            .padding(.vertical, 2)
    }
}

/// Collapses long note text to keep sheets readable while preserving full content.
private struct CollapsibleNoteText: View {
    let text: String
    var collapsedLineLimit: Int = 4
    var useCaptionFont: Bool = false
    var italic: Bool = false
    @State private var isExpanded = false

    init(
        _ text: String,
        collapsedLineLimit: Int = 4,
        useCaptionFont: Bool = false,
        italic: Bool = false
    ) {
        self.text = text
        self.collapsedLineLimit = collapsedLineLimit
        self.useCaptionFont = useCaptionFont
        self.italic = italic
    }

    private var shouldCollapse: Bool {
        text.count > 260 || text.split(separator: "\n").count > collapsedLineLimit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Group {
                if italic {
                    Text(text).italic()
                } else {
                    Text(text)
                }
            }
            .font(useCaptionFont ? AnchorTheme.Typography.caption : AnchorTheme.Typography.bodyText)
            .anchorSecondaryText()
            .lineLimit(shouldCollapse && !isExpanded ? collapsedLineLimit : nil)
            .animation(.easeInOut(duration: 0.2), value: isExpanded)

            if shouldCollapse {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(
                        isExpanded
                            ? String(localized: "Show less")
                            : String(localized: "Show more")
                    )
                    .font(AnchorTheme.Typography.smallCaption)
                    .foregroundColor(AnchorTheme.Colors.sageLeaf)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct SummaryStat: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AnchorTheme.Typography.caption)
                .anchorSecondaryText()
            Text(value)
                .font(AnchorTheme.Typography.bodyText)
                .anchorPrimaryText()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Safety Guidelines") {
    NavigationStack {
        SafetyGuidelinesView()
    }
}

#Preview("About") {
    NavigationStack {
        AboutView()
    }
}

#Preview("Reflection") {
    PostSessionReflectionView(
        prompt: String(localized: "What's one thing you'd like to remember from this conversation?")
    ) {}
}
