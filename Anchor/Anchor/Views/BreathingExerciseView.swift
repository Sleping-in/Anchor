//
//  BreathingExerciseView.swift
//  Anchor
//
//  Guided breathing exercise with animated circle.
//

import SwiftUI
import CoreHaptics
import SwiftData

struct BreathingExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Session.timestamp, order: .reverse) private var sessions: [Session]

    @State private var selectedPattern: BreathingPatternKind = .box
    private let allowsPatternSelection: Bool
    private let onCompleted: (() -> Void)?
    private let onExit: (() -> Void)?
    @State private var didComplete = false
    @State private var hasPickedPattern = false
    @State private var phase: BreathingPhase = .ready
    @State private var phaseLabel: String = BreathingPhase.ready.label
    @State private var circleScale: CGFloat = 0.5
    @State private var cyclesCompleted = 0
    @State private var currentStepIndex = 0
    @State private var isActive = false
    @State private var secondsRemaining = 0
    @State private var timer: Timer?
    @State private var hapticEngine: CHHapticEngine?

    private var currentPattern: BreathingPattern {
        BreathingPatternCatalog.pattern(for: selectedPattern)
    }

    private var suggestedPattern: BreathingPatternKind {
        BreathingPatternCatalog.suggestedPattern(sessions: sessions)
    }

    private var phaseColor: Color {
        switch phase {
        case .ready: return AnchorTheme.Colors.sageLeaf
        case .inhale: return AnchorTheme.Colors.etherBlue
        case .hold: return AnchorTheme.Colors.sageLeaf
        case .exhale: return AnchorTheme.Colors.pulsePink
        case .complete: return AnchorTheme.Colors.sageLeaf
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            if !isActive && allowsPatternSelection {
                VStack(alignment: .leading, spacing: 10) {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
                        spacing: 10
                    ) {
                        ForEach(BreathingPatternCatalog.patterns, id: \.kind) { pattern in
                            Button {
                                selectedPattern = pattern.kind
                                hasPickedPattern = true
                                resetExercise()
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                BreathingPatternCard(
                                    pattern: pattern,
                                    isSelected: selectedPattern == pattern.kind
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(pattern.name)
                            .accessibilityHint(String(localized: "Double tap to select this breathing pattern"))
                            .accessibilityAddTraits(selectedPattern == pattern.kind ? [.isSelected] : [])
                        }
                    }

                    BreathingPatternDetailsCard(
                        pattern: currentPattern,
                        isRecommended: currentPattern.kind == suggestedPattern
                    )
                }
                .padding(.top, 4)
                .transition(.move(edge: .top).combined(with: .opacity))
            } else if !isActive && !allowsPatternSelection {
                BreathingPatternDetailsCard(
                    pattern: currentPattern,
                    isRecommended: currentPattern.kind == suggestedPattern
                )
                .padding(.top, 4)
            }

            if isActive {
                Spacer(minLength: 12)
            } else {
                Spacer(minLength: 8)
            }

            VStack(spacing: 12) {
                Text(phaseLabel)
                    .font(AnchorTheme.Typography.headline)
                    .anchorPrimaryText()
                    .animation(.easeInOut(duration: 0.3), value: phaseLabel)

                if isActive && phase != .complete {
                    Text(secondsRemaining, format: .number)
                        .font(AnchorTheme.Typography.heading(size: 36))
                        .anchorSecondaryText()
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }

            ZStack {
                Circle()
                    .fill(phaseColor.opacity(0.25))
                    .frame(width: 260, height: 260)
                    .scaleEffect(circleScale * 1.15)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [phaseColor.opacity(0.8), phaseColor.opacity(0.3)],
                            center: .center,
                            startRadius: 10,
                            endRadius: 120
                        )
                    )
                    .frame(width: 220, height: 220)
                    .scaleEffect(circleScale)

                Circle()
                    .fill(phaseColor.opacity(0.5))
                    .frame(width: 100, height: 100)
                    .scaleEffect(circleScale * 0.9)
            }
            .frame(width: 260, height: 260)
            .accessibilityLabel(
                String.localizedStringWithFormat(
                    String(localized: "Breathing circle, %@"),
                    phaseLabel
                )
            )

            if isActive {
                HStack(spacing: 8) {
                    ForEach(0..<currentPattern.cycles, id: \.self) { i in
                        Circle()
                            .fill(i < cyclesCompleted ? AnchorTheme.Colors.sageLeaf : AnchorTheme.Colors.warmStone)
                            .frame(width: 10, height: 10)
                    }
                }

                Text(
                    String.localizedStringWithFormat(
                        String(localized: "Cycle %lld of %lld"),
                        Int64(min(cyclesCompleted + 1, currentPattern.cycles)),
                        Int64(currentPattern.cycles)
                    )
                )
                    .font(AnchorTheme.Typography.caption)
                    .anchorSecondaryText()
            }

            if isActive {
                Spacer(minLength: 12)
            } else {
                Spacer()
            }

            if phase == .complete {
                Button(String(localized: "Done")) {
                    didComplete = true
                    onCompleted?()
                    dismiss()
                }
                    .buttonStyle(AnchorPillButtonStyle(background: AnchorTheme.Colors.sageLeaf, foreground: AnchorTheme.Colors.softParchment))
                    .padding(.horizontal, 24)
            } else if !isActive {
                Button(String(localized: "Begin")) { startExercise() }
                    .buttonStyle(AnchorPillButtonStyle(background: AnchorTheme.Colors.sageLeaf, foreground: AnchorTheme.Colors.softParchment))
                    .padding(.horizontal, 24)
            }

            Spacer().frame(height: 10)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AnchorTheme.Colors.softParchment.ignoresSafeArea())
        .navigationTitle(String(localized: "Breathing Exercise"))
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            timer?.invalidate()
            hapticEngine?.stop()
            if !didComplete {
                onExit?()
            }
        }
        .onAppear {
            prepareHaptics()
            if !hasPickedPattern {
                selectedPattern = suggestedPattern
            }
        }
    }

    init(
        initialPattern: BreathingPatternKind = .box,
        allowsPatternSelection: Bool = true,
        onCompleted: (() -> Void)? = nil,
        onExit: (() -> Void)? = nil
    ) {
        _selectedPattern = State(initialValue: initialPattern)
        _hasPickedPattern = State(initialValue: !allowsPatternSelection)
        self.allowsPatternSelection = allowsPatternSelection
        self.onCompleted = onCompleted
        self.onExit = onExit
    }

    private func startExercise() {
        withAnimation(.easeInOut(duration: 0.35)) {
            isActive = true
        }
        cyclesCompleted = 0
        currentStepIndex = 0
        runNextStep()
    }

    private func resetExercise() {
        timer?.invalidate()
        withAnimation(.easeInOut(duration: 0.35)) {
            isActive = false
        }
        cyclesCompleted = 0
        currentStepIndex = 0
        phase = .ready
        phaseLabel = BreathingPhase.ready.label
        circleScale = 0.5
    }

    private func runNextStep() {
        guard cyclesCompleted < currentPattern.cycles else {
            completeExercise()
            return
        }

        let step = currentPattern.steps[currentStepIndex]
        startPhase(step) {
            currentStepIndex += 1
            if currentStepIndex >= currentPattern.steps.count {
                currentStepIndex = 0
                cyclesCompleted += 1
            }
            runNextStep()
        }
    }

    private func startPhase(_ step: BreathingStep, completion: @escaping () -> Void) {
        phase = step.phase
        phaseLabel = step.label
        secondsRemaining = Int(step.duration)

        withAnimation(.easeInOut(duration: step.duration)) {
            circleScale = step.scale
        }

        playPhaseHaptic(step.phase, duration: step.duration)

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                secondsRemaining -= 1
                if secondsRemaining <= 0 {
                    timer?.invalidate()
                    completion()
                }
            }
        }
    }

    private func completeExercise() {
        phase = .complete
        phaseLabel = BreathingPhase.complete.label
        timer?.invalidate()
        withAnimation(.easeInOut(duration: 0.6)) {
            circleScale = 0.7
        }
        playCompletionHaptic()
    }

    // MARK: - Haptics

    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let engine = try CHHapticEngine()
            engine.resetHandler = { [weak engine = Optional(engine)] in
                try? engine?.start()
            }
            try engine.start()
            hapticEngine = engine
        } catch {
            // Haptics unavailable — degrade gracefully
        }
    }

    private func playPhaseHaptic(_ phase: BreathingPhase, duration: TimeInterval) {
        guard let engine = hapticEngine else {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            return
        }

        do {
            let pattern: CHHapticPattern
            switch phase {
            case .inhale:
                pattern = try CHHapticPattern(events: [
                    CHHapticEvent(
                        eventType: .hapticContinuous,
                        parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                        ],
                        relativeTime: 0,
                        duration: duration
                    )
                ], parameters: [])
            case .exhale:
                pattern = try CHHapticPattern(events: [
                    CHHapticEvent(
                        eventType: .hapticContinuous,
                        parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                        ],
                        relativeTime: 0,
                        duration: duration
                    )
                ], parameters: [])
            case .hold:
                pattern = try CHHapticPattern(events: [
                    CHHapticEvent(
                        eventType: .hapticTransient,
                        parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                        ],
                        relativeTime: 0
                    )
                ], parameters: [])
            default:
                return
            }

            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }

    private func playCompletionHaptic() {
        guard let engine = hapticEngine else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return
        }

        do {
            let pattern = try CHHapticPattern(events: [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                    ],
                    relativeTime: 0
                )
            ], parameters: [])

            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

private struct BreathingPatternCard: View {
    let pattern: BreathingPattern
    let isSelected: Bool
    @ScaledMetric(relativeTo: .body) private var cardHeight: CGFloat = 64

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(pattern.name)
                .font(AnchorTheme.Typography.bodyText)
                .foregroundColor(isSelected ? AnchorTheme.Colors.softParchment : AnchorTheme.Colors.quietInk)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: cardHeight, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(isSelected ? AnchorTheme.Colors.sageLeaf : AnchorTheme.Colors.warmStone)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isSelected ? AnchorTheme.Colors.sageLeaf : AnchorTheme.Colors.warmSand.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: AnchorTheme.Colors.warmSand.opacity(isSelected ? 0.25 : 0.12), radius: 6, x: 0, y: 4)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

}

private struct BreathingPatternDetailsCard: View {
    let pattern: BreathingPattern
    let isRecommended: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(pattern.description)
                    .font(AnchorTheme.Typography.bodyText)
                    .anchorPrimaryText()
                    .lineLimit(2)
                Spacer()
                if isRecommended {
                    Text(String(localized: "Recommended"))
                        .font(AnchorTheme.Typography.smallCaption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(AnchorTheme.Colors.sageLeaf.opacity(0.18))
                        )
                        .foregroundColor(AnchorTheme.Colors.sageLeaf)
                }
            }

            Text(metaLine)
                .font(AnchorTheme.Typography.caption)
                .anchorSecondaryText()

            Text(stepSummary)
                .font(AnchorTheme.Typography.smallCaption)
                .anchorSecondaryText()
        }
        .anchorCard()
        .accessibilityElement(children: .combine)
    }

    private var patternSummary: String {
        String.localizedStringWithFormat(
            String(localized: "%lldx cycles • %@ total"),
            Int64(pattern.cycles),
            totalDurationText
        )
    }

    private var metaLine: String {
        String.localizedStringWithFormat(
            String(localized: "Best for %@ • %@"),
            pattern.recommendedFor,
            patternSummary
        )
    }

    private var stepSummary: String {
        pattern.steps.map { stepText($0) }.joined(separator: " · ")
    }

    private static let durationFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    private var totalDurationText: String {
        let total = Int(pattern.steps.reduce(0) { $0 + $1.duration } * Double(pattern.cycles))
        let minutes = total / 60
        let seconds = total % 60
        if minutes > 0 {
            return String.localizedStringWithFormat(
                String(localized: "%lldm %llds"),
                Int64(minutes),
                Int64(seconds)
            )
        }
        return String.localizedStringWithFormat(String(localized: "%llds"), Int64(seconds))
    }

    private func stepText(_ step: BreathingStep) -> String {
        let formatted = Self.durationFormatter.string(from: NSNumber(value: step.duration))
            ?? String(format: "%.0f", step.duration)
        return String.localizedStringWithFormat(
            String(localized: "%@ %@s"),
            step.label,
            formatted
        )
    }
}

#Preview {
    BreathingExerciseView()
        .modelContainer(for: Session.self, inMemory: true)
}
