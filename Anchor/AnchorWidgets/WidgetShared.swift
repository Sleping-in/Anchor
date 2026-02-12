//
//  WidgetShared.swift
//  AnchorWidgets
//
//  Shared timeline entry, data reader, and color palette
//  used across all Anchor widgets.
//

import WidgetKit
import SwiftUI

// MARK: - Shared Timeline Entry

struct AnchorTimelineEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Shared Timeline Provider

struct AnchorTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> AnchorTimelineEntry {
        AnchorTimelineEntry(date: .now, data: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (AnchorTimelineEntry) -> Void) {
        let entry = AnchorTimelineEntry(date: .now, data: context.isPreview ? .preview : WidgetDataSync.read())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AnchorTimelineEntry>) -> Void) {
        let data = WidgetDataSync.read()
        let entry = AnchorTimelineEntry(date: .now, data: data)
        // Refresh every 30 minutes
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Widget Colors (hardcoded since Asset Catalog isn't shared)

enum WidgetColors {
    static let softParchment = Color(light: Color(hex: "#FAF7F2"), dark: Color(hex: "#1C1B19"))
    static let warmStone     = Color(light: Color(hex: "#EDE8DE"), dark: Color(hex: "#292720"))
    static let warmSand      = Color(light: Color(hex: "#E2D9C8"), dark: Color(hex: "#383632"))
    static let quietInk      = Color(light: Color(hex: "#4E453B"), dark: Color(hex: "#EAE8E3"))
    static let quietInkSecondary = Color(light: Color(hex: "#7A6F63"), dark: Color(hex: "#ADA8A1"))
    static let sageLeaf      = Color(hex: "#8DA399")
    static let etherBlue     = Color(hex: "#38BDF8")
    static let pulsePink     = Color(hex: "#F472B6")
    static let thinkingViolet = Color(hex: "#A78BFA")
    static let crisisRed     = Color(hex: "#EF4444")
}

// MARK: - Color Helpers

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}

// MARK: - Preview Data

extension WidgetData {
    static let preview = WidgetData(
        currentStreak: 7,
        lastSessionDate: Calendar.current.date(byAdding: .hour, value: -3, to: .now),
        lastMoodEmoji: "🙂",
        lastMoodScore: 4,
        dailyMoods: previewWeek(),
        totalSessions: 23,
        lastCheckInAgo: "3h ago"
    )

    private static func previewWeek() -> [DailyMood] {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        let moods: [Double] = [3.0, 2.5, 3.5, 4.0, 3.0, 4.5, 4.0]
        return (0..<7).reversed().enumerated().map { i, dayOffset in
            let date = cal.date(byAdding: .day, value: -dayOffset, to: .now)!
            return DailyMood(dateLabel: fmt.string(from: date), averageMood: moods[i], date: date)
        }
    }
}
