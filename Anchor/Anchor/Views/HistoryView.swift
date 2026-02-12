//
//  HistoryView.swift
//  Anchor
//
//  Created for Anchor - AI-Powered Emotional Support
//

import SwiftData
import SwiftUI
import UIKit

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.displayScale) private var displayScale
    @Query(sort: \Session.timestamp, order: .reverse) private var sessions: [Session]
    @Query private var profiles: [UserProfile]
    @Query private var userSettings: [UserSettings]
    @State private var selectedSession: Session?
    @State private var showingDeleteAlert = false
    @State private var sessionToDelete: Session?
    @State private var showingDeleteAllAlert = false
    @State private var showingExportSheet = false
    @State private var exportFileURL: URL?
    @State private var searchText = ""
    @State private var showingSaveError = false
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var pendingShareSession: Session?
    @State private var showingShareOptions = false
    @State private var showingCopyAlert = false
    @State private var preparingPDFShare = false

    private var hasContent: Bool {
        !sessions.isEmpty
    }

    private var filteredSessions: [Session] {
        guard !searchText.isEmpty else { return sessions }
        return sessions.filter { session in
            session.summary.localizedCaseInsensitiveContains(searchText)
                || session.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
                || (session.moodTriggers ?? []).contains {
                    $0.localizedCaseInsensitiveContains(searchText)
                        || MoodTriggerTag.label(for: $0).localizedCaseInsensitiveContains(
                            searchText)
                } || (session.sessionFocus ?? "").localizedCaseInsensitiveContains(searchText)
                || (SessionFocus(rawValue: session.sessionFocus ?? "")?.title
                    .localizedCaseInsensitiveContains(searchText) ?? false)
                || (session.observedMood ?? "").localizedCaseInsensitiveContains(searchText)
                || (session.copingStrategies ?? []).contains {
                    $0.localizedCaseInsensitiveContains(searchText)
                } || (session.suggestedFollowUp ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    private var currentStreak: Int {
        userSettings.first?.currentStreak ?? 0
    }

    private var averageMoodDelta: Double? {
        let deltas = sessions.compactMap { session -> Double? in
            guard let before = session.moodBefore, let after = session.moodAfter else { return nil }
            return Double(after - before)
        }
        guard !deltas.isEmpty else { return nil }
        let total = deltas.reduce(0, +)
        return total / Double(deltas.count)
    }

    private var topTags: [String] {
        let allTags = sessions.flatMap { $0.tags }
        return topFrequencies(from: allTags, max: 3)
    }

    private var topTriggers: [String] {
        let allTriggers = sessions.flatMap { $0.moodTriggers ?? [] }
        return topFrequencies(from: allTriggers, max: 3).map { MoodTriggerTag.label(for: $0) }
    }

    var body: some View {
        List {
            if !hasContent {
                VStack(spacing: 20) {
                    OrbView(state: .idle, size: 80)
                        .opacity(0.5)

                    Text(String(localized: "No sessions yet"))
                        .font(AnchorTheme.Typography.headline)
                        .anchorPrimaryText()

                    Text(
                        String(
                            localized:
                                "When you have a conversation with Anchor,\nit will appear here.")
                    )
                    .font(AnchorTheme.Typography.subheadline)
                    .anchorSecondaryText()
                    .multilineTextAlignment(.center)

                    Button(action: { dismiss() }) {
                        Text(String(localized: "Start a session"))
                            .font(AnchorTheme.Typography.subheadline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(
                        AnchorPillButtonStyle(
                            background: AnchorTheme.Colors.sageLeaf,
                            foreground: AnchorTheme.Colors.softParchment)
                    )
                    .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 80)
                .listRowSeparator(.hidden)
                .listRowBackground(AnchorTheme.Colors.softParchment)
            } else {
                if searchText.isEmpty, !sessions.isEmpty {
                    Section {
                        HistorySummaryCard(
                            totalSessions: sessions.count,
                            currentStreak: currentStreak,
                            averageMoodDelta: averageMoodDelta,
                            topTags: topTags,
                            topTriggers: topTriggers
                        )

                        NavigationLink {
                            InsightsView()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "chart.bar.xaxis")
                                    .foregroundColor(AnchorTheme.Colors.etherBlue)
                                    .font(.system(size: 18, weight: .semibold))
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(String(localized: "View Insights"))
                                        .font(AnchorTheme.Typography.subheadline)
                                        .anchorPrimaryText()
                                    Text(String(localized: "See mood trends and recurring patterns."))
                                        .font(AnchorTheme.Typography.caption)
                                        .anchorSecondaryText()
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(AnchorTheme.Colors.softParchment)
                }

                if filteredSessions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: searchText.isEmpty ? "clock" : "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(AnchorTheme.Colors.warmSand)
                            .accessibilityHidden(true)
                        Text(
                            searchText.isEmpty
                                ? String(localized: "No sessions yet")
                                : String(localized: "No matching results")
                        )
                        .font(AnchorTheme.Typography.headline)
                        .anchorPrimaryText()
                        Text(
                            searchText.isEmpty
                                ? String(localized: "Your conversations will appear here.")
                                : String(localized: "Try a different keyword or tag.")
                        )
                        .font(AnchorTheme.Typography.subheadline)
                        .anchorSecondaryText()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                    .listRowSeparator(.hidden)
                    .listRowBackground(AnchorTheme.Colors.softParchment)
                } else {
                    Section {
                        ForEach(filteredSessions) { session in
                            Button {
                                selectedSession = session
                            } label: {
                                SessionDetailRow(session: session)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(sessionAccessibilityLabel(session))
                            .accessibilityHint(String(localized: "View session details"))
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    promptShareOptions(for: session)
                                } label: {
                                    Label(
                                        String(localized: "Share"),
                                        systemImage: "square.and.arrow.up")
                                }

                                if !session.summary.isEmpty {
                                    Button {
                                        copySummary(for: session)
                                    } label: {
                                        Label(
                                            String(localized: "Copy Takeaway"),
                                            systemImage: "doc.on.doc")
                                    }
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    sessionToDelete = session
                                    showingDeleteAlert = true
                                } label: {
                                    Label(String(localized: "Delete"), systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(String(localized: "History"))
        .navigationBarTitleDisplayMode(.large)
        .listSectionSpacing(10)
        .scrollContentBackground(.hidden)
        .background(AnchorTheme.Colors.softParchment)
        .anchorScreenBackground()
        .searchable(text: $searchText, prompt: String(localized: "Search history"))
        .sheet(item: $selectedSession) { session in
            SessionDetailView(session: session)
        }
        .alert(
            String(localized: "Delete Session?"), isPresented: $showingDeleteAlert,
            presenting: sessionToDelete
        ) { session in
            Button(String(localized: "Cancel"), role: .cancel) {}
            Button(String(localized: "Delete"), role: .destructive) {
                deleteSession(session)
            }
        } message: { session in
            Text(
                String(
                    localized:
                        "This will permanently delete this session. This action cannot be undone."))
        }
        .alert(String(localized: "Delete All Sessions?"), isPresented: $showingDeleteAllAlert) {
            Button(String(localized: "Cancel"), role: .cancel) {}
            Button(String(localized: "Delete All"), role: .destructive) {
                deleteAllSessions()
            }
        } message: {
            Text(
                String.localizedStringWithFormat(
                    String(
                        localized:
                            "This will permanently delete all %lld sessions. This action cannot be undone."
                    ),
                    Int64(sessions.count)
                )
            )
        }
        .sheet(isPresented: $showingExportSheet) {
            if let url = exportFileURL {
                ShareSheet(activityItems: [url])
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: shareItems)
        }
        .sheet(isPresented: $showingShareOptions) {
            if let session = pendingShareSession {
                ShareOptionsSheet(
                    title: String(localized: "Share Session"),
                    subtitle: String(localized: "Choose how you’d like to share this check-in."),
                    actions: shareActions(for: session, includeCopy: true),
                    onDismiss: {
                        showingShareOptions = false
                        pendingShareSession = nil
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .alert(String(localized: "Copied to Clipboard"), isPresented: $showingCopyAlert) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            Text(String(localized: "Session takeaway copied."))
        }
        .persistenceAlert(isPresented: $showingSaveError)
        .toolbar {
            if !sessions.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: exportAllData) {
                            Label(
                                String(localized: "Export All Data"),
                                systemImage: "square.and.arrow.up")
                        }

                        Button(role: .destructive, action: { showingDeleteAllAlert = true }) {
                            Label(String(localized: "Delete All Sessions"), systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel(String(localized: "Session options"))
                    .accessibilityHint(String(localized: "Export or delete sessions"))
                }
            }
        }
    }

    private func deleteSession(_ session: Session) {
        withAnimation {
            modelContext.delete(session)
            if !modelContext.safeSave() { showingSaveError = true }
        }
    }

    private func deleteAllSessions() {
        for session in sessions {
            modelContext.delete(session)
        }
        if !modelContext.safeSave() { showingSaveError = true }
    }

    private func exportAllData() {
        guard
            let url = DataExporter.exportAll(
                sessions: sessions,
                profile: profiles.first
            )
        else { return }
        exportFileURL = url
        showingExportSheet = true
    }

    private func promptShareOptions(for session: Session) {
        pendingShareSession = session
        showingShareOptions = true
    }

    private func shareActions(for session: Session, includeCopy: Bool) -> [ShareOption] {
        var actions: [ShareOption] = [
            ShareOption(
                title: String(localized: "Share Summary Card"),
                subtitle: String(localized: "A clean card with highlights."),
                systemImage: "square.and.arrow.up",
                action: { shareSummaryCard(for: session) }
            )
        ]

        if hasSessionNotes(session) {
            actions.append(
                ShareOption(
                    title: String(localized: "Share Notes Card"),
                    subtitle: String(localized: "Supportive notes as a card."),
                    systemImage: "doc.richtext",
                    action: { shareNotesCard(for: session) }
                )
            )
            actions.append(
                ShareOption(
                    title: String(localized: "Export PDF"),
                    subtitle: String(localized: "Therapist-ready PDF notes."),
                    systemImage: "arrow.down.doc",
                    action: { sharePDF(for: session) }
                )
            )
        }

        if includeCopy, !session.summary.isEmpty {
            actions.append(
                ShareOption(
                    title: String(localized: "Copy Takeaway"),
                    subtitle: String(localized: "Copy the takeaway to your clipboard."),
                    systemImage: "doc.on.doc",
                    action: { copySummary(for: session) }
                )
            )
        }

        return actions
    }

    @MainActor
    private func sharePDF(for session: Session) {
        guard !preparingPDFShare else { return }
        let payload = SessionSummaryPayload(session: session)
        preparingPDFShare = true
        DispatchQueue.global(qos: .userInitiated).async {
            let url = SessionPDFExporter.generatePDF(from: payload)
            DispatchQueue.main.async {
                preparingPDFShare = false
                guard let url else { return }
                shareItems = [url]
                showingShareSheet = true
            }
        }
    }

    @MainActor
    private func shareSummaryCard(for session: Session) {
        let payload = SessionSummaryPayload(session: session)
        let card = SessionSummaryShareCardView(payload: payload)
            .frame(width: 380)
            .padding(20)
            .background(Color.white)

        let renderer = ImageRenderer(content: card)
        renderer.scale = max(displayScale, 3)
        if let image = renderer.uiImage {
            shareItems = [image, sessionShareText(session)]
        } else {
            shareItems = [sessionShareText(session)]
        }
        showingShareSheet = !shareItems.isEmpty
    }

    @MainActor
    private func shareNotesCard(for session: Session) {
        let card = SessionNotesShareCardView(
            payload: SessionSummaryPayload(session: session),
            summaryStatus: .ready
        )
        .frame(width: 380)
        .padding(20)
        .background(Color.white)

        let renderer = ImageRenderer(content: card)
        renderer.scale = max(displayScale, 3)
        if let image = renderer.uiImage {
            shareItems = [image, sessionNotesText(session)]
        } else {
            shareItems = [sessionNotesText(session)]
        }
        showingShareSheet = !shareItems.isEmpty
    }

    private func copySummary(for session: Session) {
        guard !session.summary.isEmpty else { return }
        UIPasteboard.general.string = session.summary
        showingCopyAlert = true
    }

    private func sessionShareText(_ session: Session) -> String {
        var lines: [String] = []
        lines.append(String(localized: "Anchor Session"))
        lines.append(session.timestamp.formatted(date: .abbreviated, time: .shortened))
        if !session.summary.isEmpty {
            lines.append("")
            lines.append(session.summary)
        }
        if !session.tags.isEmpty {
            let topicsText = session.tags.prefix(4).joined(separator: ", ")
            lines.append("")
            lines.append(
                String.localizedStringWithFormat(String(localized: "Topics: %@"), topicsText))
        }
        if let focus = session.sessionFocus {
            let focusLabel = SessionFocus(rawValue: focus)?.title ?? focus
            lines.append("")
            lines.append(
                String.localizedStringWithFormat(String(localized: "Focus: %@"), focusLabel))
        }
        if let before = session.moodBefore, let after = session.moodAfter {
            lines.append("")
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Mood: %@ → %@"), moodWord(before), moodWord(after)))
        }
        if let followUp = session.suggestedFollowUp, !followUp.isEmpty {
            lines.append("")
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Suggested follow-up: %@"), followUp))
        }
        lines.append("")
        lines.append(String(localized: "(No transcripts included)"))
        return lines.joined(separator: "\n")
    }

    private func sessionNotesText(_ session: Session) -> String {
        var lines: [String] = []
        lines.append(String(localized: "Session Notes"))
        lines.append(session.timestamp.formatted(date: .abbreviated, time: .shortened))

        if let narrative = session.narrativeSummary, !narrative.isEmpty {
            lines.append("")
            lines.append(
                String.localizedStringWithFormat(String(localized: "Summary: %@"), narrative))
        }

        if let moodStart = session.moodStartDescription, !moodStart.isEmpty {
            lines.append("")
            lines.append(
                String.localizedStringWithFormat(String(localized: "Mood start: %@"), moodStart))
        }
        if let moodEnd = session.moodEndDescription, !moodEnd.isEmpty {
            lines.append(
                String.localizedStringWithFormat(String(localized: "Mood end: %@"), moodEnd))
        }
        if let moodShift = session.moodShiftDescription, !moodShift.isEmpty {
            lines.append(
                String.localizedStringWithFormat(String(localized: "Shift: %@"), moodShift))
        }

        if let observed = session.observedMood, !observed.isEmpty,
            (session.moodStartDescription ?? "").isEmpty
        {
            lines.append("")
            lines.append(
                String.localizedStringWithFormat(String(localized: "Observed mood: %@"), observed))
        }

        if let insight = session.keyInsight, !insight.isEmpty {
            lines.append("")
            lines.append(
                String.localizedStringWithFormat(String(localized: "Key insight: %@"), insight))
        }
        if let quotes = session.userQuotes, !quotes.isEmpty {
            for quote in quotes {
                lines.append(
                    String.localizedStringWithFormat(String(localized: "\u{201C}%@\u{201D}"), quote)
                )
            }
        }

        let explored = session.copingStrategiesExplored ?? []
        if !explored.isEmpty {
            lines.append("")
            let strategyList = explored.joined(separator: "\n  • ")
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Coping strategies:\n  • %@"), strategyList))
        } else {
            let strategies = session.copingStrategies ?? []
            if !strategies.isEmpty {
                lines.append("")
                let strategyList = strategies.joined(separator: ", ")
                lines.append(
                    String.localizedStringWithFormat(
                        String(localized: "Coping strategies: %@"), strategyList))
            }
        }

        if let items = session.actionItemsForTherapist, !items.isEmpty {
            lines.append("")
            let itemList = items.joined(separator: "\n  → ")
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "For your therapist:\n  → %@"), itemList))
        }

        if let pattern = session.recurringPatternAlert, !pattern.isEmpty {
            lines.append("")
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Recurring pattern: %@"), pattern))
        }

        if let followUp = session.suggestedFollowUp, !followUp.isEmpty {
            lines.append("")
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Suggested follow-up: %@"), followUp))
        }

        if let focus = session.primaryFocus, !focus.isEmpty {
            lines.append("")
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Primary focus: %@"),
                    focus
                )
            )
        }
        if let themes = session.relatedThemes, !themes.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Related themes: %@"),
                    themes.joined(separator: ", ")
                )
            )
        }
        if let pattern = session.patternRecognized, !pattern.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Pattern recognized: %@"),
                    pattern
                )
            )
        }
        if let snapshots = session.recurringTopicsSnapshot, !snapshots.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Recurring topics snapshot: %@"),
                    snapshots.joined(separator: ", ")
                )
            )
        }
        if let trend = session.recurringTopicsTrend, !trend.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Recurring trend: %@"),
                    trend
                )
            )
        }

        if let startIntensity = session.moodStartIntensity {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Mood intensity start: %lld/10"),
                    Int64(startIntensity)
                )
            )
        }
        if let endIntensity = session.moodEndIntensity {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Mood intensity end: %lld/10"),
                    Int64(endIntensity)
                )
            )
        }
        if let startPhysical = session.moodStartPhysicalSymptoms, !startPhysical.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Start physical cues: %@"),
                    startPhysical.joined(separator: ", ")
                )
            )
        }
        if let endPhysical = session.moodEndPhysicalSymptoms, !endPhysical.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "End physical cues: %@"),
                    endPhysical.joined(separator: ", ")
                )
            )
        }

        if let attempted = session.copingStrategiesAttempted, !attempted.isEmpty {
            lines.append("")
            lines.append(String(localized: "Coping attempted:"))
            for item in attempted {
                lines.append("• \(item)")
            }
        }
        if let worked = session.copingStrategiesWorked, !worked.isEmpty {
            lines.append("")
            lines.append(String(localized: "What helped:"))
            for item in worked {
                lines.append("• \(item)")
            }
        }
        if let didnt = session.copingStrategiesDidntWork, !didnt.isEmpty {
            lines.append("")
            lines.append(String(localized: "What did not help:"))
            for item in didnt {
                lines.append("• \(item)")
            }
        }

        if let previousHomework = session.previousHomeworkAssigned, !previousHomework.isEmpty {
            lines.append("")
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Previous homework: %@"),
                    previousHomework
                )
            )
        }
        if let completion = session.previousHomeworkCompletion, !completion.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Previous homework completion: %@"),
                    completion
                )
            )
        }
        if let reflection = session.previousHomeworkReflection, !reflection.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Previous homework reflection: %@"),
                    reflection
                )
            )
        }
        if let goalProgress = session.therapyGoalProgress, !goalProgress.isEmpty {
            lines.append("")
            lines.append(String(localized: "Therapy goal progress:"))
            for goal in goalProgress {
                lines.append("• \(goal)")
            }
        }
        if let userActions = session.actionItemsForUser, !userActions.isEmpty {
            lines.append("")
            lines.append(String(localized: "Action items for you:"))
            for action in userActions {
                lines.append("• \(action)")
            }
        }
        if let people = session.continuityPeopleMentioned, !people.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "People mentioned: %@"),
                    people.joined(separator: "; ")
                )
            )
        }
        if let events = session.continuityUpcomingEvents, !events.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Upcoming events: %@"),
                    events.joined(separator: "; ")
                )
            )
        }
        if let environment = session.continuityEnvironmentalFactors, !environment.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Environmental factors: %@"),
                    environment.joined(separator: "; ")
                )
            )
        }

        if let risk = session.crisisRiskDetectedByModel {
            lines.append("")
            lines.append(
                risk
                    ? String(localized: "Model safety risk detected: yes")
                    : String(localized: "Model safety risk detected: no")
            )
        }
        if let notes = session.crisisNotes, !notes.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Safety notes: %@"),
                    notes
                )
            )
        }
        if let factors = session.protectiveFactors, !factors.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Protective factors: %@"),
                    factors.joined(separator: ", ")
                )
            )
        }
        if let recommendation = session.safetyRecommendation, !recommendation.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Safety recommendation: %@"),
                    recommendation
                )
            )
        }
        if let emotions = session.dominantEmotions, !emotions.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Dominant emotions: %@"),
                    emotions.joined(separator: ", ")
                )
            )
        }
        if let copingStyle = session.primaryCopingStyle, !copingStyle.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Primary coping style: %@"),
                    copingStyle
                )
            )
        }
        if let rating = session.sessionEffectivenessSelfRating {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Session effectiveness: %lld/10"),
                    Int64(rating)
                )
            )
        }

        let completedItems = Set(session.completedHomeworkItems ?? [])
        let homeworkItems = session.homeworkItems ?? []
        if !homeworkItems.isEmpty {
            lines.append("")
            lines.append(String(localized: "Home practice:"))
            for item in homeworkItems {
                let marker = completedItems.contains(item) ? "✅" : "•"
                lines.append("\(marker) \(item)")
            }
        } else if let homework = session.homework, !homework.isEmpty {
            lines.append("")
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Home practice: %@"),
                    homework
                )
            )
        }

        lines.append("")
        lines.append(String(localized: "Supportive notes — not a clinical record."))
        lines.append(String(localized: "(No transcripts included)"))
        return lines.joined(separator: "\n")
    }

    private func hasSessionNotes(_ session: Session) -> Bool {
        let hasMood = !(session.observedMood ?? "").isEmpty
        let hasStrategies = !(session.copingStrategies ?? []).isEmpty
        let hasFollowUp = !(session.suggestedFollowUp ?? "").isEmpty
        let hasNarrative = !(session.narrativeSummary ?? "").isEmpty
        let hasInsight = !(session.keyInsight ?? "").isEmpty
        let hasMoodJourney =
            !(session.moodStartDescription ?? "").isEmpty
            || !(session.moodEndDescription ?? "").isEmpty
            || !(session.moodShiftDescription ?? "").isEmpty
        let hasExplored = !(session.copingStrategiesExplored ?? []).isEmpty
        let hasCopingDetail = !(session.copingStrategiesAttempted ?? []).isEmpty
            || !(session.copingStrategiesWorked ?? []).isEmpty
            || !(session.copingStrategiesDidntWork ?? []).isEmpty
        let hasTherapistItems = !(session.actionItemsForTherapist ?? []).isEmpty
        let hasUserItems = !(session.actionItemsForUser ?? []).isEmpty
        let hasPattern = !(session.recurringPatternAlert ?? "").isEmpty
        let hasAdvancedPattern = !(session.patternRecognized ?? "").isEmpty
            || !(session.primaryFocus ?? "").isEmpty
            || !(session.relatedThemes ?? []).isEmpty
            || !(session.recurringTopicsSnapshot ?? []).isEmpty
            || !(session.recurringTopicsTrend ?? "").isEmpty
        let hasMoodDetail = session.moodStartIntensity != nil
            || session.moodEndIntensity != nil
            || !(session.moodStartPhysicalSymptoms ?? []).isEmpty
            || !(session.moodEndPhysicalSymptoms ?? []).isEmpty
        let hasHomework =
            !(session.homework ?? "").isEmpty
            || !(session.homeworkItems ?? []).isEmpty
        let hasProgress = !(session.previousHomeworkAssigned ?? "").isEmpty
            || !(session.previousHomeworkCompletion ?? "").isEmpty
            || !(session.previousHomeworkReflection ?? "").isEmpty
            || !(session.therapyGoalProgress ?? []).isEmpty
        let hasContinuity = !(session.continuityPeopleMentioned ?? []).isEmpty
            || !(session.continuityUpcomingEvents ?? []).isEmpty
            || !(session.continuityEnvironmentalFactors ?? []).isEmpty
        let hasSafety = session.crisisRiskDetectedByModel != nil
            || !(session.crisisNotes ?? "").isEmpty
            || !(session.protectiveFactors ?? []).isEmpty
            || !(session.safetyRecommendation ?? "").isEmpty
        let hasClinical = !(session.dominantEmotions ?? []).isEmpty
            || !(session.primaryCopingStyle ?? "").isEmpty
            || session.sessionEffectivenessSelfRating != nil
        return hasMood || hasStrategies || hasFollowUp || hasNarrative
            || hasInsight || hasMoodJourney || hasExplored || hasTherapistItems
            || hasPattern || hasHomework || hasCopingDetail || hasUserItems
            || hasAdvancedPattern || hasMoodDetail || hasProgress || hasContinuity
            || hasSafety || hasClinical
    }

    private func sessionAccessibilityLabel(_ session: Session) -> String {
        var parts: [String] = []
        parts.append(session.timestamp.formatted(.relative(presentation: .named)))
        parts.append(session.formattedDuration)
        if !session.summary.isEmpty {
            parts.append(session.summary)
        }
        if session.crisisDetected {
            parts.append(String(localized: "Crisis detected"))
        }
        if let b = session.moodBefore, let a = session.moodAfter {
            parts.append(
                String.localizedStringWithFormat(
                    String(localized: "Mood %@ to %@"),
                    moodWord(b),
                    moodWord(a)
                )
            )
        }
        return parts.joined(separator: ", ")
    }

    private func moodWord(_ level: Int?) -> String {
        guard let level else { return String(localized: "unknown") }
        switch level {
        case 1: return String(localized: "very low")
        case 2: return String(localized: "low")
        case 3: return String(localized: "okay")
        case 4: return String(localized: "good")
        case 5: return String(localized: "great")
        default: return String(localized: "okay")
        }
    }

    private func topFrequencies(from values: [String], max: Int) -> [String] {
        let trimmed = values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let counts = Dictionary(grouping: trimmed, by: { $0 }).mapValues { $0.count }
        return
            counts
            .sorted { lhs, rhs in
                if lhs.value == rhs.value { return lhs.key < rhs.key }
                return lhs.value > rhs.value
            }
            .prefix(max)
            .map { $0.key }
    }

}

struct SessionDetailRow: View {
    let session: Session

    private var moodEmoji: (before: String, after: String)? {
        guard let b = session.moodBefore, let a = session.moodAfter else { return nil }
        return (MoodEmoji.emoji(for: b), MoodEmoji.emoji(for: a))
    }

    private func moodWord(_ level: Int?) -> String {
        guard let level else { return "unknown" }
        switch level {
        case 1: return String(localized: "very low")
        case 2: return String(localized: "low")
        case 3: return String(localized: "okay")
        case 4: return String(localized: "good")
        case 5: return String(localized: "great")
        default: return String(localized: "okay")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top row: relative time + status icons
            HStack(alignment: .center) {
                Text(session.timestamp, format: .relative(presentation: .named))
                    .font(AnchorTheme.Typography.caption)
                    .anchorSecondaryText()

                Text(String(localized: "•"))
                    .anchorSecondaryText()

                Text(session.formattedDuration)
                    .font(AnchorTheme.Typography.caption)
                    .anchorSecondaryText()

                Spacer()

                if session.crisisDetected {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AnchorTheme.Colors.crisisRed)
                        .font(.caption)
                        .accessibilityLabel(String(localized: "Crisis detected"))
                }

                if session.completed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AnchorTheme.Colors.sageLeaf)
                        .font(.caption)
                        .accessibilityLabel(String(localized: "Completed"))
                }
            }

            // Summary
            if !session.summary.isEmpty {
                Text(session.summary)
                    .font(AnchorTheme.Typography.bodyText)
                    .anchorPrimaryText()
                    .lineLimit(2)
            }

            // Bottom row: mood arc + tags
            HStack(spacing: 12) {
                if let mood = moodEmoji {
                    HStack(spacing: 4) {
                        Text(mood.before)
                            .font(.system(size: 16))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 9, weight: .bold))
                            .anchorSecondaryText()
                            .accessibilityHidden(true)
                        Text(mood.after)
                            .font(.system(size: 16))
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        String.localizedStringWithFormat(
                            String(localized: "Mood: %@ to %@"),
                            moodWord(session.moodBefore),
                            moodWord(session.moodAfter)
                        )
                    )
                }

                if !session.tags.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(session.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AnchorTheme.Colors.warmStone)
                                .foregroundStyle(AnchorTheme.Colors.quietInk)
                                .clipShape(Capsule())
                        }
                    }
                }

                Spacer()
            }
        }
        .anchorCard()
        .padding(.vertical, 2)
    }
}

struct SessionDetailView: View {
    @Bindable var session: Session
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showingShareOptions = false
    @State private var preparingPDFShare = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Session Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "Session Details"))
                            .font(AnchorTheme.Typography.headline)
                            .anchorPrimaryText()

                        InfoRow(
                            label: String(localized: "Date"),
                            value: session.timestamp.formatted(date: .long, time: .shortened))
                        InfoRow(
                            label: String(localized: "When"),
                            value: session.timestamp.formatted(.relative(presentation: .named)))
                        InfoRow(
                            label: String(localized: "Duration"), value: session.formattedDuration)
                        InfoRow(
                            label: String(localized: "Status"),
                            value: session.completed
                                ? String(localized: "Completed") : String(localized: "Interrupted"))

                        if session.crisisDetected {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(AnchorTheme.Colors.crisisRed)
                                Text(String(localized: "Crisis keywords detected"))
                                    .foregroundColor(AnchorTheme.Colors.crisisRed)
                            }
                            .font(AnchorTheme.Typography.subheadline)
                        }
                    }
                    .anchorCard()

                    // Mood
                    if let moodBefore = session.moodBefore, let moodAfter = session.moodAfter {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(localized: "Mood"))
                                .font(AnchorTheme.Typography.headline)
                                .anchorPrimaryText()

                            HStack {
                                VStack {
                                    Text(String(localized: "Before"))
                                        .font(AnchorTheme.Typography.caption)
                                        .anchorSecondaryText()
                                    MoodIndicator(level: moodBefore)
                                }

                                Spacer()

                                Image(systemName: "arrow.right")
                                    .anchorSecondaryText()
                                    .accessibilityHidden(true)

                                Spacer()

                                VStack {
                                    Text(String(localized: "After"))
                                        .font(AnchorTheme.Typography.caption)
                                        .anchorSecondaryText()
                                    MoodIndicator(level: moodAfter)
                                }
                            }
                        }
                        .anchorCard()
                    }

                    // Homework
                    if !(session.homeworkItems ?? []).isEmpty || !(session.homework ?? "").isEmpty {
                        let homeworkItems = session.homeworkItems ?? []
                        let completedItems = Set(session.completedHomeworkItems ?? [])
                        let isHomeworkDone =
                            !homeworkItems.isEmpty
                            ? completedItems.count == homeworkItems.count
                            : session.homeworkCompleted

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(String(localized: "Home Practice"))
                                    .font(AnchorTheme.Typography.headline)
                                    .anchorPrimaryText()
                                Spacer()
                                if isHomeworkDone {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AnchorTheme.Colors.sageLeaf)
                                        .font(.title2)
                                }
                            }

                            if !homeworkItems.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(homeworkItems, id: \.self) { item in
                                        Button {
                                            var updated = Set(session.completedHomeworkItems ?? [])
                                            if updated.contains(item) {
                                                updated.remove(item)
                                            } else {
                                                updated.insert(item)
                                            }
                                            session.completedHomeworkItems = Array(updated).sorted()
                                            session.homeworkCompleted = updated.count
                                                == homeworkItems.count
                                        } label: {
                                            HStack(alignment: .top, spacing: 10) {
                                                Image(
                                                    systemName: completedItems.contains(item)
                                                        ? "checkmark.circle.fill" : "circle"
                                                )
                                                .foregroundColor(
                                                    completedItems.contains(item)
                                                        ? AnchorTheme.Colors.sageLeaf
                                                        : AnchorTheme.Colors.quietInkSecondary
                                                )
                                                .padding(.top, 2)
                                                .accessibilityHidden(true)
                                                Text(item)
                                                    .font(AnchorTheme.Typography.bodyText)
                                                    .anchorPrimaryText()
                                                    .multilineTextAlignment(.leading)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            } else if let homework = session.homework {
                                Text(homework)
                                    .font(AnchorTheme.Typography.bodyText)
                                    .anchorPrimaryText()
                            }

                            if !isHomeworkDone {
                                Button {
                                    withAnimation {
                                        if !homeworkItems.isEmpty {
                                            session.completedHomeworkItems = homeworkItems
                                            session.homeworkCompleted = true
                                        } else {
                                            session.homeworkCompleted = true
                                        }
                                    }
                                } label: {
                                    Label(
                                        !homeworkItems.isEmpty
                                            ? String(localized: "Mark All as Complete")
                                            : String(localized: "Mark as Complete"),
                                        systemImage: "checkmark"
                                    )
                                    .font(AnchorTheme.Typography.subheadline)
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(
                                    AnchorPillButtonStyle(
                                        background: AnchorTheme.Colors.sageLeaf,
                                        foreground: AnchorTheme.Colors.softParchment))
                            }
                        }
                        .anchorCard()
                    }

                    if let focusRaw = session.sessionFocus {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(localized: "Session Focus"))
                                .font(AnchorTheme.Typography.headline)
                                .anchorPrimaryText()

                            Text(SessionFocus(rawValue: focusRaw)?.title ?? focusRaw)
                                .font(AnchorTheme.Typography.bodyText)
                                .anchorPrimaryText()

                            if let focus = SessionFocus(rawValue: focusRaw) {
                                Text(focus.subtitle)
                                    .font(AnchorTheme.Typography.caption)
                                    .anchorSecondaryText()
                            }
                        }
                        .anchorCard()
                    }

                    if !(session.moodTriggers ?? []).isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(localized: "Mood Triggers"))
                                .font(AnchorTheme.Typography.headline)
                                .anchorPrimaryText()

                            FlowLayout(spacing: 8) {
                                ForEach(session.moodTriggers ?? [], id: \.self) { trigger in
                                    Text(MoodTriggerTag.label(for: trigger))
                                        .font(AnchorTheme.Typography.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(AnchorTheme.Colors.warmStone)
                                        .foregroundColor(AnchorTheme.Colors.quietInk)
                                        .cornerRadius(14)
                                }
                            }
                        }
                        .anchorCard()
                    }

                    if let stress = session.voiceStressScore {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(localized: "Voice Stress"))
                                .font(AnchorTheme.Typography.headline)
                                .anchorPrimaryText()

                            HStack {
                                Text(
                                    String.localizedStringWithFormat(
                                        String(localized: "%lld / 100"),
                                        Int64(stress)
                                    )
                                )
                                .font(AnchorTheme.Typography.heading(size: 24))
                                .foregroundColor(stressColor(stress))

                                Spacer()

                                Text(stressLabel(stress))
                                    .font(AnchorTheme.Typography.caption)
                                    .anchorSecondaryText()
                            }

                            Text(
                                String(
                                    localized:
                                        "Estimated from your speech patterns during the session.")
                            )
                            .font(AnchorTheme.Typography.caption)
                            .anchorSecondaryText()
                        }
                        .anchorCard()
                    }

                    // Summary
                    if !session.summary.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(localized: "Summary"))
                                .font(AnchorTheme.Typography.headline)
                                .anchorPrimaryText()

                            Text(session.summary)
                                .font(AnchorTheme.Typography.bodyText)
                                .anchorSecondaryText()
                        }
                        .anchorCard()
                    }

                    SessionNotesCardView(
                        payload: SessionSummaryPayload(session: session),
                        summaryStatus: .ready
                    )

                    // Tags
                    if !session.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(localized: "Topics"))
                                .font(AnchorTheme.Typography.headline)
                                .anchorPrimaryText()

                            FlowLayout(spacing: 8) {
                                ForEach(session.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(AnchorTheme.Typography.caption)
                                        .lineLimit(1)
                                        .fixedSize(horizontal: true, vertical: false)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(AnchorTheme.Colors.warmStone)
                                        .foregroundColor(AnchorTheme.Colors.quietInk)
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .anchorCard()
                    }

                    Button {
                        showingShareOptions = true
                    } label: {
                        Label(
                            String(localized: "Share Summary"), systemImage: "square.and.arrow.up"
                        )
                        .font(AnchorTheme.Typography.subheadline)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(
                        AnchorPillButtonStyle(
                            background: AnchorTheme.Colors.sageLeaf,
                            foreground: AnchorTheme.Colors.softParchment))
                }
                .padding()
            }
            .navigationTitle(String(localized: "Session"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "Done")) {
                        dismiss()
                    }
                }
            }
        }
        .anchorScreenBackground()
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: shareItems)
        }
        .sheet(isPresented: $showingShareOptions) {
            ShareOptionsSheet(
                title: String(localized: "Share Session"),
                subtitle: String(localized: "Choose how you’d like to share this check-in."),
                actions: shareOptions,
                onDismiss: { showingShareOptions = false }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    @MainActor
    private func shareSummaryCard() {
        let payload = SessionSummaryPayload(session: session)
        let card = SessionSummaryShareCardView(payload: payload)
            .frame(width: 380)
            .padding(20)
            .background(Color.white)

        let renderer = ImageRenderer(content: card)
        renderer.scale = max(displayScale, 3)
        let fallbackText =
            session.summary.isEmpty
            ? String.localizedStringWithFormat(
                String(localized: "Anchor session on %@"),
                session.timestamp.formatted(date: .abbreviated, time: .shortened)
            )
            : session.summary
        if let image = renderer.uiImage {
            shareItems = [image, fallbackText]
        } else {
            shareItems = [fallbackText]
        }
        showingShareSheet = !shareItems.isEmpty
    }

    @MainActor
    private func shareNotesCard() {
        let card = SessionNotesShareCardView(
            payload: SessionSummaryPayload(session: session),
            summaryStatus: .ready
        )
        .frame(width: 380)
        .padding(20)
        .background(Color.white)

        let renderer = ImageRenderer(content: card)
        renderer.scale = max(displayScale, 3)
        if let image = renderer.uiImage {
            shareItems = [image, sessionNotesText()]
        } else {
            shareItems = [sessionNotesText()]
        }
        showingShareSheet = !shareItems.isEmpty
    }

    private var shareOptions: [ShareOption] {
        var options: [ShareOption] = [
            ShareOption(
                title: String(localized: "Share Summary Card"),
                subtitle: String(localized: "A clean card with highlights."),
                systemImage: "square.and.arrow.up",
                action: { shareSummaryCard() }
            )
        ]

        if hasSessionNotes {
            options.append(
                ShareOption(
                    title: String(localized: "Share Notes Card"),
                    subtitle: String(localized: "Supportive notes as a card."),
                    systemImage: "doc.richtext",
                    action: { shareNotesCard() }
                )
            )
            options.append(
                ShareOption(
                    title: String(localized: "Export PDF"),
                    subtitle: String(localized: "Therapist-ready PDF notes."),
                    systemImage: "arrow.down.doc",
                    action: { sharePDF() }
                )
            )
        }

        return options
    }

    private var hasSessionNotes: Bool {
        let hasMood = !(session.observedMood ?? "").isEmpty
        let hasStrategies = !(session.copingStrategies ?? []).isEmpty
        let hasFollowUp = !(session.suggestedFollowUp ?? "").isEmpty
        let hasNarrative = !(session.narrativeSummary ?? "").isEmpty
        let hasInsight = !(session.keyInsight ?? "").isEmpty
        let hasMoodJourney =
            !(session.moodStartDescription ?? "").isEmpty
            || !(session.moodEndDescription ?? "").isEmpty
            || !(session.moodShiftDescription ?? "").isEmpty
        let hasExplored = !(session.copingStrategiesExplored ?? []).isEmpty
        let hasCopingDetail = !(session.copingStrategiesAttempted ?? []).isEmpty
            || !(session.copingStrategiesWorked ?? []).isEmpty
            || !(session.copingStrategiesDidntWork ?? []).isEmpty
        let hasTherapistItems = !(session.actionItemsForTherapist ?? []).isEmpty
        let hasUserItems = !(session.actionItemsForUser ?? []).isEmpty
        let hasPattern = !(session.recurringPatternAlert ?? "").isEmpty
        let hasAdvancedPattern = !(session.patternRecognized ?? "").isEmpty
            || !(session.primaryFocus ?? "").isEmpty
            || !(session.relatedThemes ?? []).isEmpty
            || !(session.recurringTopicsSnapshot ?? []).isEmpty
            || !(session.recurringTopicsTrend ?? "").isEmpty
        let hasMoodDetail = session.moodStartIntensity != nil
            || session.moodEndIntensity != nil
            || !(session.moodStartPhysicalSymptoms ?? []).isEmpty
            || !(session.moodEndPhysicalSymptoms ?? []).isEmpty
        let hasHomework =
            !(session.homework ?? "").isEmpty
            || !(session.homeworkItems ?? []).isEmpty
        let hasProgress = !(session.previousHomeworkAssigned ?? "").isEmpty
            || !(session.previousHomeworkCompletion ?? "").isEmpty
            || !(session.previousHomeworkReflection ?? "").isEmpty
            || !(session.therapyGoalProgress ?? []).isEmpty
        let hasContinuity = !(session.continuityPeopleMentioned ?? []).isEmpty
            || !(session.continuityUpcomingEvents ?? []).isEmpty
            || !(session.continuityEnvironmentalFactors ?? []).isEmpty
        let hasSafety = session.crisisRiskDetectedByModel != nil
            || !(session.crisisNotes ?? "").isEmpty
            || !(session.protectiveFactors ?? []).isEmpty
            || !(session.safetyRecommendation ?? "").isEmpty
        let hasClinical = !(session.dominantEmotions ?? []).isEmpty
            || !(session.primaryCopingStyle ?? "").isEmpty
            || session.sessionEffectivenessSelfRating != nil
        return hasMood || hasStrategies || hasFollowUp || hasNarrative
            || hasInsight || hasMoodJourney || hasExplored || hasTherapistItems
            || hasPattern || hasHomework || hasCopingDetail || hasUserItems
            || hasAdvancedPattern || hasMoodDetail || hasProgress || hasContinuity
            || hasSafety || hasClinical
    }

    private func sessionShareText() -> String {
        var lines: [String] = []
        lines.append(String(localized: "Anchor Session"))
        lines.append(session.timestamp.formatted(date: .abbreviated, time: .shortened))
        if !session.summary.isEmpty {
            lines.append("")
            lines.append(session.summary)
        }
        if !session.tags.isEmpty {
            let topicsText = session.tags.prefix(4).joined(separator: ", ")
            lines.append("")
            lines.append(
                String.localizedStringWithFormat(String(localized: "Topics: %@"), topicsText))
        }
        if let focus = session.sessionFocus {
            let focusLabel = SessionFocus(rawValue: focus)?.title ?? focus
            lines.append("")
            lines.append(
                String.localizedStringWithFormat(String(localized: "Focus: %@"), focusLabel))
        }
        if session.moodBefore != nil, session.moodAfter != nil {
            lines.append("")
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Mood: %@ → %@"),
                    moodWord(session.moodBefore),
                    moodWord(session.moodAfter)
                )
            )
        }
        if let followUp = session.suggestedFollowUp, !followUp.isEmpty {
            lines.append("")
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Suggested follow-up: %@"), followUp))
        }

        if let focus = session.primaryFocus, !focus.isEmpty {
            lines.append("")
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Primary focus: %@"),
                    focus
                )
            )
        }
        if let themes = session.relatedThemes, !themes.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Related themes: %@"),
                    themes.joined(separator: ", ")
                )
            )
        }
        if let pattern = session.patternRecognized, !pattern.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Pattern recognized: %@"),
                    pattern
                )
            )
        }
        if let snapshots = session.recurringTopicsSnapshot, !snapshots.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Recurring topics snapshot: %@"),
                    snapshots.joined(separator: ", ")
                )
            )
        }
        if let trend = session.recurringTopicsTrend, !trend.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Recurring trend: %@"),
                    trend
                )
            )
        }

        if let startIntensity = session.moodStartIntensity {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Mood intensity start: %lld/10"),
                    Int64(startIntensity)
                )
            )
        }
        if let endIntensity = session.moodEndIntensity {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Mood intensity end: %lld/10"),
                    Int64(endIntensity)
                )
            )
        }
        if let startPhysical = session.moodStartPhysicalSymptoms, !startPhysical.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Start physical cues: %@"),
                    startPhysical.joined(separator: ", ")
                )
            )
        }
        if let endPhysical = session.moodEndPhysicalSymptoms, !endPhysical.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "End physical cues: %@"),
                    endPhysical.joined(separator: ", ")
                )
            )
        }

        if let attempted = session.copingStrategiesAttempted, !attempted.isEmpty {
            lines.append("")
            lines.append(String(localized: "Coping attempted:"))
            for item in attempted {
                lines.append("• \(item)")
            }
        }
        if let worked = session.copingStrategiesWorked, !worked.isEmpty {
            lines.append("")
            lines.append(String(localized: "What helped:"))
            for item in worked {
                lines.append("• \(item)")
            }
        }
        if let didnt = session.copingStrategiesDidntWork, !didnt.isEmpty {
            lines.append("")
            lines.append(String(localized: "What did not help:"))
            for item in didnt {
                lines.append("• \(item)")
            }
        }

        if let previousHomework = session.previousHomeworkAssigned, !previousHomework.isEmpty {
            lines.append("")
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Previous homework: %@"),
                    previousHomework
                )
            )
        }
        if let completion = session.previousHomeworkCompletion, !completion.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Previous homework completion: %@"),
                    completion
                )
            )
        }
        if let reflection = session.previousHomeworkReflection, !reflection.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Previous homework reflection: %@"),
                    reflection
                )
            )
        }
        if let goalProgress = session.therapyGoalProgress, !goalProgress.isEmpty {
            lines.append("")
            lines.append(String(localized: "Therapy goal progress:"))
            for goal in goalProgress {
                lines.append("• \(goal)")
            }
        }
        if let userActions = session.actionItemsForUser, !userActions.isEmpty {
            lines.append("")
            lines.append(String(localized: "Action items for you:"))
            for action in userActions {
                lines.append("• \(action)")
            }
        }
        if let people = session.continuityPeopleMentioned, !people.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "People mentioned: %@"),
                    people.joined(separator: "; ")
                )
            )
        }
        if let events = session.continuityUpcomingEvents, !events.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Upcoming events: %@"),
                    events.joined(separator: "; ")
                )
            )
        }
        if let environment = session.continuityEnvironmentalFactors, !environment.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Environmental factors: %@"),
                    environment.joined(separator: "; ")
                )
            )
        }

        if let risk = session.crisisRiskDetectedByModel {
            lines.append("")
            lines.append(
                risk
                    ? String(localized: "Model safety risk detected: yes")
                    : String(localized: "Model safety risk detected: no")
            )
        }
        if let notes = session.crisisNotes, !notes.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Safety notes: %@"),
                    notes
                )
            )
        }
        if let factors = session.protectiveFactors, !factors.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Protective factors: %@"),
                    factors.joined(separator: ", ")
                )
            )
        }
        if let recommendation = session.safetyRecommendation, !recommendation.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Safety recommendation: %@"),
                    recommendation
                )
            )
        }
        if let emotions = session.dominantEmotions, !emotions.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Dominant emotions: %@"),
                    emotions.joined(separator: ", ")
                )
            )
        }
        if let copingStyle = session.primaryCopingStyle, !copingStyle.isEmpty {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Primary coping style: %@"),
                    copingStyle
                )
            )
        }
        if let rating = session.sessionEffectivenessSelfRating {
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Session effectiveness: %lld/10"),
                    Int64(rating)
                )
            )
        }
        lines.append("")
        lines.append(String(localized: "(No transcripts included)"))
        return lines.joined(separator: "\n")
    }

    private func sessionNotesText() -> String {
        var lines: [String] = []
        lines.append(String(localized: "Session Notes"))
        lines.append(session.timestamp.formatted(date: .abbreviated, time: .shortened))

        if let narrative = session.narrativeSummary, !narrative.isEmpty {
            lines.append("")
            lines.append(
                String.localizedStringWithFormat(String(localized: "Summary: %@"), narrative))
        }

        if let moodStart = session.moodStartDescription, !moodStart.isEmpty {
            lines.append("")
            lines.append(
                String.localizedStringWithFormat(String(localized: "Mood start: %@"), moodStart))
        }
        if let moodEnd = session.moodEndDescription, !moodEnd.isEmpty {
            lines.append(
                String.localizedStringWithFormat(String(localized: "Mood end: %@"), moodEnd))
        }
        if let moodShift = session.moodShiftDescription, !moodShift.isEmpty {
            lines.append(
                String.localizedStringWithFormat(String(localized: "Shift: %@"), moodShift))
        }

        if let observed = session.observedMood, !observed.isEmpty,
            (session.moodStartDescription ?? "").isEmpty
        {
            lines.append("")
            lines.append(
                String.localizedStringWithFormat(String(localized: "Observed mood: %@"), observed))
        }

        if let insight = session.keyInsight, !insight.isEmpty {
            lines.append("")
            lines.append(
                String.localizedStringWithFormat(String(localized: "Key insight: %@"), insight))
        }
        if let quotes = session.userQuotes, !quotes.isEmpty {
            for quote in quotes {
                lines.append(
                    String.localizedStringWithFormat(String(localized: "\u{201C}%@\u{201D}"), quote)
                )
            }
        }

        let explored = session.copingStrategiesExplored ?? []
        if !explored.isEmpty {
            lines.append("")
            let strategyList = explored.joined(separator: "\n  • ")
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Coping strategies:\n  • %@"), strategyList))
        } else {
            let strategies = session.copingStrategies ?? []
            if !strategies.isEmpty {
                lines.append("")
                let strategyList = strategies.joined(separator: ", ")
                lines.append(
                    String.localizedStringWithFormat(
                        String(localized: "Coping strategies: %@"), strategyList))
            }
        }

        if let items = session.actionItemsForTherapist, !items.isEmpty {
            lines.append("")
            let itemList = items.joined(separator: "\n  → ")
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "For your therapist:\n  → %@"), itemList))
        }

        if let pattern = session.recurringPatternAlert, !pattern.isEmpty {
            lines.append("")
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Recurring pattern: %@"), pattern))
        }

        if let followUp = session.suggestedFollowUp, !followUp.isEmpty {
            lines.append("")
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Suggested follow-up: %@"), followUp))
        }

        let completedItems = Set(session.completedHomeworkItems ?? [])
        let homeworkItems = session.homeworkItems ?? []
        if !homeworkItems.isEmpty {
            lines.append("")
            lines.append(String(localized: "Home practice:"))
            for item in homeworkItems {
                let marker = completedItems.contains(item) ? "✅" : "•"
                lines.append("\(marker) \(item)")
            }
        } else if let homework = session.homework, !homework.isEmpty {
            lines.append("")
            lines.append(
                String.localizedStringWithFormat(
                    String(localized: "Home practice: %@"),
                    homework
                )
            )
        }

        lines.append("")
        lines.append(String(localized: "Supportive notes — not a clinical record."))
        lines.append(String(localized: "(No transcripts included)"))
        return lines.joined(separator: "\n")
    }

    @MainActor
    private func sharePDF() {
        guard !preparingPDFShare else { return }
        let payload = SessionSummaryPayload(session: session)
        preparingPDFShare = true
        DispatchQueue.global(qos: .userInitiated).async {
            let url = SessionPDFExporter.generatePDF(from: payload)
            DispatchQueue.main.async {
                preparingPDFShare = false
                guard let url else { return }
                shareItems = [url]
                showingShareSheet = true
            }
        }
    }

    private func moodWord(_ level: Int?) -> String {
        guard let level else { return String(localized: "unknown") }
        switch level {
        case 1: return String(localized: "very low")
        case 2: return String(localized: "low")
        case 3: return String(localized: "okay")
        case 4: return String(localized: "good")
        case 5: return String(localized: "great")
        default: return String(localized: "okay")
        }
    }

    private func stressLabel(_ score: Double) -> String {
        switch score {
        case ..<30: return String(localized: "Low")
        case 30..<60: return String(localized: "Moderate")
        default: return String(localized: "High")
        }
    }

    private func stressColor(_ score: Double) -> Color {
        switch score {
        case ..<30: return AnchorTheme.Colors.sageLeaf
        case 30..<60: return AnchorTheme.Colors.warmSand
        default: return AnchorTheme.Colors.crisisRed
        }
    }
}

struct HistorySummaryCard: View {
    let totalSessions: Int
    let currentStreak: Int
    let averageMoodDelta: Double?
    let topTags: [String]
    let topTriggers: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Highlights"))
                .font(AnchorTheme.Typography.headline)
                .anchorPrimaryText()

            HStack(spacing: 12) {
                HistorySummaryStat(
                    label: String(localized: "Sessions"), value: String(totalSessions))
                HistorySummaryStat(
                    label: String(localized: "Streak"),
                    value: currentStreak > 0
                        ? String.localizedStringWithFormat(
                            String(localized: "%lld days"), Int64(currentStreak))
                        : String(localized: "—")
                )
                HistorySummaryStat(
                    label: String(localized: "Avg shift"), value: averageMoodDeltaText)
            }

            if !topTags.isEmpty || !topTriggers.isEmpty {
                Divider()
                    .background(AnchorTheme.Colors.warmSand.opacity(0.4))
            }

            if !topTags.isEmpty {
                SummaryTagRow(title: String(localized: "Top topics"), items: topTags)
            }

            if !topTriggers.isEmpty {
                SummaryTagRow(title: String(localized: "Top triggers"), items: topTriggers)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AnchorTheme.Colors.warmStone)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AnchorTheme.Colors.warmSand.opacity(0.2), lineWidth: 1)
        )
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var averageMoodDeltaText: String {
        guard let averageMoodDelta else { return "—" }
        return String(format: "%+.1f", averageMoodDelta)
    }

    private var accessibilitySummary: String {
        var parts: [String] = []
        parts.append(String(localized: "Highlights"))
        parts.append(
            String.localizedStringWithFormat(
                String(localized: "Sessions %lld"), Int64(totalSessions)))
        if currentStreak > 0 {
            parts.append(
                String.localizedStringWithFormat(
                    String(localized: "Streak %lld days"), Int64(currentStreak)))
        } else {
            parts.append(String(localized: "Streak none"))
        }
        if let averageMoodDelta {
            let averageShiftText = String(format: "%+.1f", averageMoodDelta)
            parts.append(
                String.localizedStringWithFormat(
                    String(localized: "Average shift %@"), averageShiftText))
        } else {
            parts.append(String(localized: "Average shift unavailable"))
        }
        if !topTags.isEmpty {
            let topTopicsText = topTags.prefix(2).joined(separator: ", ")
            parts.append(
                String.localizedStringWithFormat(String(localized: "Top topics %@"), topTopicsText))
        }
        if !topTriggers.isEmpty {
            let topTriggersText = topTriggers.prefix(2).joined(separator: ", ")
            parts.append(
                String.localizedStringWithFormat(
                    String(localized: "Top triggers %@"), topTriggersText))
        }
        return parts.joined(separator: ", ")
    }
}

struct HistorySummaryStat: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AnchorTheme.Typography.caption)
                .anchorSecondaryText()
            Text(value)
                .font(AnchorTheme.Typography.subheadline)
                .anchorPrimaryText()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SummaryTagRow: View {
    let title: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AnchorTheme.Typography.caption)
                .anchorSecondaryText()

            Text(displayItems.joined(separator: " • "))
                .font(AnchorTheme.Typography.subheadline)
                .anchorPrimaryText()
                .lineLimit(1)
        }
    }

    private var displayItems: [String] {
        let maxItems = 2
        guard items.count > maxItems else { return items }
        let remaining = items.count - maxItems
        return Array(items.prefix(maxItems))
            + [String.localizedStringWithFormat(String(localized: "+%lld"), Int64(remaining))]
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(AnchorTheme.Typography.caption)
                .anchorSecondaryText()
            Spacer()
            Text(value)
                .font(AnchorTheme.Typography.bodyText)
                .anchorPrimaryText()
        }
    }
}

struct ShareOption: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void
}

struct ShareOptionsSheet: View {
    let title: String
    let subtitle: String
    let actions: [ShareOption]
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 6) {
                Text(title)
                    .font(AnchorTheme.Typography.headline)
                    .anchorPrimaryText()
                Text(subtitle)
                    .font(AnchorTheme.Typography.caption)
                    .anchorSecondaryText()
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(actions) { action in
                        Button {
                            action.action()
                            onDismiss()
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(AnchorTheme.Colors.warmStone)
                                        .frame(width: 40, height: 40)
                                    Image(systemName: action.systemImage)
                                        .foregroundColor(AnchorTheme.Colors.quietInk)
                                        .font(.system(size: 16, weight: .semibold))
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(action.title)
                                        .font(AnchorTheme.Typography.subheadline)
                                        .anchorPrimaryText()
                                    Text(action.subtitle)
                                        .font(AnchorTheme.Typography.smallCaption)
                                        .anchorSecondaryText()
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(AnchorTheme.Colors.quietInkSecondary)
                                    .font(.caption)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(AnchorTheme.Colors.warmStone)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AnchorTheme.Colors.warmSand.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 4)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button(String(localized: "Cancel")) {
                onDismiss()
                dismiss()
            }
            .buttonStyle(
                AnchorPillButtonStyle(
                    background: AnchorTheme.Colors.warmStone,
                    foreground: AnchorTheme.Colors.quietInk
                )
            )
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(AnchorTheme.Colors.softParchment)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AnchorTheme.Colors.softParchment.ignoresSafeArea())
        .onDisappear {
            onDismiss()
        }
    }
}

struct MoodIndicator: View {
    let level: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { index in
                Circle()
                    .fill(index <= level ? color(for: level) : AnchorTheme.Colors.warmStone)
                    .frame(width: 12, height: 12)
            }
        }
    }

    private func color(for level: Int) -> Color {
        let base = AnchorTheme.Colors.sageLeaf
        switch level {
        case 1...2: return base.opacity(0.3)
        case 3: return base.opacity(0.5)
        case 4: return base.opacity(0.7)
        case 5: return base
        default: return base.opacity(0.3)
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
            .modelContainer(for: Session.self, inMemory: true)
    }
}
