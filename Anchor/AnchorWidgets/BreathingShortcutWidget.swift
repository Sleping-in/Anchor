//
//  BreathingShortcutWidget.swift
//  AnchorWidgets
//
//  Small widget — calming breathing shortcut with a subtle
//  animated ring and one-tap launch to the breathing exercise.
//

import SwiftUI
import WidgetKit

struct BreathingShortcutWidget: Widget {
    let kind = "BreathingShortcutWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AnchorTimelineProvider()) { entry in
            BreathingShortcutView(entry: entry)
                .containerBackground(WidgetColors.softParchment, for: .widget)
        }
        .configurationDisplayName("Breathing")
        .description("Quick access to a calming breathing exercise.")
        .supportedFamilies([.systemSmall])
    }
}

private struct BreathingShortcutView: View {
    let entry: AnchorTimelineEntry

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(WidgetColors.sageLeaf.opacity(0.2), lineWidth: 3)
                    .frame(width: 62, height: 62)

                // Inner filled circle
                Circle()
                    .fill(WidgetColors.sageLeaf.opacity(0.15))
                    .frame(width: 52, height: 52)

                Image(systemName: "wind")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(WidgetColors.sageLeaf)
            }

            Text(String(localized: "Breathe"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(WidgetColors.quietInk)

            Text(String(localized: "Take a moment"))
                .font(.system(size: 11))
                .foregroundColor(WidgetColors.quietInkSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "anchor://breathing"))
        .containerBackground(for: .widget) { WidgetColors.softParchment }
    }
}

#Preview(as: .systemSmall) {
    BreathingShortcutWidget()
} timeline: {
    AnchorTimelineEntry(date: .now, data: .preview)
}
