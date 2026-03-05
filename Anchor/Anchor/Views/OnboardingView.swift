//
//  OnboardingView.swift
//  Anchor
//
//  Calm onboarding flow (arrival, safety, preferences).
//

import SwiftUI
import SwiftData
import UIKit

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]

    @State private var selection = 0
    @State private var safetyAcknowledged = false
    @State private var selectedDateOfBirth = Calendar.current.date(byAdding: .year, value: -20, to: Date()) ?? Date()
    @State private var ageVerificationFailed = false
    @State private var nameInput = ""
    @State private var selectedConcerns: Set<String> = []
    @State private var selectedCommStyle = "gentle"
    @FocusState private var focusedField: OnboardingField?

    private var userSettings: UserSettings? {
        settings.first
    }

    private let totalSlides = 7

    private enum OnboardingField {
        case name
    }

    private let availableConcerns = [
        "Anxiety", "Stress", "Loneliness", "Grief",
        "Relationships", "Self-esteem", "Sleep", "Work",
        "Family", "Anger", "Motivation", "Life changes"
    ]

    private let commStyles: [(id: String, title: String, icon: String, description: String)] = [
        ("listener", "Just listen", "ear.fill", "I mostly want to feel heard and validated."),
        ("gentle", "Gentle guidance", "leaf.fill", "Offer soft suggestions when the moment feels right."),
        ("direct", "Direct advice", "arrow.right.circle.fill", "Give me clear, practical strategies.")
    ]

    /// Calculate age in years from the selected date of birth.
    private var ageInYears: Int {
        Calendar.current.dateComponents([.year], from: selectedDateOfBirth, to: Date()).year ?? 0
    }

    var body: some View {
        VStack(spacing: 24) {
            TabView(selection: $selection) {
                arrivalSlide
                    .tag(0)

                ageGateSlide
                    .tag(1)

                aboutYouSlide
                    .tag(2)

                concernsSlide
                    .tag(3)

                commStyleSlide
                    .tag(4)

                safetySlide
                    .tag(5)

                preferencesSlide
                    .tag(6)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 8) {
                ForEach(0..<totalSlides, id: \.self) { index in
                    Circle()
                        .fill(index == selection ? AnchorTheme.Colors.quietInk : AnchorTheme.Colors.warmSand)
                        .frame(width: 6, height: 6)
                        .opacity(index == selection ? 0.8 : 0.4)
                }
            }

            if selection != 0 {
                HStack {
                    Button(action: goBack) {
                        Text(String(localized: "Back"))
                            .font(AnchorTheme.Typography.caption)
                    }
                    .buttonStyle(.plain)
                    .disabled(selection == 0)
                    .opacity(selection == 0 ? 0.4 : 1.0)
                    .accessibilityIdentifier("onboarding.back")

                    Spacer()

                    if showsSkip {
                        Button(action: skipCurrentSlide) {
                            Text(String(localized: "Skip for now"))
                                .font(AnchorTheme.Typography.caption)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("onboarding.skip")
                    }
                }
                .padding(.horizontal, 24)

                Button(action: handleContinue) {
                Text(selection == totalSlides - 1 ? String(localized: "Enter Anchor") : String(localized: "Continue"))
                        .font(AnchorTheme.Typography.subheadline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AnchorPillButtonStyle(
                    background: AnchorTheme.Colors.sageLeaf,
                    foreground: AnchorTheme.Colors.softParchment
                ))
                .padding(.horizontal, 24)
                .disabled(!canContinue)
                .opacity(canContinue ? 1.0 : 0.6)
                .accessibilityIdentifier("onboarding.continue")
            }
        }
        .padding(.vertical, 32)
        .anchorScreenBackground()
        .onAppear {
            ensureSettings()
        }
        .onChange(of: selection) { _, _ in
            focusedField = nil
        }
        .onTapGesture {
            focusedField = nil
            hideKeyboard()
        }
    }

    private var arrivalSlide: some View {
        VStack(spacing: 18) {
            Spacer()
            OrbView(state: .idle, size: 200)
            Text(String(localized: "Welcome to Anchor"))
                .font(AnchorTheme.Typography.title)
                .anchorPrimaryText()
            Text(String(localized: "A quiet presence for moments that feel heavy."))
                .font(AnchorTheme.Typography.subheadline)
                .anchorSecondaryText()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Text(String(localized: "Take a breath. We’ll move at your pace."))
                .font(AnchorTheme.Typography.caption)
                .anchorSecondaryText()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)

            Button(action: handleContinue) {
                Text(String(localized: "Begin"))
                    .font(AnchorTheme.Typography.subheadline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AnchorPillButtonStyle(
                background: AnchorTheme.Colors.sageLeaf,
                foreground: AnchorTheme.Colors.softParchment
            ))
            .padding(.horizontal, 48)
            Spacer()
        }
    }

    private var ageGateSlide: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "person.badge.shield.checkmark.fill")
                .font(.system(size: 60))
                .foregroundColor(AnchorTheme.Colors.sageLeaf)
                .accessibilityHidden(true)

            Text(String(localized: "Verify your age"))
                .font(AnchorTheme.Typography.title)
                .anchorPrimaryText()

            Text(String(localized: "Anchor is designed for users 18 and older."))
                .font(AnchorTheme.Typography.subheadline)
                .anchorSecondaryText()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            DatePicker(
                String(localized: "Date of Birth"),
                selection: $selectedDateOfBirth,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .accessibilityLabel(String(localized: "Date of birth"))
            .onChange(of: selectedDateOfBirth) {
                ageVerificationFailed = false
            }

            if ageVerificationFailed {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .accessibilityHidden(true)
                    Text(String(localized: "You must be 18 or older to use Anchor."))
                }
                .font(AnchorTheme.Typography.caption)
                .foregroundColor(AnchorTheme.Colors.crisisRed)
                .transition(.opacity)
            }
            Spacer()
        }
    }

    private var aboutYouSlide: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "person.crop.circle")
                .font(.system(size: 60))
                .foregroundColor(AnchorTheme.Colors.etherBlue)
                .accessibilityHidden(true)

            Text(String(localized: "What should I call you?"))
                .font(AnchorTheme.Typography.title)
                .anchorPrimaryText()

            Text(String(localized: "A first name or nickname is perfect."))
                .font(AnchorTheme.Typography.subheadline)
                .anchorSecondaryText()

            TextField(String(localized: "Your name"), text: $nameInput)
                .font(AnchorTheme.Typography.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.vertical, 12)
                .background(AnchorTheme.Colors.warmStone)
                .cornerRadius(AnchorTheme.Layout.controlRadius)
                .padding(.horizontal, 48)
                .focused($focusedField, equals: .name)
                .submitLabel(.continue)
                .onSubmit {
                    handleContinue()
                }

            Spacer()
        }
    }

    private var concernsSlide: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "heart.text.clipboard.fill")
                .font(.system(size: 56))
                .foregroundColor(AnchorTheme.Colors.sageLeaf)
                .accessibilityHidden(true)

            Text(String(localized: "What brings you here?"))
                .font(AnchorTheme.Typography.title)
                .anchorPrimaryText()

            Text(String(localized: "Pick any that apply — you can always share more later."))
                .font(AnchorTheme.Typography.subheadline)
                .anchorSecondaryText()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                ForEach(availableConcerns, id: \.self) { concern in
                    let isSelected = selectedConcerns.contains(concern)
                    Button {
                        if isSelected {
                            selectedConcerns.remove(concern)
                        } else {
                            selectedConcerns.insert(concern)
                        }
                    } label: {
                        Text(concern)
                            .font(AnchorTheme.Typography.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(isSelected ? AnchorTheme.Colors.sageLeaf : AnchorTheme.Colors.warmStone)
                            .foregroundColor(isSelected ? AnchorTheme.Colors.softParchment : AnchorTheme.Colors.quietInk)
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(concern)
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                    .accessibilityHint(isSelected ? String(localized: "Double tap to deselect") : String(localized: "Double tap to select"))
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private var commStyleSlide: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 56))
                .foregroundColor(AnchorTheme.Colors.etherBlue)
                .accessibilityHidden(true)

            Text(String(localized: "How should I support you?"))
                .font(AnchorTheme.Typography.title)
                .anchorPrimaryText()

            VStack(spacing: 12) {
                ForEach(commStyles, id: \.id) { style in
                    let isSelected = selectedCommStyle == style.id
                    Button {
                        selectedCommStyle = style.id
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: style.icon)
                                .font(.system(size: 20))
                                .foregroundColor(isSelected ? AnchorTheme.Colors.softParchment : AnchorTheme.Colors.sageLeaf)
                                .frame(width: 28)
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(style.title)
                                    .font(AnchorTheme.Typography.subheadline)
                                Text(style.description)
                                    .font(AnchorTheme.Typography.smallCaption)
                                    .opacity(0.8)
                            }
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(isSelected ? AnchorTheme.Colors.softParchment : AnchorTheme.Colors.sageLeaf)
                                    .accessibilityHidden(true)
                            }
                        }
                        .padding(14)
                        .background(isSelected ? AnchorTheme.Colors.sageLeaf : AnchorTheme.Colors.warmStone)
                        .foregroundColor(isSelected ? AnchorTheme.Colors.softParchment : AnchorTheme.Colors.quietInk)
                        .cornerRadius(AnchorTheme.Layout.controlRadius)
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(style.title)
                    .accessibilityValue(isSelected ? String(localized: "Selected") : String(localized: "Not selected"))
                }
            }
            .padding(.horizontal, 24)

            if let settings = userSettings {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Conversation persona"))
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
                .anchorCard()
                .padding(.horizontal, 24)
            }

            Spacer()
        }
    }

    private var safetySlide: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(AnchorTheme.Colors.crisisRed)
                .accessibilityHidden(true)
            Text(String(localized: "Safety comes first"))
                .font(AnchorTheme.Typography.title)
                .anchorPrimaryText()
            Text(String(localized: "Anchor is support, not emergency care. We will always show crisis resources when needed."))
                .font(AnchorTheme.Typography.subheadline)
                .anchorSecondaryText()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: { safetyAcknowledged.toggle() }) {
                HStack(spacing: 8) {
                    Image(systemName: safetyAcknowledged ? "checkmark.circle.fill" : "circle")
                        .accessibilityHidden(true)
                    Text(String(localized: "I understand"))
                        .font(AnchorTheme.Typography.subheadline)
                }
                .foregroundColor(AnchorTheme.Colors.quietInk)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AnchorTheme.Colors.warmStone)
                .cornerRadius(AnchorTheme.Layout.controlRadius)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "I understand"))
            .accessibilityValue(safetyAcknowledged ? String(localized: "Acknowledged") : String(localized: "Not acknowledged"))
            .accessibilityHint(String(localized: "Acknowledge that Anchor is not a replacement for emergency care"))
            Spacer()
        }
    }

    private var preferencesSlide: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 60))
                    .foregroundColor(AnchorTheme.Colors.sageLeaf)
                    .accessibilityHidden(true)
                Text(String(localized: "Set your pace"))
                    .font(AnchorTheme.Typography.title)
                    .anchorPrimaryText()
                Text(String(localized: "These can be changed anytime in Settings."))
                    .font(AnchorTheme.Typography.subheadline)
                    .anchorSecondaryText()

                if let settings = userSettings {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(String(localized: "Anchor can send gentle reminders so check-ins stay easy to keep."))
                            .font(AnchorTheme.Typography.caption)
                            .anchorSecondaryText()

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

                        Text(String(localized: "A short daily ritual with a calming quote and breath."))
                            .font(AnchorTheme.Typography.caption)
                            .anchorSecondaryText()

                        Toggle(String(localized: "Require Face ID"), isOn: Binding(
                            get: { settings.appLockEnabled ?? false },
                            set: { newValue in
                                settings.appLockEnabled = newValue
                                modelContext.safeSave()
                            }
                        ))
                        .tint(AnchorTheme.Colors.sageLeaf)

                        Text(String(localized: "Lock Anchor when you leave the app. Face ID or device passcode will be required to reopen."))
                            .font(AnchorTheme.Typography.caption)
                            .anchorSecondaryText()

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

                            HStack {
                                Text(String(localized: "Slower"))
                                    .font(AnchorTheme.Typography.caption)
                                    .anchorSecondaryText()
                                Spacer()
                                Text(String(format: "%.1fx", settings.voiceSpeed))
                                    .font(AnchorTheme.Typography.caption)
                                    .anchorSecondaryText()
                                Spacer()
                                Text(String(localized: "Faster"))
                                    .font(AnchorTheme.Typography.caption)
                                    .anchorSecondaryText()
                            }
                        }
                    }
                    .anchorCard()
                    .padding(.horizontal, 24)
                }
            }
            .padding(.vertical, 24)
        }
    }

    private var canContinue: Bool {
        switch selection {
        case 1: return !ageVerificationFailed  // age gate
        case 5: return safetyAcknowledged      // safety acknowledgement
        default: return true
        }
    }

    private var showsSkip: Bool {
        selection == 2 || selection == 3
    }

    private func handleContinue() {
        guard canContinue else { return }

        focusedField = nil
        hideKeyboard()

        // Age verification on age gate slide
        if selection == 1 {
            if ageInYears < 18 {
                ageVerificationFailed = true
                return
            } else {
                ageVerificationFailed = false
                if let settings = userSettings {
                    settings.dateOfBirth = selectedDateOfBirth
                    modelContext.safeSave()
                }
            }
        }

        // Save name after aboutYou slide
        if selection == 2, let settings = userSettings {
            let trimmed = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { settings.userName = trimmed }
        }

        // Save concerns after concerns slide
        if selection == 3, let settings = userSettings {
            settings.primaryConcerns = Array(selectedConcerns)
        }

        // Save communication style after commStyle slide
        if selection == 4, let settings = userSettings {
            settings.communicationStyle = selectedCommStyle
        }

        if selection < totalSlides - 1 {
            withAnimation(AnchorTheme.Motion.gentleSpring) {
                selection += 1
            }
        } else {
            completeOnboarding()
        }
    }

    private func goBack() {
        guard selection > 0 else { return }
        withAnimation(AnchorTheme.Motion.gentleSpring) {
            selection -= 1
        }
    }

    private func skipCurrentSlide() {
        switch selection {
        case 2:
            nameInput = ""
            if let settings = userSettings {
                settings.userName = ""
            }
        case 3:
            selectedConcerns.removeAll()
            if let settings = userSettings {
                settings.primaryConcerns = []
            }
        default:
            break
        }
        handleContinue()
    }

    private func ensureSettings() {
        guard settings.isEmpty else { return }
        let newSettings = UserSettings()
        modelContext.insert(newSettings)
        modelContext.safeSave()
    }

    private func completeOnboarding() {
        guard let settings = userSettings else { return }
        // Persist any last-minute profile data
        let trimmedName = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty { settings.userName = trimmedName }
        if !selectedConcerns.isEmpty { settings.primaryConcerns = Array(selectedConcerns) }
        settings.communicationStyle = selectedCommStyle
        withAnimation(.easeInOut(duration: 0.35)) {
            settings.hasCompletedOnboarding = true
        }
        modelContext.safeSave()
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: UserSettings.self, inMemory: true)
}
