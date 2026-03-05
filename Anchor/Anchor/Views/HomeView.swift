//
//  HomeView.swift
//  Anchor
//
//  Created for Anchor - AI-Powered Emotional Support
//

import SwiftUI
import SwiftData
import UIKit

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(DeepLinkRouter.self) private var deepLinkRouter
    @Query private var settings: [UserSettings]
    @Query(sort: \Session.timestamp, order: .reverse) private var sessions: [Session]
    
    @State private var showingConversation = false
    @State private var showingSafetyDisclaimer = false
    @State private var showingLimitAlert = false
    @State private var showingSubscriptionSheet = false
    @State private var deepLinkNavigation: DeepLinkDestination?
    @State private var showingAnchorMoment = false
    
    private var userSettings: UserSettings? {
        settings.first
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let base: String
        switch hour {
        case 5..<12: base = String(localized: "Good morning")
        case 12..<17: base = String(localized: "Good afternoon")
        case 17..<22: base = String(localized: "Good evening")
        default: base = String(localized: "Welcome")
        }
        if let name = userSettings?.userName, !name.isEmpty {
            return String.localizedStringWithFormat(String(localized: "%@, %@"), base, name)
        }
        return base
    }

    private var accessStatusText: String? {
        guard let settings = userSettings else { return nil }
        if settings.isSubscribed {
            return String(localized: "Premium active")
        }
        if settings.isInTrialPeriod, let daysRemaining = settings.trialDaysRemaining {
            let dayLabel = daysRemaining == 1 ? String(localized: "day") : String(localized: "days")
            return String.localizedStringWithFormat(
                String(localized: "Trial: %lld %@ remaining"),
                Int64(daysRemaining),
                dayLabel
            )
        }
        let remaining = settings.remainingFreeSeconds()
        return String.localizedStringWithFormat(
            String(localized: "Free time left today: %@"),
            formattedMinutes(remaining)
        )
    }

    private var latestSession: Session? {
        sessions.first
    }

    private var takeawayTitle: String {
        guard let session = latestSession else { return String(localized: "Today’s focus") }
        return session.summary.isEmpty ? String(localized: "Today’s focus") : String(localized: "Last takeaway")
    }

    private var takeawayBody: String {
        guard let session = latestSession else {
            return String(localized: "Your first check-in starts here.")
        }
        if !session.summary.isEmpty {
            return session.summary
        }
        if let focusRaw = session.sessionFocus, !focusRaw.isEmpty {
            return SessionFocus(rawValue: focusRaw)?.title ?? focusRaw
        }
        return String(localized: "Show up with one small check-in.")
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text(greeting)
                        .font(AnchorTheme.Typography.title)
                        .anchorPrimaryText()

                    Text(String(localized: "I’m here with you."))
                        .font(AnchorTheme.Typography.subheadline)
                        .anchorSecondaryText()
                    if let streak = userSettings?.currentStreak, streak > 1 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                            Text(
                                String.localizedStringWithFormat(
                                    String(localized: "%lld-day streak"),
                                    Int64(streak)
                                )
                            )
                                .anchorSecondaryText()
                        }
                        .font(AnchorTheme.Typography.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AnchorTheme.Colors.warmStone)
                        .cornerRadius(16)
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(
                            String.localizedStringWithFormat(
                                String(localized: "%lld day streak"),
                                Int64(streak)
                            )
                        )
                    }
                }
                .padding(.top, 28)

                HomePresenceOrb(size: 170)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    Text(takeawayTitle)
                        .font(AnchorTheme.Typography.caption)
                        .anchorSecondaryText()

                    Text(takeawayBody)
                        .font(AnchorTheme.Typography.bodyText)
                        .anchorPrimaryText()
                        .lineLimit(3)
                }
                .anchorCard()
                .frame(minHeight: 120, alignment: .leading)
                .padding(.horizontal, 6)

                if let accessStatusText {
                    Text(accessStatusText)
                        .font(AnchorTheme.Typography.caption)
                        .anchorSecondaryText()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AnchorTheme.Colors.warmStone)
                        .cornerRadius(14)
                }

                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    startConversation()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .accessibilityHidden(true)
                        Text(String(localized: "Start Conversation"))
                            .font(AnchorTheme.Typography.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(AnchorPillButtonStyle(
                    background: AnchorTheme.Colors.sageLeaf,
                    foreground: AnchorTheme.Colors.softParchment
                ))
                .accessibilityLabel(String(localized: "Start conversation"))
                .accessibilityHint(String(localized: "Begin a voice conversation with Anchor"))
                .accessibilityIdentifier("home.startConversation")
                .padding(.horizontal, 8)

                HStack(spacing: 16) {
                    NavigationLink(destination: EmergencyResourcesView()) {
                        HomeCircleButton(
                            label: String(localized: "SOS"),
                            textColor: AnchorTheme.Colors.crisisRed
                        )
                    }
                    .accessibilityLabel(String(localized: "Emergency resources"))
                    .accessibilityHint(String(localized: "View crisis hotlines and support"))
                    .accessibilityIdentifier("home.sos")

                    NavigationLink(destination: BreathingExerciseView()) {
                        HomeCircleButton(
                            icon: "wind",
                            iconSize: 18
                        )
                    }
                    .accessibilityLabel(String(localized: "Breathing exercise"))
                    .accessibilityHint(String(localized: "Start a guided breathing exercise"))
                    .accessibilityIdentifier("home.breathing")

                    NavigationLink(destination: InsightsView()) {
                        HomeCircleButton(
                            icon: "chart.line.uptrend.xyaxis",
                            iconSize: 18
                        )
                    }
                    .accessibilityLabel(String(localized: "Insights"))
                    .accessibilityHint(String(localized: "View mood trends and session statistics"))
                    .accessibilityIdentifier("home.insights")

                    NavigationLink(destination: HistoryView()) {
                        HomeCircleButton(
                            icon: "clock",
                            iconSize: 18
                        )
                    }
                    .accessibilityLabel(String(localized: "History"))
                    .accessibilityHint(String(localized: "View past session summaries"))
                    .accessibilityIdentifier("home.history")
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 24)
            .background(AnchorTheme.Colors.softParchment.ignoresSafeArea())
            .navigationTitle(String(localized: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .foregroundColor(AnchorTheme.Colors.quietInk)
                    }
                    .accessibilityLabel(String(localized: "Settings"))
                    .accessibilityHint(String(localized: "Open app settings"))
                    .accessibilityIdentifier("home.settings")
                }
            }
            .sheet(isPresented: $showingConversation) {
                ConversationView()
            }
            .sheet(isPresented: $showingAnchorMoment) {
                AnchorMomentView()
            }
            .sheet(isPresented: $showingSafetyDisclaimer) {
                SafetyDisclaimerView(isPresented: $showingSafetyDisclaimer)
            }
            .sheet(isPresented: $showingSubscriptionSheet) {
                SubscriptionView()
            }
            .onAppear {
                checkSafetyDisclaimer()
                refreshDailyUsageIfNeeded()
            }
            .task(id: deepLinkRouter.pendingDestination) {
                guard let dest = deepLinkRouter.consume() else { return }
                handleDeepLink(dest)
            }
            .navigationDestination(item: $deepLinkNavigation) { dest in
                switch dest {
                case .breathing: BreathingExerciseView()
                case .insights:  InsightsView()
                case .history:   HistoryView()
                case .settings:  SettingsView()
                default:         EmptyView()
                }
            }
            .alert(String(localized: "Daily Limit Reached"), isPresented: $showingLimitAlert) {
                Button(String(localized: "View Plans")) {
                    showingSubscriptionSheet = true
                }
                Button(String(localized: "OK"), role: .cancel) {}
            } message: {
                Text(String(localized: "You’ve used your 10 minutes for today. Come back tomorrow or upgrade for unlimited conversations."))
            }
            .toolbarBackground(AnchorTheme.Colors.softParchment, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .background(AnchorTheme.Colors.softParchment, ignoresSafeAreaEdges: .all)
    }
    
    private func startConversation() {
        // Check if user has seen safety disclaimer
        guard let settings = userSettings else { return }
        settings.refreshDailyUsageIfNeeded()
        modelContext.safeSave()

        if !settings.hasSeenSafetyDisclaimer {
            showingSafetyDisclaimer = true
            return
        }

        if settings.hasUnlimitedAccess {
            showingConversation = true
        } else if settings.remainingFreeSeconds() > 0 {
            showingConversation = true
        } else {
            showingLimitAlert = true
        }
    }

    
    private func checkSafetyDisclaimer() {
        if let settings = userSettings, !settings.hasSeenSafetyDisclaimer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingSafetyDisclaimer = true
            }
        }
    }

    private func refreshDailyUsageIfNeeded() {
        guard let settings = userSettings else { return }
        settings.refreshDailyUsageIfNeeded()
        modelContext.safeSave()
    }


    private func formattedMinutes(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    private func handleDeepLink(_ dest: DeepLinkDestination) {
                switch dest {
                case .conversation:
                    startConversation()
                case .breathing, .insights, .history, .settings:
                    deepLinkNavigation = dest
                case .anchorMoment:
                    showingAnchorMoment = true
                case .home:
                    break // already here
                }
            }
}

private struct HomeCircleButton: View {
    var label: String?
    var icon: String?
    var iconSize: CGFloat = 20
    var textColor: Color = AnchorTheme.Colors.quietInk
    var iconColor: Color = AnchorTheme.Colors.quietInk
    var size: CGFloat = 48
    var fillColor: Color = AnchorTheme.Colors.warmStone

    var body: some View {
        ZStack {
            Circle()
                .fill(fillColor)
                .overlay(
                    Circle()
                        .stroke(AnchorTheme.Colors.warmSand.opacity(0.1), lineWidth: 1)
                )

            if let label {
                Text(label)
                    .font(AnchorTheme.Typography.caption)
                    .foregroundColor(textColor)
            } else if let icon {
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundColor(iconColor)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

private struct HomePresenceOrb: View {
    let size: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var corePulse = false

    private var accent: Color { AnchorTheme.Colors.accent(for: .idle) }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accent.opacity(0.28), accent.opacity(0.04)],
                        center: .center,
                        startRadius: 10,
                        endRadius: size * 0.7
                    )
                )
                .frame(width: size * 1.25, height: size * 1.25)
                .blur(radius: 28)
                .opacity(0.75)
                .accessibilityHidden(true)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [accent.opacity(0.55), accent.opacity(0.2), AnchorTheme.Colors.warmSand.opacity(0.06)],
                        center: .center,
                        startRadius: 10,
                        endRadius: size * 0.6
                    )
                )
                .frame(width: size, height: size)
                .blur(radius: 14)
                .opacity(0.78)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [accent.opacity(0.4), accent.opacity(0.12)],
                        center: .center,
                        startRadius: 4,
                        endRadius: size * 0.28
                    )
                )
                .frame(width: size * 0.5, height: size * 0.5)
                .blur(radius: 10)
                .opacity(corePulse ? 0.85 : 0.65)
                .animation(reduceMotion ? .default : .easeInOut(duration: 5.2).repeatForever(autoreverses: true), value: corePulse)
        }
        .frame(width: size * 1.25, height: size * 1.25)
        .onAppear {
            guard !reduceMotion else { return }
            corePulse = true
        }
        .onChange(of: reduceMotion) { _, reduced in
            corePulse = !reduced
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    HomeView()
        .environmentObject(NetworkMonitor())
        .environment(DeepLinkRouter())
        .modelContainer(for: [Session.self, UserSettings.self], inMemory: true)
}
