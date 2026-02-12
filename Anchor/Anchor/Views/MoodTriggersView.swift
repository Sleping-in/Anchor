//
//  MoodTriggersView.swift
//  Anchor
//
//  Quick tags to capture mood influences after a session.
//

import SwiftUI

struct MoodTriggersView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selected: Set<String>
    let onDone: () -> Void

    private let tags = MoodTriggerTag.allCases

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "What influenced your mood today?"))
                        .font(AnchorTheme.Typography.headline)
                        .anchorPrimaryText()
                    Text(String(localized: "Choose any that feel relevant — this helps Anchor spot patterns."))
                        .font(AnchorTheme.Typography.subheadline)
                        .anchorSecondaryText()
                }

                FlowLayout(spacing: 10) {
                    ForEach(tags) { tag in
                        let isSelected = selected.contains(tag.rawValue)
                        Button {
                            if isSelected {
                                selected.remove(tag.rawValue)
                            } else {
                                selected.insert(tag.rawValue)
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Text(tag.label)
                                .font(AnchorTheme.Typography.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(isSelected ? AnchorTheme.Colors.sageLeaf.opacity(0.2) : AnchorTheme.Colors.warmStone)
                                .foregroundColor(AnchorTheme.Colors.quietInk)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(isSelected ? AnchorTheme.Colors.sageLeaf : AnchorTheme.Colors.warmSand.opacity(0.4), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                    }
                }

                Spacer()

                Button {
                    onDone()
                } label: {
                    Text(String(localized: "Continue"))
                        .font(AnchorTheme.Typography.subheadline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AnchorPillButtonStyle(background: AnchorTheme.Colors.sageLeaf, foreground: AnchorTheme.Colors.softParchment))
            }
            .padding(24)
            .navigationTitle(String(localized: "Mood Triggers"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "Skip")) {
                        onDone()
                    }
                }
            }
        }
        .anchorScreenBackground()
    }
}

#Preview {
    MoodTriggersView(selected: .constant([MoodTriggerTag.work.rawValue])) {}
}
