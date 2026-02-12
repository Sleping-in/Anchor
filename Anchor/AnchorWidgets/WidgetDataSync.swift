//
//  WidgetDataSync.swift
//  AnchorWidgets
//
//  Duplicated subset of the main app's WidgetDataSync so the
//  widget extension can read from the shared App Group container.
//  Only the read path and Codable models are needed here.
//

import Foundation

let anchorAppGroup = "group.Sensh.Anchor"

// MARK: - Shared Codable Models

struct WidgetData: Codable {
    var currentStreak: Int
    var lastSessionDate: Date?
    var lastMoodEmoji: String
    var lastMoodScore: Int?
    var dailyMoods: [DailyMood]
    var totalSessions: Int
    var lastCheckInAgo: String

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
    let dateLabel: String
    let averageMood: Double
    let date: Date
}

// MARK: - Read-only access for widgets

enum WidgetDataSync {
    private static let key = "anchorWidgetData"

    static func read() -> WidgetData {
        guard let defaults = UserDefaults(suiteName: anchorAppGroup),
              let jsonData = defaults.data(forKey: key),
              let data = try? JSONDecoder().decode(WidgetData.self, from: jsonData)
        else {
            return .empty
        }
        return data
    }

    static func moodEmoji(for score: Int?) -> String {
        switch score {
        case 1: return "😞"
        case 2: return "😔"
        case 3: return "😐"
        case 4: return "🙂"
        case 5: return "😊"
        default: return "😐"
        }
    }
}
