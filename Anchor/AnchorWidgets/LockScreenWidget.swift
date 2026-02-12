//
//  LockScreenWidget.swift
//  AnchorWidgets
//
//  Lock screen accessory widgets — streak count + last mood.
//  Supports circular, rectangular, and inline families.
//

import SwiftUI
import WidgetKit

struct LockScreenWidget: Widget {
    let kind = "LockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AnchorTimelineProvider()) { entry in
            LockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("Anchor")
        .description("Your streak and mood at a glance.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}

private struct LockScreenWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: AnchorTimelineEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                circularView
            case .accessoryRectangular:
                rectangularView
            case .accessoryInline:
                inlineView
            default:
                circularView
            }
        }
        .containerBackground(for: .widget) { Color.clear }
    }

    // MARK: - Circular (lock screen circle)

    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 1) {
                if entry.data.currentStreak > 0 {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                    Text(String(localized: "\(entry.data.currentStreak)"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                } else {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 16))
                    Text(String(localized: "–"))
                        .font(.system(size: 12, weight: .medium))
                }
            }
        }
        .widgetURL(URL(string: "anchor://home"))
    }

    // MARK: - Rectangular (lock screen wide)

    private var rectangularView: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "Anchor"))
                    .font(.system(size: 13, weight: .semibold))

                if entry.data.currentStreak > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                        Text(String(localized: "\(entry.data.currentStreak)-day streak"))
                            .font(.system(size: 11))
                    }
                } else {
                    Text(String(localized: "Start your streak"))
                        .font(.system(size: 11))
                }
            }

            Spacer()

            Text(entry.data.lastMoodEmoji)
                .font(.system(size: 22))
        }
        .widgetURL(URL(string: "anchor://home"))
    }

    // MARK: - Inline (single line on lock screen)

    private var inlineView: some View {
        HStack(spacing: 4) {
            if entry.data.currentStreak > 0 {
                Image(systemName: "flame.fill")
                Text(String(localized: "\(entry.data.currentStreak)d streak"))
            } else {
                Image(systemName: "leaf.fill")
                Text(String(localized: "Anchor"))
            }
            Text(entry.data.lastMoodEmoji)
        }
        .widgetURL(URL(string: "anchor://home"))
    }
}

#Preview(as: .accessoryCircular) {
    LockScreenWidget()
} timeline: {
    AnchorTimelineEntry(date: .now, data: .preview)
    AnchorTimelineEntry(date: .now, data: .empty)
}

#Preview(as: .accessoryRectangular) {
    LockScreenWidget()
} timeline: {
    AnchorTimelineEntry(date: .now, data: .preview)
}

#Preview(as: .accessoryInline) {
    LockScreenWidget()
} timeline: {
    AnchorTimelineEntry(date: .now, data: .preview)
}
