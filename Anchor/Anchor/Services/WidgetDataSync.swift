//
//  WidgetDataSync.swift
//  Anchor
//
//  Syncs app data into a shared App Group container so widgets
//  can read it. Call after any session completes or mood changes.
//

import Foundation
import WidgetKit

/// Shared App Group suite name – must match the App Group capability
/// configured on both the main app target and the widget extension target.
let anchorAppGroup = "group.Sensh.Anchor"

// MARK: - Shared Codable Models

/// Lightweight snapshot of widget-relevant data, stored as JSON in UserDefaults.
struct WidgetData: Codable {
    var currentStreak: Int
    var lastSessionDate: Date?
    var lastMoodEmoji: String
    var lastMoodScore: Int?
    var dailyMoods: [DailyMood]       // last 7 days
    var totalSessions: Int
    var lastCheckInAgo: String         // "2h ago", "Yesterday", etc.

    static let empty = WidgetData(
        currentStreak: 0,
        lastSessionDate: nil,
        lastMoodEmoji: "😶",
        lastMoodScore: nil,
        dailyMoods: [],
        totalSessions: 0,
        lastCheckInAgo: "No sessions yet"
    )
}

struct DailyMood: Codable, Identifiable {
    var id: String { dateLabel }
    let dateLabel: String    // "Mon", "Tue", …
    let averageMood: Double  // 1.0–5.0
    let date: Date
}

// MARK: - Sync from Main App

enum WidgetDataSync {

    private static let key = "anchorWidgetData"

    /// Write current app state into the shared container and reload widgets.
    static func sync(
        streak: Int,
        lastSessionDate: Date?,
        sessions: [(timestamp: Date, moodBefore: Int?, moodAfter: Int?)],
        totalSessions: Int
    ) {
        let lastMood = sessions.first.flatMap { $0.moodAfter ?? $0.moodBefore }
        let emoji = MoodEmoji.emoji(for: lastMood)
        let dailyMoods = buildWeeklyMoods(from: sessions)
        let ago = relativeTimeString(from: lastSessionDate)

        let data = WidgetData(
            currentStreak: streak,
            lastSessionDate: lastSessionDate,
            lastMoodEmoji: emoji,
            lastMoodScore: lastMood,
            dailyMoods: dailyMoods,
            totalSessions: totalSessions,
            lastCheckInAgo: ago
        )

        guard let defaults = UserDefaults(suiteName: anchorAppGroup) else { return }
        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: key)
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Read the latest snapshot (used by widget extension).
    static func read() -> WidgetData {
        guard let defaults = UserDefaults(suiteName: anchorAppGroup),
              let jsonData = defaults.data(forKey: key),
              let data = try? JSONDecoder().decode(WidgetData.self, from: jsonData)
        else {
            return .empty
        }
        return data
    }

    // MARK: Helpers

    private static func buildWeeklyMoods(
        from sessions: [(timestamp: Date, moodBefore: Int?, moodAfter: Int?)]
    ) -> [DailyMood] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        var result: [DailyMood] = []

        for dayOffset in (0..<7).reversed() {
            guard let dayDate = cal.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let dayEnd = cal.date(byAdding: .day, value: 1, to: dayDate)!

            let dayMoods = sessions.compactMap { s -> Double? in
                guard s.timestamp >= dayDate && s.timestamp < dayEnd else { return nil }
                if let after = s.moodAfter { return Double(after) }
                if let before = s.moodBefore { return Double(before) }
                return nil
            }

            let avg = dayMoods.isEmpty ? 0 : dayMoods.reduce(0, +) / Double(dayMoods.count)
            result.append(DailyMood(
                dateLabel: formatter.string(from: dayDate),
                averageMood: avg,
                date: dayDate
            ))
        }
        return result
    }

    private static func relativeTimeString(from date: Date?) -> String {
        guard let date else { return String(localized: "No sessions yet") }
        let interval = Date().timeIntervalSince(date)
        switch interval {
        case ..<60:          return String(localized: "Just now")
        case ..<3600:
            return String.localizedStringWithFormat(String(localized: "%lldm ago"), Int64(interval / 60))
        case ..<86400:
            return String.localizedStringWithFormat(String(localized: "%lldh ago"), Int64(interval / 3600))
        case ..<172800:      return String(localized: "Yesterday")
        default:
            return String.localizedStringWithFormat(String(localized: "%lldd ago"), Int64(interval / 86400))
        }
    }
}
