//
//  AnchorMomentView.swift
//  Anchor
//
//  Short calming micro-interaction with quote, ambient sound, and breath.
//

import Combine
import SwiftUI

struct AnchorMomentView: View {
    @Environment(\.dismiss) private var dismiss
    var showsCloseButton: Bool = true

    @State private var quote: String = ""
    @State private var author: String = ""
    @State private var isActive = false
    @State private var secondsRemaining = 30
    @State private var phaseLabel = String(localized: "Inhale")
    @State private var circleScale: CGFloat = 0.6
    @State private var soundEnabled = true

    @State private var ambientPlayer: AmbientSoundPlayer? = AmbientSoundPlayer()
    private let totalSeconds = 30
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private let quotes: [(String, String)] = [
        (String(localized: "Breathe. You are safe in this moment."), String(localized: "Anchor")),
        (String(localized: "Small steps are still progress."), String(localized: "Anchor")),
        (String(localized: "Let your shoulders soften. You’re doing your best."), String(localized: "Anchor")),
        (String(localized: "One breath at a time."), String(localized: "Anchor")),
        (String(localized: "Notice what is steady, even if it’s small."), String(localized: "Anchor"))
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Text(String(localized: "Anchor Moment"))
                    .font(AnchorTheme.Typography.headline)
                    .anchorPrimaryText()

                VStack(spacing: 6) {
                    Text(quote)
                        .font(AnchorTheme.Typography.bodyText)
                        .anchorPrimaryText()
                        .multilineTextAlignment(.center)
                    Text(author)
                        .font(AnchorTheme.Typography.caption)
                        .anchorSecondaryText()
                }
                .padding(.horizontal, 24)
            }

            VStack(spacing: 16) {
                Text(phaseLabel)
                    .font(AnchorTheme.Typography.subheadline)
                    .anchorPrimaryText()

                Text(secondsRemaining, format: .number)
                    .font(AnchorTheme.Typography.heading(size: 36))
                    .anchorSecondaryText()
                    .monospacedDigit()
                    .contentTransition(.numericText())

                ProgressView(value: progress)
                    .tint(AnchorTheme.Colors.sageLeaf)
                    .scaleEffect(x: 1.0, y: 1.4, anchor: .center)
                    .accessibilityLabel(String(localized: "Progress"))
                    .accessibilityValue(
                        String.localizedStringWithFormat(
                            String(localized: "%lld percent"),
                            Int64(progress * 100)
                        )
                    )

                ZStack {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(AnchorTheme.Colors.sageLeaf.opacity(0.35), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 255, height: 255)

                    Circle()
                        .fill(AnchorTheme.Colors.sageLeaf.opacity(0.18))
                        .frame(width: 240, height: 240)
                        .scaleEffect(circleScale * 1.1)

                    Circle()
                        .fill(AnchorTheme.Colors.sageLeaf.opacity(0.35))
                        .frame(width: 200, height: 200)
                        .scaleEffect(circleScale)
                }
            }

            Toggle(String(localized: "Ambient sound"), isOn: $soundEnabled)
                .tint(AnchorTheme.Colors.sageLeaf)
                .padding(.horizontal, 32)
                .onChange(of: soundEnabled) { _, newValue in
                    if newValue {
                        ambientPlayer?.start()
                    } else {
                        ambientPlayer?.stop()
                    }
                }

            Spacer()

            let buttonTitle = isActive ? String(localized: "Restart") : String(localized: "Begin")
            Button(buttonTitle) {
                startBreathing()
            }
            .buttonStyle(AnchorPillButtonStyle(background: AnchorTheme.Colors.sageLeaf, foreground: AnchorTheme.Colors.softParchment))
            .padding(.horizontal, 24)

            if showsCloseButton {
                Button(String(localized: "Close")) {
                    dismiss()
                }
                .font(AnchorTheme.Typography.caption)
                .padding(.bottom, 16)
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AnchorTheme.Colors.softParchment.ignoresSafeArea())
        .onAppear {
            if let selection = quotes.randomElement() {
                quote = String.localizedStringWithFormat(String(localized: "“%@”"), selection.0)
                author = selection.1
            }
            if soundEnabled {
                ambientPlayer?.start()
            }
            startBreathing()
        }
        .onDisappear {
            isActive = false
            ambientPlayer?.stop()
            ambientPlayer = nil
        }
        .onReceive(tick) { _ in
            guard isActive else { return }
            secondsRemaining -= 1
            let elapsed = totalSeconds - secondsRemaining
            updatePhase(for: elapsed)

            if secondsRemaining <= 0 {
                isActive = false
                phaseLabel = String(localized: "Complete")
                withAnimation(.easeInOut(duration: 0.6)) {
                    circleScale = 0.7
                }
            }
        }
    }

    private func startBreathing() {
        isActive = true
        secondsRemaining = totalSeconds
        updatePhase(for: 0)
        let phaseLength = 3

        withAnimation(.easeInOut(duration: Double(phaseLength))) {
            circleScale = 1.0
        }
    }

    private func updatePhase(for elapsedSeconds: Int) {
        let phaseLength = 3
        let phaseIndex = (elapsedSeconds / phaseLength) % 2
        if phaseIndex == 0 {
            phaseLabel = String(localized: "Inhale")
            withAnimation(.easeInOut(duration: Double(phaseLength))) {
                circleScale = 1.0
            }
        } else {
            phaseLabel = String(localized: "Exhale")
            withAnimation(.easeInOut(duration: Double(phaseLength))) {
                circleScale = 0.6
            }
        }
    }

    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return max(0, min(1, Double(secondsRemaining) / Double(totalSeconds)))
    }
}

#Preview {
    AnchorMomentView()
}
