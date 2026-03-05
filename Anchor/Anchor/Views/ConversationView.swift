//
//  ConversationView.swift
//  Anchor
//
//  Created for Anchor - AI-Powered Emotional Support
//

import Speech
import SwiftData
import SwiftUI
import UIKit

struct ConversationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var voiceController: VoiceStateController
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @Environment(DeepLinkRouter.self) private var deepLinkRouter
    @Environment(\.scenePhase) private var scenePhase
    @Query private var settings: [UserSettings]
    @Query(sort: \Session.timestamp, order: .reverse) private var previousSessions: [Session]
    @Query private var profiles: [UserProfile]

    @StateObject private var liveClient = GeminiLiveClient()
    @StateObject private var localTranscriber = LocalTranscriber()
    @State private var audioIO = LiveAudioIO()
    @State private var isRecording = false
    @State private var conversationStartTime = Date()
    @State private var elapsedTime: TimeInterval = 0
    @State private var activeUsageTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var freeSessionLimitSeconds: TimeInterval?
    @State private var didRecordUsage = false
    @State private var showingLimitAlert = false
    @State private var showingConfigAlert = false
    @State private var configAlertMessage = ""
    @State private var allowLiveErrors = false
    @State private var showingMicAlert = false
    @State private var showingDisconnectAlert = false
    @State private var showingAudioInterruptionAlert = false
    @State private var crisisDetected = false
    @State private var showingCrisisResources = false
    @State private var showingCrisisInterruption = false
    @State private var wasRecordingBeforeCrisis = false
    @State private var moodBefore: Int? = nil
    @State private var moodAfter: Int? = nil
    @State private var showingMoodBefore = true
    @State private var showingMoodAfter = false
    @State private var showingMoodTriggers = false
    @State private var reflectionPrompt = ""
    @State private var showingSummary = false
    @State private var showingCelebration = false
    @State private var celebrationContent: CelebrationContent?
    @State private var summaryPayload: SessionSummaryPayload?
    @State private var summaryStatus: SummaryStatus = .idle
    @State private var breathingSuggestion: BreathingSuggestion?
    @State private var activeBreathingPattern: BreathingPatternKind = .box
    @State private var showingBreathingExercise = false
    @State private var isSessionPaused = false
    @State private var wasRecordingBeforeBreathing = false
    @State private var wasRecordingBeforeInterruption = false
    @State private var breathingInitiatedByModel = false
    @State private var lastActionTimestamp: Date?
    @State private var didSaveSession = false
    @State private var micPermissionDenied = false
    @State private var textInput = ""
    @State private var showingFlagSheet = false
    @State private var flaggedMessageText = ""
    @State private var flaggedUserContext = ""
    @State private var flagReason = ""
    @State private var showingFlagConfirmation = false
    @State private var warmupActive = false
    @State private var warmupWorkItem: DispatchWorkItem?
    @State private var moodTriggers: Set<String> = []
    @State private var sessionFocus: SessionFocus = .justTalk
    @State private var isAtBottom = true
    @State private var liveActivitySessionID = UUID()
    @State private var wasBackgrounded = false
    
    // Throttle state for Live Activity updates
    @State private var lastLiveActivityUpdate: Date = .distantPast
    @State private var pendingLiveActivityUpdate: Bool = false

    private let liveActivityManager = SessionLiveActivityManager.shared

    private let conversationStarters = [
        String(localized: "I just need someone to listen"),
        String(localized: "I'm feeling anxious today"),
        String(localized: "Tell me about my day"),
        String(localized: "Help me process something"),
        String(localized: "I can't sleep"),
    ]

    // Crisis keyword patterns – canonical list lives in CrisisKeywordScanner.

    private var userSettings: UserSettings? {
        settings.first
    }

    private var liveActivityIsPrivate: Bool {
        userSettings?.liveActivityPrivateMode ?? false
    }

    private var liveActivityFocusTitle: String? {
        sessionFocus == .justTalk ? nil : sessionFocus.title
    }

    private var orbState: OrbState {
        voiceController.state.orbState
    }

    private var displayOrbState: OrbState {
        warmupActive ? .connecting : orbState
    }

    private var shouldShowTextFallback: Bool {
        !networkMonitor.isConnected || micPermissionDenied
    }

    private var contentOpacity: Double {
        isRecording && !isSessionPaused ? 0.6 : 1.0
    }

    private var statusText: String {
        if isSessionPaused { return String(localized: "Paused") }
        guard isRecording else { return String(localized: "Ready") }
        if warmupActive { return String(localized: "I'm here…") }
        switch voiceController.state {
        case .idle: return String(localized: "Listening")
        case .connecting: return String(localized: "Connecting…")
        case .listening: return String(localized: "Listening")
        case .thinking: return String(localized: "Thinking")
        case .speaking: return String(localized: "Speaking")
        case .crisis: return String(localized: "Support")
        }
    }

    private var statusColor: Color {
        if isSessionPaused { return AnchorTheme.Colors.warmSand }
        switch voiceController.state {
        case .idle: return AnchorTheme.Colors.sageLeaf
        case .connecting: return AnchorTheme.Colors.warmSand
        case .listening: return AnchorTheme.Colors.etherBlue
        case .thinking: return AnchorTheme.Colors.thinkingViolet
        case .speaking: return AnchorTheme.Colors.pulsePink
        case .crisis: return AnchorTheme.Colors.crisisRed
        }
    }

    private var displayStatusColor: Color {
        warmupActive ? AnchorTheme.Colors.warmSand : statusColor
    }

    private var micStatusText: String {
        if isSessionPaused { return String(localized: "Session paused") }
        return isRecording ? String(localized: "Mic live") : String(localized: "Mic idle")
    }

    private var remainingSessionSeconds: TimeInterval? {
        guard let limit = freeSessionLimitSeconds else { return nil }
        return max(0, limit - activeUsageTime)
    }

    private var recordButtonTitle: String {
        if isSessionPaused { return String(localized: "Resume") }
        return isRecording ? String(localized: "Pause") : String(localized: "Start")
    }

    private var recordButtonIcon: String {
        if isSessionPaused { return "play" }
        return isRecording ? "pause" : "mic"
    }

    private var actionCooldown: TimeInterval { 30 }

    @ViewBuilder
    private var startersSection: some View {
        VStack(spacing: 12) {
            Text(
                isRecording
                    ? String(localized: "Listening…") : String(localized: "Or start with a prompt…")
            )
            .font(AnchorTheme.Typography.caption)
            .anchorSecondaryText()
            .animation(.easeInOut(duration: 0.3), value: isRecording)

            FlowLayout(spacing: 8) {
                ForEach(conversationStarters, id: \.self) { starter in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        Task { await liveClient.sendUserText(starter) }
                    } label: {
                        Text(starter)
                            .font(AnchorTheme.Typography.caption)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                Capsule()
                                    .fill(AnchorTheme.Colors.warmStone)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(AnchorTheme.Colors.warmSand, lineWidth: 1)
                            )
                            .foregroundColor(AnchorTheme.Colors.quietInk)
                    }
                    .buttonStyle(.plain)
                    .fixedSize()
                    .accessibilityHint(String(localized: "Send this as your opening message"))
                }
            }
            .opacity(isRecording ? 0.5 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: isRecording)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .transition(.opacity.combined(with: .scale(scale: 0.95)).combined(with: .offset(y: 10)))
    }

    @ViewBuilder
    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollViewReader { proxy in
                ZStack(alignment: .bottomTrailing) {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(liveClient.messages) { message in
                                MessageBubble(
                                    text: message.text,
                                    isUser: message.role == .user,
                                    isStreaming: message.isStreaming
                                )
                                .id(message.id)
                                .contextMenu {
                                    if message.role == .assistant {
                                        Button {
                                            // Find the user message just before this AI response
                                            if let idx = liveClient.messages.firstIndex(where: {
                                                $0.id == message.id
                                            }),
                                                idx > 0,
                                                liveClient.messages[idx - 1].role == .user
                                            {
                                                flaggedUserContext =
                                                    liveClient.messages[idx - 1].text
                                            } else {
                                                flaggedUserContext = ""
                                            }
                                            flaggedMessageText = message.text
                                            flagReason = ""
                                            showingFlagSheet = true
                                        } label: {
                                            Label(
                                                String(localized: "Report Response"),
                                                systemImage: "flag")
                                        }
                                    }
                                }
                                .onAppear {
                                    if message.id == liveClient.messages.last?.id {
                                        isAtBottom = true
                                    }
                                }
                                .onDisappear {
                                    if message.id == liveClient.messages.last?.id {
                                        isAtBottom = false
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if !isAtBottom {
                        Button {
                            if let last = liveClient.messages.last {
                                withAnimation(AnchorTheme.Motion.gentleSpring) {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                                isAtBottom = true
                            }
                        } label: {
                            Label(String(localized: "Jump to latest"), systemImage: "arrow.down")
                                .font(AnchorTheme.Typography.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.thinMaterial)
                                .clipShape(Capsule())
                        }
                        .padding(.trailing, 8)
                        .padding(.bottom, 8)
                        .accessibilityLabel(String(localized: "Jump to latest message"))
                    }
                }
                .onChange(of: liveClient.messages.count) { _, _ in
                    if isAtBottom, let last = liveClient.messages.last {
                        withAnimation(AnchorTheme.Motion.gentleSpring) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 100, maxHeight: 280)
        .anchorCard()
        .padding(.horizontal, 24)
        .opacity(contentOpacity)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    @ViewBuilder
    private var statusSection: some View {
        VStack(spacing: 16) {
            OrbView(state: displayOrbState, size: 210)

            Text(statusText)
                .font(AnchorTheme.Typography.headline)
                .anchorPrimaryText()
                .contentTransition(.interpolate)
                .animation(.easeInOut(duration: 0.5), value: statusText)

            if isSessionPaused {
                Text(String(localized: "Session paused"))
                    .font(AnchorTheme.Typography.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(AnchorTheme.Colors.warmStone)
                    )
                    .foregroundColor(AnchorTheme.Colors.quietInk)
            }

            HStack(spacing: 8) {
                Circle()
                    .fill(displayStatusColor)
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.5), value: displayStatusColor)
                Text(micStatusText)
                    .font(AnchorTheme.Typography.caption)
                    .anchorSecondaryText()
            }

            if isRecording && !isSessionPaused {
                Text(formattedElapsedTime)
                    .font(AnchorTheme.Typography.caption)
                    .anchorSecondaryText()
                    .monospacedDigit()

                if let remaining = remainingSessionSeconds {
                    Text(
                        String.localizedStringWithFormat(
                            String(localized: "Free time remaining: %@"),
                            formattedMinutes(remaining)
                        )
                    )
                    .font(AnchorTheme.Typography.caption)
                    .anchorSecondaryText()
                    .monospacedDigit()
                }
            }
        }
    }

    @ViewBuilder
    private var bottomControls: some View {
        HStack(spacing: 18) {
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                endConversation()
            }) {
                Label(String(localized: "End"), systemImage: "xmark")
                    .font(AnchorTheme.Typography.caption)
            }
            .buttonStyle(
                AnchorPillButtonStyle(
                    background: AnchorTheme.Colors.warmStone,
                    foreground: AnchorTheme.Colors.quietInk)
            )
            .accessibilityLabel(String(localized: "End conversation"))
            .accessibilityHint(String(localized: "End the current session and save"))
            .accessibilityIdentifier("conversation.end")

            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                toggleRecording()
            }) {
                Label(recordButtonTitle, systemImage: recordButtonIcon)
                    .font(AnchorTheme.Typography.subheadline)
            }
            .buttonStyle(
                AnchorPillButtonStyle(
                    background: AnchorTheme.Colors.warmStone,
                    foreground: AnchorTheme.Colors.quietInk)
            )
            .disabled(!isRecording && !isSessionPaused && shouldShowTextFallback)
            .opacity(!isRecording && !isSessionPaused && shouldShowTextFallback ? 0.5 : 1.0)
            .accessibilityLabel(
                isSessionPaused
                    ? String(localized: "Resume session")
                    : (isRecording
                        ? String(localized: "Pause recording")
                        : String(localized: "Start recording"))
            )
            .accessibilityHint(
                isSessionPaused
                    ? String(localized: "Resume the microphone")
                    : (isRecording
                        ? String(localized: "Pause the microphone")
                        : String(localized: "Resume the microphone"))
            )
            .accessibilityIdentifier("conversation.toggleRecording")

            NavigationLink(destination: EmergencyResourcesView()) {
                Label(String(localized: "Help"), systemImage: "exclamationmark.triangle")
                    .font(AnchorTheme.Typography.caption)
            }
            .buttonStyle(
                AnchorPillButtonStyle(
                    background: AnchorTheme.Colors.crisisRed.opacity(0.2),
                    foreground: AnchorTheme.Colors.crisisRed)
            )
            .accessibilityLabel(String(localized: "Emergency help"))
            .accessibilityHint(String(localized: "View crisis hotlines and resources"))
            .accessibilityIdentifier("conversation.help")
        }
        .opacity(contentOpacity)
    }

    @ViewBuilder
    private var connectionBanners: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .accessibilityHidden(true)
                Text(String(localized: "No connection — text-only mode"))
                    .font(AnchorTheme.Typography.smallCaption)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AnchorTheme.Colors.warmSand.opacity(0.9))
            .cornerRadius(20)
            .padding(.top, 4)
        }

        if micPermissionDenied {
            HStack(spacing: 8) {
                Image(systemName: "mic.slash")
                    .accessibilityHidden(true)
                Text(String(localized: "Microphone access denied — text-only mode"))
                    .font(AnchorTheme.Typography.smallCaption)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AnchorTheme.Colors.warmSand.opacity(0.9))
            .cornerRadius(20)
        }
    }

    @ViewBuilder
    private var textFallbackSection: some View {
        if shouldShowTextFallback {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Text-only check-in"))
                    .font(AnchorTheme.Typography.caption)
                    .anchorSecondaryText()

                HStack(spacing: 8) {
                    TextField(
                        String(localized: "Type what's on your mind…"), text: $textInput,
                        axis: .vertical
                    )
                    .font(AnchorTheme.Typography.bodyText)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(AnchorTheme.Colors.warmStone)
                    .cornerRadius(14)
                    .accessibilityLabel(String(localized: "Message input"))
                    .accessibilityHint(String(localized: "Type a message to send to Anchor"))
                    .accessibilityIdentifier("conversation.textInput")

                    Button(action: sendTextMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(AnchorTheme.Colors.sageLeaf)
                            .accessibilityHidden(true)
                    }
                    .disabled(textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel(String(localized: "Send message"))
                    .accessibilityHint(String(localized: "Send your typed message"))
                    .accessibilityIdentifier("conversation.sendText")
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private var conversationContent: some View {
        NavigationStack {
            VStack(spacing: 20) {
                connectionBanners

                statusSection

                Group {
                    if liveClient.messages.isEmpty {
                        startersSection
                    } else {
                        transcriptSection
                    }
                }
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.85),
                    value: liveClient.messages.isEmpty)

                textFallbackSection
                Spacer(minLength: 8)
            }
            .padding(.horizontal, 8)
            .navigationTitle(String(localized: "Conversation"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "Done")) {
                        endConversation()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomControls
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .background(
                        AnchorTheme.Colors.softParchment
                            .opacity(0.96)
                            .ignoresSafeArea(edges: .bottom)
                    )
            }
        }
    }

    var body: some View {
        conversationObserved
    }

    private var conversationBase: some View {
        conversationContent
            .anchorScreenBackground()
            .onDisappear {
                stopTimer()
                allowLiveErrors = false
                liveClient.disconnect()
                audioIO.stop()
            }
            .onChange(of: liveClient.isGenerating) { _, isGenerating in
                if isGenerating {
                    voiceController.update(.speaking)
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                } else if isRecording {
                    voiceController.update(.listening)
                }
            }
            .onChange(of: liveClient.errorMessage) { _, newValue in
                if let message = newValue, allowLiveErrors {
                    configAlertMessage = message
                    showingConfigAlert = true
                }
            }
    }

    private var conversationAlerts: some View {
        conversationBase
            .alert(String(localized: "Daily Limit Reached"), isPresented: $showingLimitAlert) {
                Button(String(localized: "OK")) {
                    dismiss()
                }
            } message: {
                Text(
                    String(
                        localized:
                            "You’ve used your 10 minutes for today. Come back tomorrow or upgrade for unlimited conversations."
                    ))
            }
            .alert(String(localized: "Live API Configuration"), isPresented: $showingConfigAlert) {
                Button(String(localized: "OK"), role: .cancel) {}
            } message: {
                Text(configAlertMessage)
            }
            .alert(String(localized: "Microphone Access Needed"), isPresented: $showingMicAlert) {
                Button(String(localized: "OK"), role: .cancel) {}
            } message: {
                Text(
                    String(
                        localized:
                            "Enable microphone access in Settings to use live voice conversations.")
                )
            }
            .alert(String(localized: "Connection Lost"), isPresented: $showingDisconnectAlert) {
                Button(String(localized: "Reconnect")) {
                    voiceController.update(.connecting)
                    Task {
                        await liveClient.reconnectSession()
                        if liveClient.liveConnectionState == .ready {
                            voiceController.update(.listening)
                        }
                    }
                }
                Button(String(localized: "End Session"), role: .destructive) {
                    endConversation()
                }
            } message: {
                Text(
                    String(
                        localized: "The connection was interrupted. Would you like to reconnect?"))
            }
            .alert(
                String(localized: "Audio Interrupted"), isPresented: $showingAudioInterruptionAlert
            ) {
                Button(String(localized: "Resume")) {
                    resumeAfterInterruption()
                }
                Button(String(localized: "End Session"), role: .destructive) {
                    endConversation()
                }
            } message: {
                Text(
                    String(
                        localized: "Your audio session was interrupted. Resume when you're ready."))
            }
    }

    private var conversationSheets: some View {
        conversationAlerts
            .sheet(isPresented: $showingCrisisResources) {
                EmergencyResourcesView()
            }
            .sheet(isPresented: $showingCrisisInterruption) {
                CrisisInterruptionView(
                    onViewResources: { showingCrisisResources = true },
                    onContinue: resumeAfterCrisis,
                    onEnd: endConversationAfterCrisis
                )
                .interactiveDismissDisabled()
                .presentationDetents([.large])
                .presentationCornerRadius(28)
            }
            .sheet(isPresented: $showingMoodBefore) {
                MoodCheckInView(
                    title: String(localized: "How are you feeling?"),
                    subtitle: String(localized: "Before we begin, check in with yourself."),
                    focusSelection: $sessionFocus
                ) { selected in
                    moodBefore = selected
                    showingMoodBefore = false
                    // Start the conversation after mood selection
                    if !isRecording {
                        isRecording = true
                        startConversation(resetTimer: true)
                    }
                }
                .presentationDetents([.medium])
                .interactiveDismissDisabled()
            }
            .sheet(isPresented: $showingMoodAfter) {
                MoodCheckInView(
                    title: String(localized: "How are you feeling now?"),
                    subtitle: String(localized: "Take a moment to notice any shift."),
                    autoAdvanceOnSelect: true
                ) { selected in
                    moodAfter = selected
                    showingMoodAfter = false
                    reflectionPrompt = buildReflectionPrompt()
                    showingMoodTriggers = true
                }
                .presentationDetents([.medium])
                .interactiveDismissDisabled()
            }
            .sheet(isPresented: $showingMoodTriggers) {
                MoodTriggersView(selected: $moodTriggers) {
                    showingMoodTriggers = false
                    handleSessionCompletion()
                }
                .presentationDetents([.medium])
            }
            .sheet(item: $breathingSuggestion) { suggestion in
                BreathingSuggestionCard(
                    suggestion: suggestion,
                    onAccept: { startBreathingFlow(from: suggestion) },
                    onDecline: {
                        breathingSuggestion = nil
                        Task {
                            await liveClient.sendContextSignal(
                                "[Signal] Breathing suggestion declined.")
                        }
                    }
                )
                .presentationDetents([.medium])
                .presentationCornerRadius(28)
            }
            .sheet(isPresented: $showingBreathingExercise) {
                BreathingExerciseView(
                    initialPattern: activeBreathingPattern,
                    allowsPatternSelection: false,
                    onCompleted: { resumeAfterBreathing(didComplete: true) },
                    onExit: { resumeAfterBreathing(didComplete: false) }
                )
                .presentationDetents([.large])
                .presentationCornerRadius(28)
            }
            .fullScreenCover(isPresented: $showingCelebration) {
                if let content = celebrationContent {
                    SessionCelebrationView(content: content) {
                        showingCelebration = false
                        showingSummary = true
                    }
                    .interactiveDismissDisabled()
                }
            }
            .sheet(isPresented: $showingSummary) {
                if let payload = summaryPayload {
                    SessionSummarySheetView(
                        payload: payload,
                        reflectionPrompt: reflectionPrompt,
                        summaryStatus: summaryStatus
                    ) {
                        showingSummary = false
                        finishEndConversation(completed: true)
                    }
                }
            }
            .sheet(isPresented: $showingFlagSheet) {
                NavigationStack {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(String(localized: "What was wrong with this response?"))
                            .font(AnchorTheme.Typography.headline)
                            .anchorPrimaryText()

                        let truncatedMessage =
                            String(flaggedMessageText.prefix(200))
                            + (flaggedMessageText.count > 200 ? "…" : "")
                        Text(String(format: String(localized: "“%@”"), truncatedMessage))
                            .font(AnchorTheme.Typography.caption)
                            .anchorSecondaryText()
                            .italic()
                            .padding()
                            .background(AnchorTheme.Colors.warmStone)
                            .cornerRadius(12)

                        VStack(alignment: .leading, spacing: 8) {
                            let reasons = [
                                String(localized: "Harmful or unsafe advice"),
                                String(localized: "Inaccurate or misleading"),
                                String(localized: "Inappropriate tone"),
                                String(localized: "Ignored my boundaries"),
                                String(localized: "Other"),
                            ]
                            ForEach(reasons, id: \.self) { reason in
                                Button {
                                    flagReason = reason
                                } label: {
                                    HStack {
                                        Image(
                                            systemName: flagReason == reason
                                                ? "checkmark.circle.fill" : "circle"
                                        )
                                        .foregroundColor(
                                            flagReason == reason
                                                ? AnchorTheme.Colors.sageLeaf
                                                : AnchorTheme.Colors.quietInkSecondary
                                        )
                                        .accessibilityHidden(true)
                                        Text(reason)
                                            .font(AnchorTheme.Typography.bodyText)
                                            .anchorPrimaryText()
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(flagReason == reason ? [.isSelected] : [])
                            }
                        }

                        Spacer()

                        Button {
                            saveFlaggedResponse()
                            showingFlagSheet = false
                            showingFlagConfirmation = true
                        } label: {
                            Text(String(localized: "Submit Report"))
                                .font(AnchorTheme.Typography.subheadline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(
                            AnchorPillButtonStyle(
                                background: AnchorTheme.Colors.sageLeaf,
                                foreground: AnchorTheme.Colors.softParchment)
                        )
                        .disabled(flagReason.isEmpty)
                        .opacity(flagReason.isEmpty ? 0.5 : 1.0)
                    }
                    .padding(24)
                    .navigationTitle(String(localized: "Report Response"))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(String(localized: "Cancel")) { showingFlagSheet = false }
                        }
                    }
                }
                .anchorScreenBackground()
                .presentationDetents([.medium, .large])
            }
    }

    private var conversationObserved: some View {
        conversationSheets
            .alert(String(localized: "Report Submitted"), isPresented: $showingFlagConfirmation) {
                Button(String(localized: "OK"), role: .cancel) {}
            } message: {
                Text(
                    String(
                        localized:
                            "Thank you for helping improve Anchor. Your report has been saved locally."
                    ))
            }
            .task {
                liveClient.onAudioChunk = { [weak audioIO] data, mimeType in
                    audioIO?.playAudioChunk(data, mimeType: mimeType)
                }

                liveClient.onTurnComplete = { [weak audioIO] in
                    audioIO?.flushPlaybackBuffer()
                }

                liveClient.onAction = { action in
                    handleLiveAction(action)
                }

                audioIO.onAudioChunk = { [weak liveClient] data, mimeType in
                    Task {
                        await liveClient?.sendRealtimeAudio(data, mimeType: mimeType)
                    }
                }

                audioIO.onEndOfTurn = { [weak liveClient, weak audioIO] in
                    Task {
                        if let score = audioIO?.currentStressScore() {
                            let clamped = max(1, min(100, Int(score.rounded())))
                            await liveClient?.sendContextSignal(
                                "[Signal] Voice stress score: \(clamped)/100.")
                        }
                        await liveClient?.sendAudioStreamEnd()
                    }
                    Task { @MainActor in
                        voiceController.update(.thinking)
                    }
                }

                audioIO.onStressScore = { [weak liveClient] score in
                    let clamped = max(1, min(100, Int(score.rounded())))
                    Task {
                        await liveClient?.sendContextSignal(
                            "[Signal] Voice stress score: \(clamped)/100.")
                    }
                }

                audioIO.onVoiceStateChange = { isSpeaking in
                    if isSpeaking {
                        Task { @MainActor in
                            voiceController.update(.listening)
                        }
                    }
                }

                audioIO.onInterruption = { event in
                    Task { @MainActor in
                        handleAudioInterruption(event)
                    }
                }

                // Auto-start the conversation after mood check-in.
                // The mood-before sheet is shown immediately; conversation
                // begins once the user selects a mood.
                updateLocalFallback()
            }
            .onChange(of: liveClient.liveConnectionState) { oldState, newState in
                if oldState == .ready && newState == .failed && isRecording && !wasBackgrounded {
                    showingDisconnectAlert = true
                }
            }
            // Crisis scan: watch message completion, not text changes (reduces onChange spam)
            .onChange(of: liveClient.messages.last?.id) { oldId, newId in
                guard oldId != newId,
                    let lastMessage = liveClient.messages.last,
                    lastMessage.role == .user
                else { return }
                // Scan the full text when message is complete
                scanForCrisisKeywords(lastMessage.text)
            }
            // Additional scan when streaming finishes (catches final text updates)
            .onChange(of: liveClient.messages.last?.isStreaming) { wasStreaming, isStreaming in
                guard let lastMessage = liveClient.messages.last,
                    lastMessage.role == .user,
                    wasStreaming == true,
                    isStreaming == false
                else { return }
                scanForCrisisKeywords(lastMessage.text)
            }
            .onChange(of: voiceController.state) { _, _ in
                updateLiveActivityStatus()
            }
            .onChange(of: isSessionPaused) { _, _ in
                updateLiveActivityStatus()
            }
            .onChange(of: userSettings?.liveActivityPrivateMode ?? false) { _, _ in
                updateLiveActivityStatus()
            }
            .onChange(of: networkMonitor.isConnected) { _, _ in
                updateLocalFallback()
            }
            .onChange(of: micPermissionDenied) { _, _ in
                updateLocalFallback()
            }
            .onChange(of: scenePhase) { _, newPhase in
                handleScenePhaseChange(newPhase)
            }
            .task(id: deepLinkRouter.pendingAction) {
                consumeDeepLinkAction()
            }
            .onAppear {
                audioIO.onLocalAudioBuffer = { buffer in
                    localTranscriber.append(buffer)
                }
                localTranscriber.onTranscription = { text, isFinal in
                    Task { @MainActor in
                        liveClient.overrideUserTranscript(text, isFinal: isFinal)
                    }
                }
            }
    }

    private func toggleRecording() {
        if isSessionPaused {
            resumeAfterBreathing(didComplete: false)
            return
        }
        if !isRecording && shouldShowTextFallback {
            return
        }
        isRecording.toggle()

        if isRecording {
            startConversation(resetTimer: true)
        } else {
            voiceController.reset()
            stopTimer()
            audioIO.stop()
            localTranscriber.stop()
            endLiveActivity()
            Task {
                await liveClient.sendAudioStreamEnd()
            }
        }
    }

    private func endConversation() {
        allowLiveErrors = false
        if !didRecordUsage {
            recordUsage()
        }
        // If the conversation lasted long enough, ask for mood-after
        if elapsedTime > 10 && !liveClient.messages.isEmpty {
            isRecording = false
            voiceController.reset()
            stopTimer()
            audioIO.stop()
            endLiveActivity()
            // Don't send audio stream end here — finishEndConversation handles full teardown.
            showingMoodAfter = true
        } else {
            moodAfter = nil
            finishEndConversation(completed: true)
        }
    }

    private func finishEndConversation(completed: Bool) {
        if !didSaveSession {
            _ = saveSession(completed: completed)
        }
        isSessionPaused = false
        wasRecordingBeforeBreathing = false
        breathingSuggestion = nil
        breathingInitiatedByModel = false
        showingBreathingExercise = false
        allowLiveErrors = false
        voiceController.reset()
        stopTimer()
        endLiveActivity()
        Task {
            await liveClient.sendAudioStreamEnd()
            liveClient.disconnect()
        }
        audioIO.stop()
        localTranscriber.stop()
        dismiss()
    }

    private func startConversation(resetTimer: Bool) {
        allowLiveErrors = true
        guard !shouldShowTextFallback else {
            isRecording = false
            voiceController.reset()
            stopTimer()
            audioIO.stop()
            localTranscriber.stop()
            allowLiveErrors = false
            return
        }
        isSessionPaused = false
        wasRecordingBeforeBreathing = false
        guard let settings = userSettings else { return }
        settings.refreshDailyUsageIfNeeded()

        if !settings.hasUnlimitedAccess {
            let remaining = settings.remainingFreeSeconds()
            guard remaining > 0 else {
                showingLimitAlert = true
                isRecording = false
                return
            }
            freeSessionLimitSeconds = remaining
        } else {
            freeSessionLimitSeconds = nil
        }

        modelContext.safeSave()
        if resetTimer {
            didSaveSession = false
            summaryPayload = nil
            summaryStatus = .idle
            celebrationContent = nil
            showingSummary = false
            showingCelebration = false
            moodTriggers.removeAll()
        }
        didRecordUsage = false
        voiceController.update(.connecting)
        if resetTimer {
            beginWarmup()
        }
        startTimer(reset: resetTimer)
        if resetTimer {
            liveActivitySessionID = UUID()
            startLiveActivity()
        } else {
            updateLiveActivityStatus()
        }

        // Apply voice speed from settings
        audioIO.playbackRate = Float(settings.voiceSpeed)
        audioIO.stressBaseline = settings.calibratedVoiceStressBaseline

        // Build personalised system prompt with session history + learned profile
        let personalisedPrompt = AnchorSystemPrompt.personalised(
            sessions: Array(previousSessions.prefix(10)),
            settings: userSettings,
            profile: profiles.first,
            sessionFocus: sessionFocus,
            persona: userSettings?.selectedPersona,
            lastCompletedSession: previousSessions.first(where: { $0.completed })
        )

        Task {
            // Initialize preferred STT engine (downloads WhisperKit model if needed)
            if LocalTranscriber.preferredEngine == .whisperKit {
                await localTranscriber.initializePreferredEngine()
            }
            
            await liveClient.connectIfNeeded(systemInstruction: personalisedPrompt)

            // Once connected, transition to listening.
            voiceController.update(.listening)

            let permissionGranted = await audioIO.requestPermission()
            guard permissionGranted else {
                showingMicAlert = true
                micPermissionDenied = true
                isRecording = false
                stopTimer()
                voiceController.reset()
                endLiveActivity()
                liveClient.disconnect()
                return
            }
            micPermissionDenied = false

            let speechPermissionGranted = await localTranscriber.requestAuthorization()

            do {
                try audioIO.start()
            } catch {
                configAlertMessage = error.localizedDescription
                showingConfigAlert = true
                isRecording = false
                stopTimer()
                voiceController.reset()
                endLiveActivity()
                return
            }

            guard speechPermissionGranted else {
                print(
                    "[ConversationView] Speech recognition permission unavailable; continuing without local transcription."
                )
                return
            }

            do {
                try localTranscriber.start()
            } catch {
                // Local STT is a quality boost; voice conversation should continue if it fails.
                print(
                    "[ConversationView] Local transcriber failed to start: \(error.localizedDescription)"
                )
            }
        }
    }

    private func startTimer(reset: Bool) {
        if reset {
            elapsedTime = 0
            activeUsageTime = 0
            conversationStartTime = Date()
        } else {
            conversationStartTime = Date().addingTimeInterval(-elapsedTime)
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                let currentState = voiceController.state
                elapsedTime = Date().timeIntervalSince(conversationStartTime)
                // Only count listening / speaking toward the free-tier quota.
                // Thinking and connecting time is the AI's overhead, not the user's.
                switch currentState {
                case .listening, .speaking:
                    activeUsageTime += 1
                default:
                    break
                }
                if let limit = freeSessionLimitSeconds, activeUsageTime >= limit {
                    handleLimitReached()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        endWarmup()
    }

    private func beginWarmup() {
        warmupWorkItem?.cancel()
        warmupActive = true
        let workItem = DispatchWorkItem {
            warmupActive = false
            warmupWorkItem = nil
        }
        warmupWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4, execute: workItem)
    }

    private func endWarmup() {
        warmupWorkItem?.cancel()
        warmupWorkItem = nil
        warmupActive = false
    }

    private var formattedElapsedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func formattedMinutes(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    private func recordUsage() {
        guard let settings = userSettings else { return }
        defer {
            didRecordUsage = true
            modelContext.safeSave()
        }

        if !settings.hasUnlimitedAccess {
            let used = min(activeUsageTime, freeSessionLimitSeconds ?? activeUsageTime)
            settings.recordUsage(seconds: used)
        }
    }

    private func handleLimitReached() {
        guard !didRecordUsage else { return }
        isRecording = false
        voiceController.reset()
        stopTimer()
        audioIO.stop()
        endLiveActivity()
        Task {
            await liveClient.sendAudioStreamEnd()
            liveClient.disconnect()
        }
        recordUsage()
        saveSession(completed: false)
        showingLimitAlert = true
    }

    @discardableResult
    private func saveSession(completed: Bool) -> Session? {
        guard elapsedTime > 10 else { return nil }
        guard !liveClient.messages.isEmpty else { return nil }

        // Quick fallback summary (used immediately, may be replaced by AI)
        let fallbackSummary = sessionFallbackSummary()
        let stressScore = audioIO.currentStressScore()
        let session = Session(
            timestamp: conversationStartTime,
            duration: elapsedTime,
            summary: fallbackSummary,
            moodBefore: moodBefore,
            moodAfter: moodAfter,
            tags: [],
            moodTriggers: Array(moodTriggers).sorted(),
            completed: completed,
            crisisDetected: crisisDetected,
            voiceStressScore: stressScore,
            sessionFocus: sessionFocus.rawValue
        )
        modelContext.insert(session)
        if let settings = userSettings {
            settings.totalSessions += 1
            settings.recordSessionForStreak()
            if let stressScore, elapsedTime >= 45, !crisisDetected {
                settings.updateVoiceStressBaseline(with: stressScore)
            }
        }
        modelContext.safeSave()
        // Sync widget data
        syncWidgetData()

        if let settings = userSettings {
            if !settings.isCheckInTimeOverridden {
                let recentSessions = [session] + Array(previousSessions.prefix(9))
                if let preferred = CheckInTimeEstimator.estimate(from: recentSessions) {
                    settings.preferredCheckInHour = preferred.hour
                    settings.preferredCheckInMinute = preferred.minute
                    modelContext.safeSave()
                    if settings.notificationsEnabled {
                        NotificationManager.shared.updateSchedule(
                            enabled: true, preferredTime: preferred)
                    }
                }
            }
        }

        if completed {
            prepareSummaryPayload(session: session)
        }

        // Fire-and-forget AI summarization to enrich the session & user profile
        let messagePairs = liveClient.messages.map { (role: $0.role.rawValue, text: $0.text) }
        let context = modelContext
        let capturedMoodBefore = moodBefore
        let capturedMoodAfter = moodAfter
        let profile = ensureUserProfile()
        let capturedSummaryContext = buildSummaryContext(profile: profile, session: session)
        Task.detached {
            let result = await SessionSummarizer.summarize(
                messages: messagePairs,
                summaryContext: capturedSummaryContext,
                retryCount: 1
            )
            await MainActor.run {
                switch result {
                case .success(let notes):
                    session.summary = notes.keyInsights
                    session.tags = notes.mainTopics
                    session.observedMood = notes.observedMood.isEmpty ? nil : notes.observedMood
                    session.copingStrategies = notes.copingStrategies
                    session.suggestedFollowUp =
                        notes.suggestedFollowUp.isEmpty ? nil : notes.suggestedFollowUp
                    session.narrativeSummary =
                        notes.narrativeSummary.isEmpty ? nil : notes.narrativeSummary
                    session.moodStartDescription =
                        notes.moodStartDescription.isEmpty ? nil : notes.moodStartDescription
                    session.moodEndDescription =
                        notes.moodEndDescription.isEmpty ? nil : notes.moodEndDescription
                    session.moodShiftDescription =
                        notes.moodShiftDescription.isEmpty ? nil : notes.moodShiftDescription
                    session.keyInsight = notes.keyInsight.isEmpty ? nil : notes.keyInsight
                    session.userQuotes = notes.userQuotes.isEmpty ? nil : notes.userQuotes
                    session.copingStrategiesExplored =
                        notes.copingStrategiesExplored.isEmpty
                        ? nil : notes.copingStrategiesExplored
                    session.actionItemsForTherapist =
                        notes.actionItemsForTherapist.isEmpty ? nil : notes.actionItemsForTherapist
                    session.recurringPatternAlert =
                        notes.recurringPatternAlert.isEmpty ? nil : notes.recurringPatternAlert
                    session.homework = notes.homework.isEmpty ? nil : notes.homework
                    session.summarySchemaVersion = notes.summarySchemaVersion
                    session.summaryRawJSON = notes.summaryRawJSON
                    session.sessionOrdinal = notes.sessionOrdinal ?? capturedSummaryContext.sessionOrdinal
                    session.primaryFocus = notes.primaryFocus.isEmpty ? nil : notes.primaryFocus
                    session.relatedThemes = notes.relatedThemes.isEmpty ? nil : notes.relatedThemes
                    session.moodStartIntensity = notes.moodStartIntensity
                    session.moodEndIntensity = notes.moodEndIntensity
                    session.moodStartPhysicalSymptoms =
                        notes.moodStartPhysicalSymptoms.isEmpty ? nil : notes.moodStartPhysicalSymptoms
                    session.moodEndPhysicalSymptoms =
                        notes.moodEndPhysicalSymptoms.isEmpty ? nil : notes.moodEndPhysicalSymptoms
                    session.patternRecognized =
                        notes.patternRecognized.isEmpty ? nil : notes.patternRecognized
                    session.recurringTopicsSnapshot =
                        notes.recurringTopicsSnapshot.isEmpty ? nil : notes.recurringTopicsSnapshot
                    session.recurringTopicsTrend =
                        notes.recurringTopicsTrend.isEmpty ? nil : notes.recurringTopicsTrend
                    session.copingStrategiesAttempted =
                        notes.copingStrategiesAttempted.isEmpty ? nil : notes.copingStrategiesAttempted
                    session.copingStrategiesWorked =
                        notes.copingStrategiesWorked.isEmpty ? nil : notes.copingStrategiesWorked
                    session.copingStrategiesDidntWork =
                        notes.copingStrategiesDidntWork.isEmpty ? nil : notes.copingStrategiesDidntWork
                    session.previousHomeworkAssigned =
                        notes.previousHomeworkAssigned.isEmpty ? nil : notes.previousHomeworkAssigned
                    session.previousHomeworkCompletion =
                        notes.previousHomeworkCompletion.isEmpty ? nil : notes.previousHomeworkCompletion
                    session.previousHomeworkReflection =
                        notes.previousHomeworkReflection.isEmpty ? nil : notes.previousHomeworkReflection
                    session.therapyGoalProgress =
                        notes.therapyGoalProgress.isEmpty ? nil : notes.therapyGoalProgress
                    session.actionItemsForUser =
                        notes.actionItemsForUser.isEmpty ? nil : notes.actionItemsForUser
                    session.continuityPeopleMentioned =
                        notes.continuityPeopleMentioned.isEmpty ? nil : notes.continuityPeopleMentioned
                    session.continuityUpcomingEvents =
                        notes.continuityUpcomingEvents.isEmpty ? nil : notes.continuityUpcomingEvents
                    session.continuityEnvironmentalFactors =
                        notes.continuityEnvironmentalFactors.isEmpty
                        ? nil : notes.continuityEnvironmentalFactors
                    session.crisisRiskDetectedByModel = notes.crisisRiskDetectedByModel
                    session.crisisNotes = notes.crisisNotes.isEmpty ? nil : notes.crisisNotes
                    session.protectiveFactors =
                        notes.protectiveFactors.isEmpty ? nil : notes.protectiveFactors
                    session.safetyRecommendation =
                        notes.safetyRecommendation.isEmpty ? nil : notes.safetyRecommendation
                    session.dominantEmotions =
                        notes.dominantEmotions.isEmpty ? nil : notes.dominantEmotions
                    session.primaryCopingStyle =
                        notes.primaryCopingStyle.isEmpty ? nil : notes.primaryCopingStyle
                    session.sessionEffectivenessSelfRating = notes.sessionEffectivenessSelfRating
                    session.crisisDetected = session.crisisDetected || (notes.crisisRiskDetectedByModel ?? false)
                    let parsedHomeworkItems = parseHomeworkItems(from: notes.homework)
                    session.homeworkItems = parsedHomeworkItems.isEmpty ? nil : parsedHomeworkItems
                    if !parsedHomeworkItems.isEmpty {
                        session.completedHomeworkItems = []
                        session.homeworkCompleted = false
                    }
                    summaryStatus = .ready
                    updateSummaryPayload(sessionID: session.id, notes: notes)
                    ProfileBuilder.integrate(
                        notes: notes,
                        moodBefore: capturedMoodBefore,
                        moodAfter: capturedMoodAfter,
                        into: profile,
                        context: context
                    )
                case .failure(let error):
                    summaryStatus = .failed(error.userMessage)
                }
            }
        }
        return session
    }

    private func sessionFallbackSummary() -> String {
        let assistantMessages = liveClient.messages.filter { $0.role == .assistant }
        let userMessages = liveClient.messages.filter { $0.role == .user }

        if let lastUser = userMessages.last, !lastUser.text.isEmpty {
            let snippet = lastUser.text.trimmingCharacters(in: .whitespacesAndNewlines)
            return String(snippet.prefix(200))
        }

        if let lastAssistant = assistantMessages.reversed().first(where: {
            !isLikelyGreeting($0.text) && !$0.text.isEmpty
        }) {
            let snippet = lastAssistant.text.trimmingCharacters(in: .whitespacesAndNewlines)
            return String(snippet.prefix(200))
        }

        if let last = assistantMessages.last, !last.text.isEmpty {
            let snippet = last.text.trimmingCharacters(in: .whitespacesAndNewlines)
            return String(snippet.prefix(200))
        }

        return String(localized: "Conversation with Anchor")
    }

    private func syncWidgetData() {
        let streak = userSettings?.currentStreak ?? 0
        let lastDate = userSettings?.lastSessionDate
        let total = userSettings?.totalSessions ?? 0
        let sessionTuples = previousSessions.prefix(30).map {
            (timestamp: $0.timestamp, moodBefore: $0.moodBefore, moodAfter: $0.moodAfter)
        }
        WidgetDataSync.sync(
            streak: streak,
            lastSessionDate: lastDate,
            sessions: sessionTuples,
            totalSessions: total
        )
    }

    /// Return the existing UserProfile or create a fresh one.
    private func ensureUserProfile() -> UserProfile {
        if let existing = profiles.first { return existing }
        let profile = UserProfile()
        modelContext.insert(profile)
        modelContext.safeSave()
        return profile
    }

    private func buildReflectionPrompt() -> String {
        let moodShift: String
        if let before = moodBefore, let after = moodAfter {
            if after > before {
                moodShift = String(localized: "It looks like you're feeling a bit better. ")
            } else if after < before {
                moodShift = String(localized: "It's okay if things still feel heavy. ")
            } else {
                moodShift = ""
            }
        } else {
            moodShift = ""
        }

        let prompts = [
            String.localizedStringWithFormat(
                String(
                    localized: "%@What's one thing you'd like to remember from this conversation?"),
                moodShift
            ),
            String.localizedStringWithFormat(
                String(
                    localized: "%@Is there a small step you could take today based on what came up?"
                ),
                moodShift
            ),
            String.localizedStringWithFormat(
                String(localized: "%@What felt most important to say out loud?"),
                moodShift
            ),
            String.localizedStringWithFormat(
                String(
                    localized:
                        "%@How would you describe what you're carrying right now in one sentence?"),
                moodShift
            ),
        ]
        return prompts.randomElement() ?? prompts[0]
    }

    private func handleSessionCompletion() {
        guard saveSession(completed: true) != nil else {
            finishEndConversation(completed: true)
            return
        }
        didSaveSession = true
        celebrationContent = buildCelebrationContent()
        showingCelebration = celebrationContent != nil
        if celebrationContent == nil {
            showingSummary = true
        }
    }

    private func buildCelebrationContent() -> CelebrationContent? {
        if let settings = userSettings {
            let milestones: Set<Int> = [3, 5, 7, 10, 14, 21, 30]
            if milestones.contains(settings.currentStreak) {
                return CelebrationContent(
                    title: String.localizedStringWithFormat(
                        String(localized: "🔥 %lld-day streak!"),
                        Int64(settings.currentStreak)
                    ),
                    subtitle: String(localized: "You’re building a steady habit."),
                    icon: "flame.fill",
                    accent: AnchorTheme.Colors.pulsePink
                )
            }
        }

        if let before = moodBefore, let after = moodAfter, after > before {
            return CelebrationContent(
                title: String(localized: "Mood lift"),
                subtitle: String.localizedStringWithFormat(
                    String(localized: "You moved from %@ to %@."),
                    MoodEmoji.emoji(for: before),
                    MoodEmoji.emoji(for: after)
                ),
                icon: "sparkles",
                accent: AnchorTheme.Colors.sageLeaf
            )
        }

        return CelebrationContent(
            title: String(localized: "Nice work showing up"),
            subtitle: String(localized: "Every check-in counts."),
            icon: "heart.fill",
            accent: AnchorTheme.Colors.etherBlue
        )
    }

    private func prepareSummaryPayload(session: Session) {
        var payload = SessionSummaryPayload(session: session)
        payload.takeaway = ""
        summaryPayload = payload
        summaryStatus = .summarizing
    }

    private func updateSummaryPayload(sessionID: UUID, notes: SessionSummarizer.SessionNotes) {
        guard var payload = summaryPayload, payload.sessionID == sessionID else { return }
        payload.topics = notes.mainTopics
        if !notes.keyInsights.isEmpty {
            payload.takeaway = notes.keyInsights
        }
        if !notes.observedMood.isEmpty {
            payload.observedMood = notes.observedMood
        }
        payload.copingStrategies = notes.copingStrategies
        if !notes.suggestedFollowUp.isEmpty {
            payload.suggestedFollowUp = notes.suggestedFollowUp
        }
        // Expanded fields
        if !notes.narrativeSummary.isEmpty {
            payload.narrativeSummary = notes.narrativeSummary
        }
        if !notes.moodStartDescription.isEmpty {
            payload.moodStartDescription = notes.moodStartDescription
        }
        if !notes.moodEndDescription.isEmpty {
            payload.moodEndDescription = notes.moodEndDescription
        }
        if !notes.moodShiftDescription.isEmpty {
            payload.moodShiftDescription = notes.moodShiftDescription
        }
        if !notes.keyInsight.isEmpty {
            payload.keyInsight = notes.keyInsight
        }
        payload.userQuotes = notes.userQuotes
        payload.copingStrategiesExplored = notes.copingStrategiesExplored
        payload.actionItemsForTherapist = notes.actionItemsForTherapist
        if !notes.recurringPatternAlert.isEmpty {
            payload.recurringPatternAlert = notes.recurringPatternAlert
        }
        if !notes.homework.isEmpty {
            payload.homework = notes.homework
            payload.homeworkItems = parseHomeworkItems(from: notes.homework)
            payload.completedHomeworkItems = []
        }
        payload.summarySchemaVersion = notes.summarySchemaVersion
        payload.summaryRawJSON = notes.summaryRawJSON ?? ""
        payload.sessionOrdinal = notes.sessionOrdinal
        payload.primaryFocus = notes.primaryFocus
        payload.relatedThemes = notes.relatedThemes
        payload.moodStartIntensity = notes.moodStartIntensity
        payload.moodEndIntensity = notes.moodEndIntensity
        payload.moodStartPhysicalSymptoms = notes.moodStartPhysicalSymptoms
        payload.moodEndPhysicalSymptoms = notes.moodEndPhysicalSymptoms
        payload.patternRecognized = notes.patternRecognized
        payload.recurringTopicsSnapshot = notes.recurringTopicsSnapshot
        payload.recurringTopicsTrend = notes.recurringTopicsTrend
        payload.copingStrategiesAttempted = notes.copingStrategiesAttempted
        payload.copingStrategiesWorked = notes.copingStrategiesWorked
        payload.copingStrategiesDidntWork = notes.copingStrategiesDidntWork
        payload.previousHomeworkAssigned = notes.previousHomeworkAssigned
        payload.previousHomeworkCompletion = notes.previousHomeworkCompletion
        payload.previousHomeworkReflection = notes.previousHomeworkReflection
        payload.therapyGoalProgress = notes.therapyGoalProgress
        payload.actionItemsForUser = notes.actionItemsForUser
        payload.continuityPeopleMentioned = notes.continuityPeopleMentioned
        payload.continuityUpcomingEvents = notes.continuityUpcomingEvents
        payload.continuityEnvironmentalFactors = notes.continuityEnvironmentalFactors
        payload.crisisRiskDetectedByModel = notes.crisisRiskDetectedByModel
        payload.crisisNotes = notes.crisisNotes
        payload.protectiveFactors = notes.protectiveFactors
        payload.safetyRecommendation = notes.safetyRecommendation
        payload.dominantEmotions = notes.dominantEmotions
        payload.primaryCopingStyle = notes.primaryCopingStyle
        payload.sessionEffectivenessSelfRating = notes.sessionEffectivenessSelfRating
        summaryPayload = payload
        summaryStatus = .ready
    }

    private func buildSummaryContext(profile: UserProfile, session: Session)
        -> SessionSummarizer.SummaryContext
    {
        let durationMinutes = max(1, Int((session.duration / 60).rounded()))
        let sessionOrdinal = userSettings?.totalSessions ?? max(1, previousSessions.count + 1)
        let priorSessions = previousSessions.filter { $0.id != session.id }
        let previousTopics = Array(Set(priorSessions.prefix(10).flatMap(\.tags))).sorted()
        let therapyGoals = profile.communicationNotes.isEmpty
            ? profile.emotionalPatterns
            : profile.communicationNotes
        let previousHomework = priorSessions.prefix(6).flatMap { prior in
            if let items = prior.homeworkItems, !items.isEmpty {
                return items
            }
            if let homework = prior.homework, !homework.isEmpty {
                return [homework]
            }
            return []
        }

        return SessionSummarizer.SummaryContext(
            sessionDate: session.timestamp,
            durationMinutes: durationMinutes,
            sessionOrdinal: sessionOrdinal,
            previousTopics: previousTopics,
            therapyGoals: Array(therapyGoals.prefix(8)),
            previousHomework: Array(previousHomework.prefix(6)),
            profileContext: profile.promptContext
        )
    }

    private func parseHomeworkItems(from homework: String) -> [String] {
        let normalized = homework.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return [] }

        let lines = normalized
            .components(separatedBy: .newlines)
            .flatMap { line -> [String] in
                if line.contains(";") {
                    return line.components(separatedBy: ";")
                }
                return [line]
            }
            .map { line in
                line
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "^-\\s*", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "^•\\s*", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "^\\d+\\.\\s*", with: "", options: .regularExpression)
            }
            .filter { !$0.isEmpty }

        var seen = Set<String>()
        var unique: [String] = []
        for item in lines {
            let key = item.lowercased()
            if seen.insert(key).inserted {
                unique.append(item)
            }
        }
        return unique
    }

    private func startLiveActivity() {
        liveActivityManager.start(
            sessionID: liveActivitySessionID,
            startedAt: conversationStartTime,
            status: liveActivityStatus(),
            focusTitle: liveActivityFocusTitle,
            isPrivate: liveActivityIsPrivate
        )
    }

    private func updateLiveActivityStatus() {
        let now = Date()
        let minInterval: TimeInterval = 2.0 // Throttle to max once per 2 seconds
        
        guard now.timeIntervalSince(lastLiveActivityUpdate) >= minInterval else {
            // Schedule pending update if not already scheduled
            if !pendingLiveActivityUpdate {
                pendingLiveActivityUpdate = true
                let delay = minInterval - now.timeIntervalSince(lastLiveActivityUpdate)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.pendingLiveActivityUpdate = false
                    self.updateLiveActivityStatus()
                }
            }
            return
        }
        
        lastLiveActivityUpdate = now
        pendingLiveActivityUpdate = false
        
        Task {
            await liveActivityManager.update(
                status: liveActivityStatus(),
                isPrivate: liveActivityIsPrivate
            )
        }
    }

    private func endLiveActivity() {
        Task {
            await liveActivityManager.end()
        }
    }

    private func liveActivityStatus() -> AnchorSessionActivityAttributes.Status {
        if isSessionPaused {
            return .paused
        }
        switch voiceController.state {
        case .connecting:
            return .connecting
        case .listening:
            return .listening
        case .thinking:
            return .thinking
        case .speaking:
            return .speaking
        case .idle, .crisis:
            return .listening
        }
    }

    private func consumeDeepLinkAction() {
        guard let action = deepLinkRouter.consumeAction() else { return }
        switch action {
        case .endSession:
            guard isRecording || elapsedTime > 0 else {
                endLiveActivity()
                return
            }
            endConversation()
        }
    }

    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            wasBackgrounded = true
        case .active:
            if wasBackgrounded {
                wasBackgrounded = false
                guard isRecording else { return }
                if liveClient.liveConnectionState != .ready {
                    voiceController.update(.connecting)
                    Task {
                        await liveClient.reconnectSession()
                        if liveClient.liveConnectionState == .ready {
                            voiceController.update(.listening)
                        }
                    }
                }
            }
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    private func isLikelyGreeting(_ text: String) -> Bool {
        let lowered = text.lowercased()
        return lowered.contains("i’m here with you")
            || lowered.contains("i'm here with you")
            || lowered.contains("want to share what’s on your mind")
            || lowered.contains("want to share what's on your mind")
            || lowered.contains("how are you feeling")
    }

    private func scanForCrisisKeywords(_ text: String) {
        guard !crisisDetected else { return }
        if CrisisKeywordScanner.containsCrisisLanguage(text) {
            handleCrisisDetected()
        }
    }

    private func handleCrisisDetected() {
        crisisDetected = true
        breathingSuggestion = nil
        showingBreathingExercise = false
        isSessionPaused = false
        voiceController.update(.crisis)
        wasRecordingBeforeCrisis = isRecording
        pauseForCrisis()
        showingCrisisInterruption = true
    }

    private func pauseForCrisis() {
        isRecording = false
        voiceController.reset()
        stopTimer()
        audioIO.stop()
        Task {
            await liveClient.sendAudioStreamEnd()
        }
    }

    private func resumeAfterCrisis() {
        showingCrisisInterruption = false
        guard wasRecordingBeforeCrisis else { return }
        wasRecordingBeforeCrisis = false
        isRecording = true
        startConversation(resetTimer: false)
    }

    private func endConversationAfterCrisis() {
        showingCrisisInterruption = false
        if !didRecordUsage {
            recordUsage()
        }
        moodAfter = nil
        showingMoodAfter = false
        finishEndConversation(completed: false)
    }

    private func handleLiveAction(_ action: LiveClientAction) {
        if shouldThrottleAction(action) {
            return
        }
        lastActionTimestamp = Date()
        switch action {
        case .crisisDetected:
            handleCrisisDetected()
        case .openCrisisResources:
            showingCrisisResources = true
        case .breathingSuggestion(let mode, let reason):
            presentBreathingSuggestion(mode: mode, reason: reason)
        }
    }

    private func shouldThrottleAction(_ action: LiveClientAction) -> Bool {
        switch action {
        case .crisisDetected:
            return false
        default:
            break
        }
        guard let lastActionTimestamp else { return false }
        return Date().timeIntervalSince(lastActionTimestamp) < actionCooldown
    }

    private func presentBreathingSuggestion(mode: BreathingPatternKind?, reason: String?) {
        guard !crisisDetected, breathingSuggestion == nil, !showingBreathingExercise else { return }
        breathingSuggestion = BreathingSuggestion(mode: mode, reason: reason)
    }

    private func startBreathingFlow(from suggestion: BreathingSuggestion) {
        let resolved =
            suggestion.mode ?? BreathingPatternCatalog.suggestedPattern(sessions: previousSessions)
        activeBreathingPattern = resolved
        breathingSuggestion = nil
        breathingInitiatedByModel = true
        pauseForBreathing()
        showingBreathingExercise = true
        Task {
            await liveClient.sendContextSignal(
                "[Signal] Breathing exercise started (mode: \(resolved.title)). Pause responses until complete."
            )
        }
    }

    private func pauseForBreathing() {
        wasRecordingBeforeBreathing = isRecording
        isSessionPaused = true
        isRecording = false
        voiceController.reset()
        stopTimer()
        audioIO.stop()
    }

    private func resumeAfterBreathing(didComplete: Bool) {
        showingBreathingExercise = false
        guard wasRecordingBeforeBreathing else { return }
        wasRecordingBeforeBreathing = false
        isSessionPaused = false
        isRecording = true
        startTimer(reset: false)
        Task {
            let granted = await audioIO.requestPermission()
            guard granted else {
                showingMicAlert = true
                micPermissionDenied = true
                isRecording = false
                stopTimer()
                voiceController.reset()
                return
            }
            micPermissionDenied = false

            do {
                try audioIO.start()
            } catch {
                configAlertMessage = error.localizedDescription
                showingConfigAlert = true
                isRecording = false
                stopTimer()
                voiceController.reset()
            }
            let note = didComplete ? "completed" : "ended early"
            await liveClient.sendContextSignal("[Signal] Breathing exercise \(note).")
        }
        voiceController.update(.listening)

        if didComplete && breathingInitiatedByModel {
            breathingInitiatedByModel = false
            Task {
                await liveClient.sendInternalRequest(
                    "[Internal] The user completed a breathing exercise. Welcome them back in 1–2 gentle sentences and ask if they want to continue."
                )
            }
        } else {
            breathingInitiatedByModel = false
        }
    }

    private func handleAudioInterruption(_ event: LiveAudioIO.AudioInterruptionEvent) {
        switch event {
        case .began:
            guard isRecording else { return }
            pauseForInterruption()
            showingAudioInterruptionAlert = true
        case .ended:
            break
        }
    }

    private func pauseForInterruption() {
        wasRecordingBeforeInterruption = isRecording
        isSessionPaused = true
        isRecording = false
        voiceController.reset()
        stopTimer()
        audioIO.stop()
    }

    private func resumeAfterInterruption() {
        guard wasRecordingBeforeInterruption else { return }
        wasRecordingBeforeInterruption = false
        isSessionPaused = false
        isRecording = true
        startTimer(reset: false)
        Task {
            let granted = await audioIO.requestPermission()
            guard granted else {
                showingMicAlert = true
                micPermissionDenied = true
                isRecording = false
                stopTimer()
                voiceController.reset()
                return
            }
            micPermissionDenied = false

            do {
                try audioIO.start()
            } catch {
                configAlertMessage = error.localizedDescription
                showingConfigAlert = true
                isRecording = false
                stopTimer()
                voiceController.reset()
            }
        }
        voiceController.update(.listening)
    }

    private func sendTextMessage() {
        let trimmed = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        textInput = ""
        Task {
            await liveClient.sendUserText(trimmed)
        }
    }

    private func updateLocalFallback() {
        let wasFallback = liveClient.localFallbackEnabled
        liveClient.localFallbackEnabled = shouldShowTextFallback
        if wasFallback && !shouldShowTextFallback {
            liveClient.disconnect()
        }
        if shouldShowTextFallback && isRecording {
            isRecording = false
            voiceController.reset()
            stopTimer()
            audioIO.stop()
            Task {
                await liveClient.sendAudioStreamEnd()
            }
        }
    }

    private func saveFlaggedResponse() {
        let report = FlaggedResponse(
            aiMessage: flaggedMessageText,
            userMessageBefore: flaggedUserContext,
            reason: flagReason
        )
        modelContext.insert(report)
        modelContext.safeSave()
    }

}

enum VoiceState {
    case idle
    case connecting
    case listening
    case thinking
    case speaking
    case crisis

    var orbState: OrbState {
        switch self {
        case .idle: return .idle
        case .connecting: return .connecting
        case .listening: return .listening
        case .thinking: return .thinking
        case .speaking: return .speaking
        case .crisis: return .crisis
        }
    }
}

private struct BreathingSuggestion: Identifiable {
    let id = UUID()
    let mode: BreathingPatternKind?
    let reason: String?
}

private struct BreathingSuggestionCard: View {
    let suggestion: BreathingSuggestion
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(AnchorTheme.Colors.warmStone)
                .frame(width: 36, height: 5)
                .padding(.top, 4)

            Image(systemName: "wind")
                .font(.system(size: 30))
                .accessibilityHidden(true)
                .foregroundStyle(AnchorTheme.Colors.etherBlue)

            Text(String(localized: "Try a breathing exercise?"))
                .font(AnchorTheme.Typography.headline)
                .anchorPrimaryText()

            Text(suggestionText)
                .font(AnchorTheme.Typography.bodyText)
                .anchorSecondaryText()
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                Button(action: onAccept) {
                    Text(String(localized: "Yes, guide me"))
                        .font(AnchorTheme.Typography.subheadline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(
                    AnchorPillButtonStyle(
                        background: AnchorTheme.Colors.sageLeaf,
                        foreground: AnchorTheme.Colors.softParchment))

                Button(action: onDecline) {
                    Text(String(localized: "Not now"))
                        .font(AnchorTheme.Typography.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(
                    AnchorPillButtonStyle(
                        background: AnchorTheme.Colors.warmStone,
                        foreground: AnchorTheme.Colors.quietInk))
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AnchorTheme.Colors.softParchment.ignoresSafeArea())
    }

    private var suggestionText: String {
        if let reason = suggestion.reason, !reason.isEmpty {
            return reason
        }
        if let mode = suggestion.mode {
            return String.localizedStringWithFormat(
                String(localized: "Anchor suggests %@ breathing to help you reset."),
                mode.title
            )
        }
        return String(localized: "Anchor can guide a short breathing exercise to help you reset.")
    }
}

struct MessageBubble: View {
    let text: String
    let isUser: Bool
    var isStreaming: Bool = false

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            HStack(alignment: .bottom, spacing: 2) {
                Text(text)
                    .font(AnchorTheme.Typography.bodyText)

                if isStreaming && !isUser {
                    StreamingDots()
                        .accessibilityLabel(String(localized: "Generating response"))
                }
            }
            .padding(12)
            .background(AnchorTheme.Colors.warmStone)
            .foregroundColor(AnchorTheme.Colors.quietInk)
            .cornerRadius(16)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                String.localizedStringWithFormat(
                    String(localized: "%@: %@"),
                    isUser ? String(localized: "You") : String(localized: "Anchor"),
                    text
                )
            )

            if !isUser { Spacer(minLength: 60) }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

/// Three small dots that pulse while the model is still streaming.
private struct StreamingDots: View {
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(AnchorTheme.Colors.quietInk.opacity(0.35))
                    .frame(width: 4, height: 4)
                    .scaleEffect(phase == i ? 1.3 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.45)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.15),
                        value: phase
                    )
            }
        }
        .onAppear { phase = 2 }
    }
}

#Preview {
    ConversationView()
        .environmentObject(VoiceStateController())
        .environmentObject(NetworkMonitor())
        .modelContainer(for: [Session.self, UserSettings.self], inMemory: true)
}
