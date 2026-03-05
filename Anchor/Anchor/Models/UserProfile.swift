//
//  UserProfile.swift
//  Anchor
//
//  Cumulative local profile built from session summaries.
//  The AI uses this to personalise conversations over time.
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    /// Recurring topics the user discusses (deduplicated, most recent first).
    var recurringTopics: [String]

    /// Coping strategies the user has found helpful or discussed positively.
    var preferredCopingStrategies: [String]

    /// Emotional patterns observed across sessions (e.g., "often anxious on weekday mornings").
    var emotionalPatterns: [String]

    /// Communication style notes (e.g., "prefers direct validation before advice").
    var communicationNotes: [String]

    /// Known triggers or stressors (e.g., "work deadlines", "family conflict").
    var knownTriggers: [String]

    /// Overall mood baseline description (updated each session).
    var moodBaseline: String

    /// Total sessions that have contributed to this profile.
    var sessionsAnalysed: Int

    /// Timestamp of the last update.
    var lastUpdated: Date

    init(
        recurringTopics: [String] = [],
        preferredCopingStrategies: [String] = [],
        emotionalPatterns: [String] = [],
        communicationNotes: [String] = [],
        knownTriggers: [String] = [],
        moodBaseline: String = "",
        sessionsAnalysed: Int = 0,
        lastUpdated: Date = Date()
    ) {
        self.recurringTopics = recurringTopics
        self.preferredCopingStrategies = preferredCopingStrategies
        self.emotionalPatterns = emotionalPatterns
        self.communicationNotes = communicationNotes
        self.knownTriggers = knownTriggers
        self.moodBaseline = moodBaseline
        self.sessionsAnalysed = sessionsAnalysed
        self.lastUpdated = lastUpdated
    }

    /// Whether the profile has any meaningful content.
    var hasContent: Bool {
        !recurringTopics.isEmpty ||
        !preferredCopingStrategies.isEmpty ||
        !emotionalPatterns.isEmpty ||
        !communicationNotes.isEmpty ||
        !knownTriggers.isEmpty ||
        !moodBaseline.isEmpty
    }

    /// A compact text block suitable for injection into the system prompt.
    var promptContext: String {
        guard hasContent else { return "" }
        var lines: [String] = []

        if !recurringTopics.isEmpty {
            lines.append("- Recurring topics: \(recurringTopics.prefix(8).joined(separator: ", "))")
        }
        if !knownTriggers.isEmpty {
            lines.append("- Known triggers/stressors: \(knownTriggers.prefix(6).joined(separator: ", "))")
        }
        if !preferredCopingStrategies.isEmpty {
            lines.append("- Coping strategies they value: \(preferredCopingStrategies.prefix(6).joined(separator: ", "))")
        }
        if !emotionalPatterns.isEmpty {
            lines.append("- Observed emotional patterns: \(emotionalPatterns.prefix(4).joined(separator: "; "))")
        }
        if !communicationNotes.isEmpty {
            lines.append("- Communication preferences: \(communicationNotes.prefix(3).joined(separator: "; "))")
        }
        if !moodBaseline.isEmpty {
            lines.append("- Current mood baseline: \(moodBaseline)")
        }

        return lines.joined(separator: "\n")
    }
}
