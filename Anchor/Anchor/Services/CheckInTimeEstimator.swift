//
//  CheckInTimeEstimator.swift
//  Anchor
//
//  Learns a user's preferred check-in time from recent sessions.
//

import Foundation

enum CheckInTimeEstimator {
    /// Estimate a preferred check-in time (hour/minute) from recent sessions.
    static func estimate(from sessions: [Session], maxSamples: Int = 10) -> DateComponents? {
        let calendar = Calendar.current
        let recent = Array(sessions.prefix(maxSamples))
        guard !recent.isEmpty else { return nil }

        let minutesOfDay = recent.map { session -> Int in
            let hour = calendar.component(.hour, from: session.timestamp)
            let minute = calendar.component(.minute, from: session.timestamp)
            return hour * 60 + minute
        }

        let average = Double(minutesOfDay.reduce(0, +)) / Double(minutesOfDay.count)
        let rounded = Int((average / 15.0).rounded()) * 15
        let normalized = (rounded + 24 * 60) % (24 * 60)
        return DateComponents(hour: normalized / 60, minute: normalized % 60)
    }

    static func formatTime(hour: Int, minute: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        components.calendar = Calendar.current

        let date = components.date ?? Date()
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "h:mm a", options: 0, locale: formatter.locale)
        let formatted = formatter.string(from: date)
        return formatted.replacingOccurrences(of: ":00", with: "")
    }
}
