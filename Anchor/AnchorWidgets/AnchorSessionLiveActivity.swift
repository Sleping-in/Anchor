//
//  AnchorSessionLiveActivity.swift
//  AnchorWidgets
//
//  Live Activity for active Anchor sessions.
//

import ActivityKit
import Foundation
import SwiftUI
import WidgetKit

struct AnchorSessionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AnchorSessionActivityAttributes.self) { context in
            AnchorSessionActivityView(context: context)
                .activityBackgroundTint(WidgetColors.warmStone)
                .activitySystemActionForegroundColor(WidgetColors.quietInk)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        PulseOrbView(
                            size: 10, status: context.state.status,
                            isPrivate: context.state.isPrivate)
                        Text(statusShortLabel(context.state))
                            .font(.caption)
                            .foregroundStyle(WidgetColors.quietInk)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(
                        focusLabel(
                            context.attributes.focusTitle, isPrivate: context.state.isPrivate)
                    )
                    .font(.caption2)
                    .foregroundStyle(WidgetColors.quietInkSecondary)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.startedAt, style: .timer)
                        .font(.caption2)
                        .foregroundStyle(WidgetColors.quietInkSecondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        Text(String(localized: "Tap to return"))
                            .font(.caption2)
                            .foregroundStyle(WidgetColors.quietInkSecondary)
                        Spacer(minLength: 0)
                        if let endURL = activityURL(context, action: "end") {
                            Link(destination: endURL) {
                                Text(String(localized: "End session"))
                                    .font(.caption2)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(WidgetColors.warmSand.opacity(0.65))
                                    .foregroundStyle(WidgetColors.quietInk)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            } compactLeading: {
                PulseOrbView(
                    size: 8, status: context.state.status, isPrivate: context.state.isPrivate)
            } compactTrailing: {
                Text(context.attributes.startedAt, style: .timer)
                    .font(.caption2)
                    .foregroundStyle(WidgetColors.quietInkSecondary)
            } minimal: {
                PulseOrbView(
                    size: 8, status: context.state.status, isPrivate: context.state.isPrivate)
            }
            .widgetURL(activityURL(context))
        }
    }
}

private struct AnchorSessionActivityView: View {
    let context: ActivityViewContext<AnchorSessionActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            PulseOrbView(size: 18, status: context.state.status, isPrivate: context.state.isPrivate)

            VStack(alignment: .leading, spacing: 4) {
                Text(statusHeadline(context.state))
                    .font(.headline)
                    .foregroundStyle(WidgetColors.quietInk)

                Text(statusSubheadline(context.state))
                    .font(.caption)
                    .foregroundStyle(WidgetColors.quietInkSecondary)

                if let focus = focusBadgeTitle(
                    context.attributes.focusTitle, isPrivate: context.state.isPrivate)
                {
                    Text(focus)
                        .font(.caption2)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(WidgetColors.warmSand.opacity(0.6))
                        .foregroundStyle(WidgetColors.quietInk)
                        .clipShape(Capsule())
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 6) {
                Text(context.attributes.startedAt, style: .timer)
                    .font(.subheadline)
                    .foregroundStyle(WidgetColors.quietInkSecondary)

                if let endURL = activityURL(context, action: "end") {
                    Link(destination: endURL) {
                        Text(String(localized: "End"))
                            .font(.caption2)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(WidgetColors.warmSand.opacity(0.65))
                            .foregroundStyle(WidgetColors.quietInk)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .widgetURL(activityURL(context))
    }
}

private struct PulseOrbView: View {
    let size: CGFloat
    let status: AnchorSessionActivityAttributes.Status
    let isPrivate: Bool

    var body: some View {
        TimelineView(.animation) { context in
            let speed = pulseSpeed(for: status, isPrivate: isPrivate)
            let pulse = 0.5 + 0.5 * sin(context.date.timeIntervalSinceReferenceDate * speed)
            let outerScale = 1.55 + pulse * 0.45
            let midScale = 1.12 + pulse * 0.2
            let color = orbColor(for: status, isPrivate: isPrivate)

            ZStack {
                Circle()
                    .fill(color.opacity(0.18))
                    .frame(width: size * outerScale, height: size * outerScale)
                Circle()
                    .fill(color.opacity(0.4))
                    .frame(width: size * midScale, height: size * midScale)
                Circle()
                    .fill(color)
                    .frame(width: size, height: size)
            }
        }
        .accessibilityHidden(true)
    }
}

private func orbColor(for status: AnchorSessionActivityAttributes.Status, isPrivate: Bool) -> Color
{
    if isPrivate {
        return WidgetColors.sageLeaf
    }
    switch status {
    case .connecting:
        return WidgetColors.warmSand
    case .listening:
        return WidgetColors.etherBlue
    case .thinking:
        return WidgetColors.thinkingViolet
    case .speaking:
        return WidgetColors.pulsePink
    case .paused:
        return WidgetColors.quietInkSecondary
    case .ended:
        return WidgetColors.quietInkSecondary
    }
}

private func pulseSpeed(for status: AnchorSessionActivityAttributes.Status, isPrivate: Bool)
    -> Double
{
    if isPrivate { return 1.2 }
    switch status {
    case .connecting: return 2.6
    case .listening: return 2.0
    case .thinking: return 1.3
    case .speaking: return 3.0
    case .paused: return 0.8
    case .ended: return 0.6
    }
}

private func statusHeadline(_ state: AnchorSessionActivityAttributes.ContentState) -> String {
    if state.isPrivate {
        return String(localized: "Session active")
    }
    switch state.status {
    case .connecting: return String(localized: "Connecting…")
    case .listening: return String(localized: "Listening for you")
    case .thinking: return String(localized: "Thinking it through")
    case .speaking: return String(localized: "Speaking with you")
    case .paused: return String(localized: "Session paused")
    case .ended: return String(localized: "Session ended")
    }
}

private func statusSubheadline(_ state: AnchorSessionActivityAttributes.ContentState) -> String {
    if state.isPrivate {
        return String(localized: "Anchor session")
    }
    switch state.status {
    case .connecting: return String(localized: "Getting things ready")
    case .listening: return String(localized: "Say what’s on your mind")
    case .thinking: return String(localized: "Putting the words together")
    case .speaking: return String(localized: "Responding now")
    case .paused: return String(localized: "Tap to resume when ready")
    case .ended: return String(localized: "Thanks for checking in")
    }
}

private func statusShortLabel(_ state: AnchorSessionActivityAttributes.ContentState) -> String {
    if state.isPrivate {
        return String(localized: "Active")
    }
    switch state.status {
    case .connecting: return String(localized: "Connecting")
    case .listening: return String(localized: "Listening")
    case .thinking: return String(localized: "Thinking")
    case .speaking: return String(localized: "Speaking")
    case .paused: return String(localized: "Paused")
    case .ended: return String(localized: "Ended")
    }
}

private func focusLabel(_ focusTitle: String?, isPrivate: Bool) -> String {
    guard let focusTitle, !focusTitle.isEmpty, !isPrivate else {
        return String(localized: "Anchor")
    }
    return focusTitle
}

private func focusBadgeTitle(_ focusTitle: String?, isPrivate: Bool) -> String? {
    guard let focusTitle, !focusTitle.isEmpty, !isPrivate else { return nil }
    return String(localized: "Focus · \(focusTitle)")
}

private func activityURL(
    _ context: ActivityViewContext<AnchorSessionActivityAttributes>,
    action: String? = nil
) -> URL? {
    var components = URLComponents()
    components.scheme = "anchor"
    components.host = "conversation"
    var items: [URLQueryItem] = [
        URLQueryItem(name: "session", value: context.attributes.sessionID.uuidString)
    ]
    if let action {
        items.append(URLQueryItem(name: "action", value: action))
    }
    components.queryItems = items
    return components.url
}
