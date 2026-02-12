//
//  WeeklyMoodTrendWidget.swift
//  AnchorWidgets
//
//  Medium widget — shows a 7-day mood bar chart with
//  today's mood highlighted and the current streak.
//

import SwiftUI
import WidgetKit

struct WeeklyMoodTrendWidget: Widget {
    let kind = "WeeklyMoodTrendWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AnchorTimelineProvider()) { entry in
            WeeklyMoodTrendView(entry: entry)
                .containerBackground(WidgetColors.softParchment, for: .widget)
        }
        .configurationDisplayName("Weekly Mood")
        .description("See how your mood has changed over the past week.")
        .supportedFamilies([.systemMedium])
    }
}

private struct WeeklyMoodTrendView: View {
    let entry: AnchorTimelineEntry

    private var moods: [DailyMood] { entry.data.dailyMoods }
    private var hasData: Bool { moods.contains { $0.averageMood > 0 } }

    var body: some View {
        Group {
            if hasData {
                filledView
            } else {
                emptyView
            }
        }
        .containerBackground(for: .widget) { WidgetColors.softParchment }
    }

    private var filledView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "Weekly Mood"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(WidgetColors.quietInk)
                    Text(entry.data.lastCheckInAgo)
                        .font(.system(size: 11))
                        .foregroundColor(WidgetColors.quietInkSecondary)
                }
                Spacer()
                if entry.data.currentStreak > 0 {
                    HStack(spacing: 3) {
                        Text("🔥")
                            .font(.system(size: 12))
                        Text(String(localized: "\(entry.data.currentStreak)"))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(WidgetColors.quietInk)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(WidgetColors.warmStone)
                    .clipShape(Capsule())
                }
            }

            // Bar chart
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(moods) { mood in
                    VStack(spacing: 4) {
                        if mood.averageMood > 0 {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(barColor(for: mood.averageMood))
                                .frame(height: barHeight(mood.averageMood))
                        } else {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(WidgetColors.warmStone)
                                .frame(height: 4)
                        }
                        Text(mood.dateLabel)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(
                                isToday(mood.date)
                                    ? WidgetColors.quietInk
                                    : WidgetColors.quietInkSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .widgetURL(URL(string: "anchor://insights"))
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 28))
                .foregroundColor(WidgetColors.quietInkSecondary)
            Text(String(localized: "No mood data yet"))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(WidgetColors.quietInk)
            Text(String(localized: "Complete a session to start tracking"))
                .font(.system(size: 11))
                .foregroundColor(WidgetColors.quietInkSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "anchor://conversation"))
    }

    // MARK: Helpers

    private func barHeight(_ value: Double) -> CGFloat {
        let maxHeight: CGFloat = 48
        return CGFloat(value / 5.0) * maxHeight
    }

    private func barColor(for mood: Double) -> Color {
        switch mood {
        case ..<2.0: return WidgetColors.crisisRed.opacity(0.7)
        case ..<3.0: return Color.orange.opacity(0.7)
        case ..<4.0: return WidgetColors.sageLeaf.opacity(0.8)
        default: return WidgetColors.sageLeaf
        }
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}

#Preview(as: .systemMedium) {
    WeeklyMoodTrendWidget()
} timeline: {
    AnchorTimelineEntry(date: .now, data: .preview)
    AnchorTimelineEntry(date: .now, data: .empty)
}
