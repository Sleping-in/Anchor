//
//  MoodStreakWidget.swift
//  AnchorWidgets
//
//  Small widget — shows the user's current check-in streak
//  with a flame icon and motivational text.
//

import WidgetKit
import SwiftUI

struct MoodStreakWidget: Widget {
    let kind = "MoodStreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AnchorTimelineProvider()) { entry in
            MoodStreakWidgetView(entry: entry)
                .containerBackground(WidgetColors.softParchment, for: .widget)
        }
        .configurationDisplayName("Mood Streak")
        .description("Track your consecutive days of checking in with Anchor.")
        .supportedFamilies([.systemSmall])
    }
}

private struct MoodStreakWidgetView: View {
    let entry: AnchorTimelineEntry

    private var streak: Int { entry.data.currentStreak }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(WidgetColors.warmStone)
                    .frame(width: 56, height: 56)

                if streak > 0 {
                    Text("🔥")
                        .font(.system(size: 28))
                } else {
                    Image(systemName: "flame")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(WidgetColors.quietInkSecondary)
                }
            }

            Text(streak > 0 ? String(localized: "\(streak)") : String(localized: "–"))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(WidgetColors.quietInk)

            Text(streakLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(WidgetColors.quietInkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "anchor://home"))
        .containerBackground(for: .widget) { WidgetColors.softParchment }
    }

    private var streakLabel: String {
        switch streak {
        case 0:   return String(localized: "Start your streak")
        case 1:   return String(localized: "day streak")
        default:  return String(localized: "day streak 🎯")
        }
    }
}

#Preview(as: .systemSmall) {
    MoodStreakWidget()
} timeline: {
    AnchorTimelineEntry(date: .now, data: .preview)
    AnchorTimelineEntry(date: .now, data: .empty)
}
