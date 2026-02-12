//
//  QuickCheckInWidget.swift
//  AnchorWidgets
//
//  Small widget — one-tap launcher to start a new conversation.
//  Shows last check-in time and a friendly prompt.
//

import SwiftUI
import WidgetKit

struct QuickCheckInWidget: Widget {
    let kind = "QuickCheckInWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AnchorTimelineProvider()) { entry in
            QuickCheckInWidgetView(entry: entry)
                .containerBackground(WidgetColors.softParchment, for: .widget)
        }
        .configurationDisplayName("Quick Check-in")
        .description("Tap to start a conversation with Anchor.")
        .supportedFamilies([.systemSmall])
    }
}

private struct QuickCheckInWidgetView: View {
    let entry: AnchorTimelineEntry

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(WidgetColors.sageLeaf)
                    .frame(width: 52, height: 52)

                Image(systemName: "mic.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
            }

            Text(String(localized: "Check in"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(WidgetColors.quietInk)

            Text(entry.data.lastCheckInAgo)
                .font(.system(size: 11))
                .foregroundColor(WidgetColors.quietInkSecondary)

            if entry.data.totalSessions == 0 {
                Text(String(localized: "Tap to start"))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(WidgetColors.sageLeaf)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "anchor://conversation"))
        .containerBackground(for: .widget) { WidgetColors.softParchment }
    }
}

#Preview(as: .systemSmall) {
    QuickCheckInWidget()
} timeline: {
    AnchorTimelineEntry(date: .now, data: .preview)
    AnchorTimelineEntry(date: .now, data: .empty)
}
