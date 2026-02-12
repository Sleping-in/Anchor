//
//  SettingsView.swift
//  Anchor
//
//  Created for Anchor - AI-Powered Emotional Support
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.displayScale) private var displayScale
    @Query private var settings: [UserSettings]
    @Query private var sessions: [Session]
    @Query private var profiles: [UserProfile]
    @State private var showingSubscriptionSheet = false
    @State private var showingSafetyResources = false
    @State private var showingDeleteConfirmation = false
    @State private var showingExportSheet = false
    @State private var exportFileURL: URL?
    @State private var showingWeeklyShareSheet = false
    @State private var showingWeeklyShareOptions = false
    @State private var weeklyShareItems: [Any] = []
    @State private var apiKeyText: String = ""
    @State private var showingResetProfileConfirmation = false
    @State private var showingSaveError = false
    
    private var userSettings: UserSettings? {
        settings.first
    }
    
    private var userProfile: UserProfile? {
        profiles.first
    }
    
    var body: some View {
        List {
            // Subscription Section
            Section {
                if let settings = userSettings {
                    if settings.isInTrialPeriod {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(String(localized: "Free Trial"))
                                .font(AnchorTheme.Typography.headline)
                                .anchorPrimaryText()
                            
                            if let daysRemaining = settings.trialDaysRemaining {
                                Text(
                                    String.localizedStringWithFormat(
                                        String(localized: "%lld days remaining"),
                                        Int64(daysRemaining)
                                    )
                                )
                                    .font(AnchorTheme.Typography.subheadline)
                                    .anchorSecondaryText()
                            }
                        }
                    } else if settings.isSubscribed {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(String(localized: "Premium"))
                                    .font(AnchorTheme.Typography.headline)
                                    .anchorPrimaryText()
                                
                                Spacer()
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AnchorTheme.Colors.sageLeaf)
                            }
                            
                            if let expiry = settings.subscriptionExpiryDate {
                                let expiryText = expiry.formatted(date: .abbreviated, time: .omitted)
                                Text(
                                    String.localizedStringWithFormat(
                                        String(localized: "Renews %@"),
                                        expiryText
                                    )
                                )
                                    .font(AnchorTheme.Typography.caption)
                                    .anchorSecondaryText()
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(String(localized: "Free Plan"))
                                .font(AnchorTheme.Typography.headline)
                                .anchorPrimaryText()
                            
                            Text(String(localized: "You can still use Anchor for 10 minutes per day."))
                                .font(AnchorTheme.Typography.subheadline)
                                .anchorSecondaryText()
                        }
                    }
                }
                
                Button(action: { showingSubscriptionSheet = true }) {
                    HStack {
                        Text(String(localized: "Manage Subscription"))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text(String(localized: "Subscription"))
            }

            // Learned Profile
            Section {
                if let profile = userProfile, profile.hasContent {
                    LabeledContent(String(localized: "Sessions analysed"), value: String(profile.sessionsAnalysed))

                    if !profile.recurringTopics.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(localized: "Recurring topics"))
                                .font(AnchorTheme.Typography.caption)
                                .anchorSecondaryText()
                            Text(profile.recurringTopics.prefix(6).joined(separator: ", "))
                                .font(AnchorTheme.Typography.subheadline)
                                .anchorPrimaryText()
                        }
                    }

                    if !profile.preferredCopingStrategies.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(localized: "Preferred coping strategies"))
                                .font(AnchorTheme.Typography.caption)
                                .anchorSecondaryText()
                            Text(profile.preferredCopingStrategies.prefix(4).joined(separator: ", "))
                                .font(AnchorTheme.Typography.subheadline)
                                .anchorPrimaryText()
                        }
                    }

                    if !profile.moodBaseline.isEmpty {
                        LabeledContent(String(localized: "Mood baseline"), value: profile.moodBaseline)
                    }

                } else {
                    Text(String(localized: "Anchor will learn your patterns after a few sessions."))
                        .font(AnchorTheme.Typography.subheadline)
                        .anchorSecondaryText()
                }
            } header: {
                Text(String(localized: "Learned Profile"))
            } footer: {
                Text(String(localized: "Built locally from your session summaries. This helps Anchor personalise conversations over time."))
            }
            Section {
                if let settings = userSettings {
                    Toggle(String(localized: "Daily Check-ins"), isOn: Binding(
                        get: { settings.notificationsEnabled },
                        set: { newValue in
                            settings.notificationsEnabled = newValue
                            modelContext.safeSave()
                            NotificationManager.shared.updateSchedule(
                                enabled: newValue,
                                preferredTime: settings.preferredCheckInTime
                            )
                        }
                    ))
                    .tint(AnchorTheme.Colors.sageLeaf)

                    Toggle(String(localized: "Set a preferred time"), isOn: Binding(
                        get: { settings.isCheckInTimeOverridden },
                        set: { newValue in
                            settings.checkInTimeOverrideEnabled = newValue
                            if newValue && settings.preferredCheckInHour == nil {
                                settings.preferredCheckInHour = 19
                                settings.preferredCheckInMinute = 0
                            }
                            if !newValue {
                                settings.preferredCheckInHour = nil
                                settings.preferredCheckInMinute = nil
                            }
                            modelContext.safeSave()
                            NotificationManager.shared.updateSchedule(
                                enabled: settings.notificationsEnabled,
                                preferredTime: settings.preferredCheckInTime
                            )
                        }
                    ))
                    .tint(AnchorTheme.Colors.sageLeaf)

                    if settings.isCheckInTimeOverridden {
                        DatePicker(
                            String(localized: "Daily Check-in Time"),
                            selection: timeBinding(
                                hour: Binding(get: { settings.preferredCheckInHour }, set: { settings.preferredCheckInHour = $0 }),
                                minute: Binding(get: { settings.preferredCheckInMinute }, set: { settings.preferredCheckInMinute = $0 }),
                                defaultHour: 19,
                                defaultMinute: 0
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: settings.preferredCheckInHour) { _, _ in
                            modelContext.safeSave()
                            NotificationManager.shared.updateSchedule(
                                enabled: settings.notificationsEnabled,
                                preferredTime: settings.preferredCheckInTime
                            )
                        }
                        .onChange(of: settings.preferredCheckInMinute) { _, _ in
                            modelContext.safeSave()
                            NotificationManager.shared.updateSchedule(
                                enabled: settings.notificationsEnabled,
                                preferredTime: settings.preferredCheckInTime
                            )
                        }
                    }

                    if let label = settings.preferredCheckInLabel {
                        Text(settings.isCheckInTimeOverridden
                             ? String.localizedStringWithFormat(String(localized: "Reminders set for %@."), label)
                             : String.localizedStringWithFormat(String(localized: "Timed around %@ based on your recent sessions."), label))
                            .font(AnchorTheme.Typography.caption)
                            .anchorSecondaryText()
                    }

                    Toggle(String(localized: "Anchor Moments"), isOn: Binding(
                        get: { settings.anchorMomentsEnabled },
                        set: { newValue in
                            settings.anchorMomentsEnabled = newValue
                            if newValue && settings.anchorMomentHour == nil {
                                settings.anchorMomentHour = 9
                                settings.anchorMomentMinute = 0
                            }
                            modelContext.safeSave()
                            NotificationManager.shared.updateAnchorMomentSchedule(
                                enabled: newValue,
                                time: settings.anchorMomentTime
                            )
                        }
                    ))
                    .tint(AnchorTheme.Colors.sageLeaf)

                    if settings.anchorMomentsEnabled {
                        DatePicker(
                            String(localized: "Anchor Moment Time"),
                            selection: timeBinding(
                                hour: Binding(get: { settings.anchorMomentHour }, set: { settings.anchorMomentHour = $0 }),
                                minute: Binding(get: { settings.anchorMomentMinute }, set: { settings.anchorMomentMinute = $0 }),
                                defaultHour: 9,
                                defaultMinute: 0
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: settings.anchorMomentHour) { _, _ in
                            modelContext.safeSave()
                            NotificationManager.shared.updateAnchorMomentSchedule(
                                enabled: settings.anchorMomentsEnabled,
                                time: settings.anchorMomentTime
                            )
                        }
                        .onChange(of: settings.anchorMomentMinute) { _, _ in
                            modelContext.safeSave()
                            NotificationManager.shared.updateAnchorMomentSchedule(
                                enabled: settings.anchorMomentsEnabled,
                                time: settings.anchorMomentTime
                            )
                        }

                        if let label = settings.anchorMomentLabel {
                            Text(String.localizedStringWithFormat(String(localized: "Anchor Moment is scheduled for %@."), label))
                                .font(AnchorTheme.Typography.caption)
                                .anchorSecondaryText()
                        }

                        NavigationLink(destination: AnchorMomentView(showsCloseButton: false)) {
                            Label(String(localized: "Try Anchor Moment"), systemImage: "sparkles")
                        }
                    }

                    Toggle(String(localized: "Weekly Sharing"), isOn: Binding(
                        get: { settings.weeklyShareEnabled },
                        set: { newValue in
                            settings.weeklyShareEnabled = newValue
                            if newValue && settings.weeklyShareHour == nil {
                                settings.weeklyShareHour = 18
                                settings.weeklyShareMinute = 0
                            }
                            modelContext.safeSave()
                            NotificationManager.shared.updateWeeklyShareSchedule(
                                enabled: newValue,
                                time: settings.weeklyShareTime
                            )
                        }
                    ))
                    .tint(AnchorTheme.Colors.sageLeaf)

                    if settings.weeklyShareEnabled {
                        DatePicker(
                            String(localized: "Weekly Reminder Time"),
                            selection: timeBinding(
                                hour: Binding(get: { settings.weeklyShareHour }, set: { settings.weeklyShareHour = $0 }),
                                minute: Binding(get: { settings.weeklyShareMinute }, set: { settings.weeklyShareMinute = $0 }),
                                defaultHour: 18,
                                defaultMinute: 0
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: settings.weeklyShareHour) { _, _ in
                            modelContext.safeSave()
                            NotificationManager.shared.updateWeeklyShareSchedule(
                                enabled: settings.weeklyShareEnabled,
                                time: settings.weeklyShareTime
                            )
                        }
                        .onChange(of: settings.weeklyShareMinute) { _, _ in
                            modelContext.safeSave()
                            NotificationManager.shared.updateWeeklyShareSchedule(
                                enabled: settings.weeklyShareEnabled,
                                time: settings.weeklyShareTime
                            )
                        }

                        if let label = settings.weeklyShareLabel {
                            Text(
                                String.localizedStringWithFormat(
                                    String(localized: "Weekly reminders scheduled for %@ on Sundays."),
                                    label
                                )
                            )
                                .font(AnchorTheme.Typography.caption)
                                .anchorSecondaryText()
                        }

                        Button(action: { showingWeeklyShareOptions = true }) {
                            Label(String(localized: "Share Weekly Summary"), systemImage: "square.and.arrow.up")
                        }
                    }
                }
            } header: {
                Text(String(localized: "Reminders"))
            } footer: {
                Text(String(localized: "Anchor learns your best check-in time and can deliver calming moments or weekly sharing nudges."))
            }

            Section {
                if let settings = userSettings {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(localized: "Conversation Persona"))
                            .font(AnchorTheme.Typography.subheadline)
                            .anchorPrimaryText()

                        Picker(String(localized: "Conversation Persona"), selection: Binding(
                            get: { settings.selectedPersona },
                            set: { newValue in
                                settings.conversationPersona = newValue.rawValue
                                modelContext.safeSave()
                            }
                        )) {
                            ForEach(ConversationPersona.allCases) { persona in
                                Text(persona.title).tag(persona)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text(settings.selectedPersona.subtitle)
                            .font(AnchorTheme.Typography.caption)
                            .anchorSecondaryText()
                    }
                }
            } header: {
                Text(String(localized: "Conversation"))
            }

            Section {
                if let settings = userSettings {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "Voice Speed"))
                            .font(AnchorTheme.Typography.subheadline)
                            .anchorPrimaryText()

                        Slider(
                            value: Binding(
                                get: { settings.voiceSpeed },
                                set: { newValue in
                                    settings.voiceSpeed = newValue
                                    modelContext.safeSave()
                                }
                            ),
                            in: 0.5...2.0,
                            step: 0.1
                        )
                        .tint(AnchorTheme.Colors.sageLeaf)
                        .accessibilityLabel(String(localized: "Voice speed"))
                        .accessibilityValue(voiceSpeedLabel(settings.voiceSpeed))

                        HStack {
                            Text(String(localized: "Slower"))
                                .font(AnchorTheme.Typography.caption)
                                .anchorSecondaryText()
                            Spacer()
                            Text(voiceSpeedLabel(settings.voiceSpeed))
                                .font(AnchorTheme.Typography.caption)
                                .foregroundColor(AnchorTheme.Colors.quietInk)
                            Spacer()
                            Text(String(localized: "Faster"))
                                .font(AnchorTheme.Typography.caption)
                                .anchorSecondaryText()
                        }
                    }
                }
            } header: {
                Text(String(localized: "Audio"))
            }

            // Security
            Section {
                if let settings = userSettings {
                    Toggle(String(localized: "Require Face ID"), isOn: Binding(
                        get: { settings.appLockEnabled ?? false },
                        set: { newValue in
                            settings.appLockEnabled = newValue
                            modelContext.safeSave()
                        }
                    ))
                    .tint(AnchorTheme.Colors.sageLeaf)

                    Text(String(localized: "Locks Anchor when you leave the app. Face ID or device passcode will be required to reopen."))
                        .font(AnchorTheme.Typography.caption)
                        .anchorSecondaryText()
                }
            } header: {
                Text(String(localized: "Security"))
            }
            
            // Privacy & Data
            Section {
                if let settings = userSettings {
                    Toggle(String(localized: "Hide Live Activity status"), isOn: Binding(
                        get: { settings.liveActivityPrivateMode ?? false },
                        set: { newValue in
                            settings.liveActivityPrivateMode = newValue
                            modelContext.safeSave()
                        }
                    ))
                    .tint(AnchorTheme.Colors.sageLeaf)

                    Text(String(localized: "Shows “Session active” on the Lock Screen instead of live status details."))
                        .font(AnchorTheme.Typography.caption)
                        .anchorSecondaryText()
                }

                NavigationLink(destination: PrivacyPolicyView()) {
                    Label(String(localized: "Privacy Policy"), systemImage: "hand.raised.fill")
                }
                
                Button(action: exportData) {
                    Label(String(localized: "Export My Data"), systemImage: "square.and.arrow.up")
                }
            } header: {
                Text(String(localized: "Privacy & Data"))
            } footer: {
                Text(String(localized: "All your data is stored locally on this device. During live sessions, Anchor derives an on-device voice stress signal to gently tune responses. It is not diagnostic. Export or delete your data at any time."))
            }
            
            // Safety
            Section {
                Button(action: { showingSafetyResources = true }) {
                    Label(String(localized: "Emergency Resources"), systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(AnchorTheme.Colors.crisisRed)
                }
                
                NavigationLink(destination: SafetyGuidelinesView()) {
                    Label(String(localized: "Safety Guidelines"), systemImage: "shield.fill")
                }
            } header: {
                Text(String(localized: "Safety"))
            }
            
            // About
            Section {
                HStack {
                    Text(String(localized: "Version"))
                    Spacer()
                    Text(String(localized: "1.0.0"))
                        .anchorSecondaryText()
                }
                
                NavigationLink(destination: HelpFAQView()) {
                    Label(String(localized: "Help & FAQ"), systemImage: "questionmark.circle")
                }
                
                NavigationLink(destination: TermsOfServiceView()) {
                    Text(String(localized: "Terms of Service"))
                }
                
                NavigationLink(destination: AboutView()) {
                    Text(String(localized: "About Anchor"))
                }
                
                    Link(String(localized: "Contact Support"), destination: SupportContact.mailtoURL)
            } header: {
                Text(String(localized: "About"))
            }

            Section {
                Button(role: .destructive, action: { showingResetProfileConfirmation = true }) {
                    Label(String(localized: "Reset Learned Profile"), systemImage: "arrow.counterclockwise")
                }

                Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                    Label(String(localized: "Delete All My Data"), systemImage: "trash")
                }
            } header: {
                Text(String(localized: "Danger Zone"))
            } footer: {
                Text(String(localized: "These actions are permanent and cannot be undone."))
            }

            // Advanced / Developer
            Section {
                HStack {
                    SecureField(String(localized: "Gemini API Key"), text: $apiKeyText)
                        .font(AnchorTheme.Typography.subheadline)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onAppear {
                            apiKeyText = KeychainHelper.geminiAPIKey ?? ""
                        }
                        .onChange(of: apiKeyText) { _, newValue in
                            KeychainHelper.setGeminiAPIKey(newValue)
                        }

                    if !apiKeyText.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AnchorTheme.Colors.sageLeaf)
                    }
                }
            } header: {
                Text(String(localized: "Advanced"))
            } footer: {
                Text(String(localized: "Developer configuration. Your key is stored in the device Keychain and never leaves this device."))
            }
        }
        .navigationTitle(String(localized: "Settings"))
        .navigationBarTitleDisplayMode(.large)
        .scrollContentBackground(.hidden)
        .background(AnchorTheme.Colors.softParchment)
        .sheet(isPresented: $showingSubscriptionSheet) {
            SubscriptionView()
        }
        .sheet(isPresented: $showingSafetyResources) {
            EmergencyResourcesView()
        }
        .sheet(isPresented: $showingExportSheet) {
            if let url = exportFileURL {
                ShareSheet(activityItems: [url])
            }
        }
        .sheet(isPresented: $showingWeeklyShareSheet) {
            ShareSheet(activityItems: weeklyShareItems)
        }
        .confirmationDialog(String(localized: "Share Weekly Summary"), isPresented: $showingWeeklyShareOptions) {
            Button(String(localized: "Share Weekly Summary Card")) {
                shareWeeklySummaryCard()
            }
            Button(String(localized: "Share Weekly Summary Text")) {
                shareWeeklySummaryText()
            }
            Button(String(localized: "Cancel"), role: .cancel) { }
        }
        .alert(String(localized: "Delete All Data?"), isPresented: $showingDeleteConfirmation) {
            Button(String(localized: "Cancel"), role: .cancel) { }
            Button(String(localized: "Delete Everything"), role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text(String(localized: "This will permanently delete all your sessions and reset your settings. This action cannot be undone."))
        }
        .alert(String(localized: "Reset Learned Profile?"), isPresented: $showingResetProfileConfirmation) {
            Button(String(localized: "Cancel"), role: .cancel) { }
            Button(String(localized: "Reset"), role: .destructive) {
                resetProfile()
            }
        } message: {
            Text(String(localized: "This will clear all learned patterns and preferences. Anchor will start learning again from scratch."))
        }
        .persistenceAlert(isPresented: $showingSaveError)
    }
    
    private func exportData() {
        guard let url = DataExporter.exportAll(
            sessions: sessions,
            profile: profiles.first
        ) else { return }
        exportFileURL = url
        showingExportSheet = true
    }

    private func shareWeeklySummaryText() {
        let text = WeeklySummaryBuilder.summaryText(
            sessions: sessions,
            settings: userSettings
        )
        weeklyShareItems = [text]
        showingWeeklyShareSheet = true
    }

    @MainActor
    private func shareWeeklySummaryCard() {
        let payload = WeeklySummaryBuilder.summaryPayload(
            sessions: sessions,
            settings: userSettings
        )
        let card = WeeklySummaryCardView(payload: payload)
            .frame(width: 340)
            .padding(24)
            .background(AnchorTheme.Colors.softParchment)

        let renderer = ImageRenderer(content: card)
        renderer.scale = displayScale

        let text = WeeklySummaryBuilder.summaryText(
            sessions: sessions,
            settings: userSettings
        )

        if let image = renderer.uiImage {
            weeklyShareItems = [image, text]
        } else {
            weeklyShareItems = [text]
        }
        showingWeeklyShareSheet = !weeklyShareItems.isEmpty
    }
    
    private func deleteAllData() {
        for session in sessions {
            modelContext.delete(session)
        }
        for profile in profiles {
            modelContext.delete(profile)
        }
        for setting in settings {
            modelContext.delete(setting)
        }
        if !modelContext.safeSave() { showingSaveError = true }
        // Re-create default settings
        let newSettings = UserSettings()
        modelContext.insert(newSettings)
        if !modelContext.safeSave() { showingSaveError = true }
    }

    private func resetProfile() {
        for profile in profiles {
            modelContext.delete(profile)
        }
        if !modelContext.safeSave() { showingSaveError = true }
    }

    private func voiceSpeedLabel(_ speed: Double) -> String {
        let label = String(format: "%.1fx", speed)
        switch speed {
        case ..<0.8:
            return String.localizedStringWithFormat(String(localized: "%@ · Relaxed"), label)
        case 0.8..<1.15:
            return String.localizedStringWithFormat(String(localized: "%@ · Normal"), label)
        case 1.15..<1.55:
            return String.localizedStringWithFormat(String(localized: "%@ · Brisk"), label)
        default:
            return String.localizedStringWithFormat(String(localized: "%@ · Fast"), label)
        }
    }

    private func timeBinding(
        hour: Binding<Int?>,
        minute: Binding<Int?>,
        defaultHour: Int,
        defaultMinute: Int
    ) -> Binding<Date> {
        Binding<Date>(
            get: {
                let calendar = Calendar.current
                var components = calendar.dateComponents([.year, .month, .day], from: Date())
                components.hour = hour.wrappedValue ?? defaultHour
                components.minute = minute.wrappedValue ?? defaultMinute
                return calendar.date(from: components) ?? Date()
            },
            set: { newValue in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                hour.wrappedValue = comps.hour
                minute.wrappedValue = comps.minute
            }
        )
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .modelContainer(for: UserSettings.self, inMemory: true)
    }
}
