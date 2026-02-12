//
//  MoodCheckInView.swift
//  Anchor
//
//  Mood check-in picker shown before and after conversations.
//

import SwiftUI
import UIKit

struct MoodCheckInView: View {
    let title: String
    let subtitle: String
    let onSelect: (Int) -> Void
    private let focusSelection: Binding<SessionFocus>?
    private let autoAdvanceOnSelect: Bool

    @State private var selectedMood: Int = 3
    @State private var didAutoAdvance = false
    private let feedback = UISelectionFeedbackGenerator()

    private let moods: [(Int, String, String)] = [
        (1, "😞", String(localized: "Very Low")),
        (2, "😔", String(localized: "Low")),
        (3, "😐", String(localized: "Okay")),
        (4, "🙂", String(localized: "Good")),
        (5, "😊", String(localized: "Great")),
    ]

    init(
        title: String,
        subtitle: String,
        focusSelection: Binding<SessionFocus>? = nil,
        autoAdvanceOnSelect: Bool = false,
        onSelect: @escaping (Int) -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.onSelect = onSelect
        self.focusSelection = focusSelection
        self.autoAdvanceOnSelect = autoAdvanceOnSelect
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(title)
                    .font(AnchorTheme.Typography.headline)
                    .anchorPrimaryText()
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(AnchorTheme.Typography.subheadline)
                    .anchorSecondaryText()
                    .multilineTextAlignment(.center)

                if let focusSelection {
                    SessionFocusPicker(selectedFocus: focusSelection)
                        .anchorCard()
                }

                HStack(spacing: 12) {
                    ForEach(moods, id: \.0) { mood in
                        Button {
                            selectedMood = mood.0
                            feedback.selectionChanged()
                            if autoAdvanceOnSelect && !didAutoAdvance {
                                didAutoAdvance = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    onSelect(selectedMood)
                                }
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Text(mood.1)
                                    .font(.system(size: selectedMood == mood.0 ? 44 : 34))
                                    .scaleEffect(selectedMood == mood.0 ? 1.12 : 1.0)
                                    .animation(.easeInOut(duration: 0.2), value: selectedMood)

                                Text(mood.2)
                                    .font(AnchorTheme.Typography.smallCaption)
                                    .anchorSecondaryText()
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .opacity(selectedMood == mood.0 ? 1.0 : 0.6)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedMood == mood.0 ? AnchorTheme.Colors.sageLeaf.opacity(0.12) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(
                            String.localizedStringWithFormat(
                                String(localized: "%@, mood %lld of 5"),
                                mood.2,
                                Int64(mood.0)
                            )
                        )
                        .accessibilityAddTraits(selectedMood == mood.0 ? [.isSelected] : [])
                    }
                }

                if autoAdvanceOnSelect {
                    Text(String(localized: "Tap a mood to continue."))
                        .font(AnchorTheme.Typography.caption)
                        .anchorSecondaryText()
                } else {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onSelect(selectedMood)
                    } label: {
                        Text(String(localized: "Continue"))
                            .font(AnchorTheme.Typography.subheadline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AnchorPillButtonStyle(
                        background: AnchorTheme.Colors.sageLeaf,
                        foreground: AnchorTheme.Colors.softParchment
                    ))
                    .padding(.horizontal, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .anchorScreenBackground()
        .onAppear {
            feedback.prepare()
            didAutoAdvance = false
        }
    }
}

private struct SessionFocusPicker: View {
    @Binding var selectedFocus: SessionFocus

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "What would you like to focus on?"))
                .font(AnchorTheme.Typography.caption)
                .anchorSecondaryText()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SessionFocus.allCases) { focus in
                        Button {
                            selectedFocus = focus
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Text(focus.title)
                                .font(AnchorTheme.Typography.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selectedFocus == focus ? AnchorTheme.Colors.sageLeaf.opacity(0.18) : AnchorTheme.Colors.warmStone)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(selectedFocus == focus ? AnchorTheme.Colors.sageLeaf : AnchorTheme.Colors.warmSand.opacity(0.4), lineWidth: 1)
                                )
                                .foregroundColor(AnchorTheme.Colors.quietInk)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selectedFocus == focus ? [.isSelected] : [])
                    }
                }
            }

            Text(selectedFocus.subtitle)
                .font(AnchorTheme.Typography.smallCaption)
                .anchorSecondaryText()
        }
    }
}

#Preview {
    MoodCheckInView(title: String(localized: "How are you feeling?"), subtitle: String(localized: "Before we begin, check in with yourself.")) { mood in
        print("Selected mood: \(mood)")
    }
}
