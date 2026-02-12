//
//  WeeklySummaryBuilder.swift
//  Anchor
//
//  Builds a shareable weekly summary without transcripts.
//

import Foundation

enum WeeklySummaryBuilder {
    static func summaryText(sessions: [Session], settings: UserSettings?, referenceDate: Date = Date()) -> String {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .weekOfYear, for: referenceDate)
        let start = interval?.start ?? calendar.startOfDay(for: referenceDate)
        let end = interval?.end ?? referenceDate

        let weeklySessions = sessions.filter { $0.timestamp >= start && $0.timestamp < end }
        let count = weeklySessions.count

        let beforeValues = weeklySessions.compactMap(\.moodBefore)
        let afterValues = weeklySessions.compactMap(\.moodAfter)

        let avgBefore = average(beforeValues)
        let avgAfter = average(afterValues)

        let shiftText: String
        if let avgBefore, let avgAfter {
            let diff = avgAfter - avgBefore
            let diffText = diff >= 0 ? "+\(String(format: "%.1f", diff))" : String(format: "%.1f", diff)
            let avgBeforeText = String(format: "%.1f", avgBefore)
            let avgAfterText = String(format: "%.1f", avgAfter)
            shiftText = String.localizedStringWithFormat(
                String(localized: "Mood avg: %@ → %@ (%@)"),
                avgBeforeText,
                avgAfterText,
                diffText
            )
        } else if let avgAfter {
            let avgAfterText = String(format: "%.1f", avgAfter)
            shiftText = String.localizedStringWithFormat(String(localized: "Mood avg: %@"), avgAfterText)
        } else {
            shiftText = String(localized: "Mood avg: —")
        }

        let topics = topTopics(from: weeklySessions, limit: 3)
        let topicText = topics.isEmpty
            ? String(localized: "Top topics: —")
            : {
                let topicList = topics.joined(separator: ", ")
                return String.localizedStringWithFormat(String(localized: "Top topics: %@"), topicList)
            }()

        let streakText: String
        if let settings {
            let dayLabel = settings.currentStreak == 1 ? String(localized: "day") : String(localized: "days")
            streakText = String.localizedStringWithFormat(
                String(localized: "Current streak: %lld %@"),
                Int64(settings.currentStreak),
                dayLabel
            )
        } else {
            streakText = String(localized: "Current streak: —")
        }

        let weekLabel = start.formatted(date: .abbreviated, time: .omitted)
        return [
            String(localized: "Anchor Weekly Check-in"),
            String.localizedStringWithFormat(String(localized: "Week of %@"), weekLabel),
            String.localizedStringWithFormat(String(localized: "Sessions: %lld"), Int64(count)),
            shiftText,
            topicText,
            streakText,
            String(localized: "(No transcripts included)")
        ].joined(separator: "\n")
    }

    private static func average(_ values: [Int]) -> Double? {
        guard !values.isEmpty else { return nil }
        return Double(values.reduce(0, +)) / Double(values.count)
    }

    private static func topTopics(from sessions: [Session], limit: Int) -> [String] {
        var counts: [String: Int] = [:]
        for session in sessions {
            for tag in session.tags {
                counts[tag, default: 0] += 1
            }
        }
        return counts.sorted { $0.value > $1.value }.prefix(limit).map { $0.key }
    }
}

struct WeeklySummaryPayload {
    let weekStart: Date
    let weekEnd: Date
    let sessionCount: Int
    let averageMoodBefore: Double?
    let averageMoodAfter: Double?
    let topTopics: [String]
    let currentStreak: Int?
}

extension WeeklySummaryBuilder {
    static func summaryPayload(
        sessions: [Session],
        settings: UserSettings?,
        referenceDate: Date = Date()
    ) -> WeeklySummaryPayload {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .weekOfYear, for: referenceDate)
        let start = interval?.start ?? calendar.startOfDay(for: referenceDate)
        let end = interval?.end ?? referenceDate

        let weeklySessions = sessions.filter { $0.timestamp >= start && $0.timestamp < end }

        let beforeValues = weeklySessions.compactMap(\.moodBefore)
        let afterValues = weeklySessions.compactMap(\.moodAfter)

        let avgBefore = average(beforeValues)
        let avgAfter = average(afterValues)
        let topics = topTopics(from: weeklySessions, limit: 4)

        return WeeklySummaryPayload(
            weekStart: start,
            weekEnd: end,
            sessionCount: weeklySessions.count,
            averageMoodBefore: avgBefore,
            averageMoodAfter: avgAfter,
            topTopics: topics,
            currentStreak: settings?.currentStreak
        )
    }
}
