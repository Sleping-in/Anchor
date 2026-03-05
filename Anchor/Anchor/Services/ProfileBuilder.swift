//
//  ProfileBuilder.swift
//  Anchor
//
//  Distils session summary notes into the cumulative UserProfile.
//  Runs locally — no network calls. Uses simple set-merge logic
//  so the profile grows but stays bounded.
//

import Foundation
import SwiftData

enum ProfileBuilder {

    private static let maxTopics = 20
    private static let maxStrategies = 12
    private static let maxPatterns = 8
    private static let maxTriggers = 12
    private static let maxCommNotes = 6

    /// Merge new session notes into the user profile.
    /// Call this on the MainActor after summarisation completes.
    @MainActor
    static func integrate(
        notes: SessionSummarizer.SessionNotes,
        moodBefore: Int?,
        moodAfter: Int?,
        into profile: UserProfile,
        context: ModelContext
    ) {
        // ── Topics ──────────────────────────────────────────────
        let newTopics = (notes.mainTopics + notes.relatedThemes + notes.recurringTopicsSnapshot)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
        profile.recurringTopics = mergeUnique(
            existing: profile.recurringTopics,
            new: newTopics,
            limit: maxTopics
        )

        // ── Coping strategies ──────────────────────────────────
        // Merge both legacy and expanded coping strategy fields
        let legacyStrategies = notes.copingStrategies
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
        let expandedStrategies = notes.copingStrategiesExplored
            .map { strategy in
                // Strip emoji markers (✅, ⚠️) and effectiveness notes for profile storage
                let cleaned =
                    strategy
                    .replacingOccurrences(of: "✅ ", with: "")
                    .replacingOccurrences(of: "⚠️ ", with: "")
                    .components(separatedBy: "→").first ?? strategy
                return cleaned.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            }
            .filter { !$0.isEmpty }
        let attemptedStrategies = notes.copingStrategiesAttempted
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
        let workedStrategies = notes.copingStrategiesWorked
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
        let allStrategies = legacyStrategies + expandedStrategies + attemptedStrategies + workedStrategies
        profile.preferredCopingStrategies = mergeUnique(
            existing: profile.preferredCopingStrategies,
            new: allStrategies,
            limit: maxStrategies
        )

        let lessEffectiveStrategies = notes.copingStrategiesDidntWork
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { "Less effective strategy: \($0)" }
        if !lessEffectiveStrategies.isEmpty {
            profile.communicationNotes = mergeUnique(
                existing: profile.communicationNotes,
                new: lessEffectiveStrategies,
                limit: maxCommNotes
            )
        }

        // ── Mood baseline ──────────────────────────────────────
        if !notes.observedMood.isEmpty {
            profile.moodBaseline = notes.observedMood
        } else if !notes.dominantEmotions.isEmpty {
            profile.moodBaseline = notes.dominantEmotions.joined(separator: ", ")
        }

        // ── Emotional patterns (from mood shifts) ──────────────
        var newPatterns: [String] = []
        if let before = moodBefore, let after = moodAfter {
            let shift = after - before
            let description: String
            switch shift {
            case 2...: description = "Mood improved notably (\(before)→\(after))"
            case 1: description = "Slight mood improvement (\(before)→\(after))"
            case 0: description = "Mood stayed stable at \(before)/5"
            case -1: description = "Slight mood dip (\(before)→\(after))"
            default: description = "Mood dropped (\(before)→\(after))"
            }
            newPatterns.append(description)
        }
        if !notes.patternRecognized.isEmpty {
            newPatterns.append(notes.patternRecognized)
        }
        if !notes.recurringTopicsTrend.isEmpty {
            newPatterns.append("Recurring-topic trend: \(notes.recurringTopicsTrend)")
        }
        if !notes.dominantEmotions.isEmpty {
            newPatterns.append("Dominant emotions: \(notes.dominantEmotions.joined(separator: ", "))")
        }
        if !newPatterns.isEmpty {
            profile.emotionalPatterns = mergeUnique(
                existing: profile.emotionalPatterns,
                new: newPatterns,
                limit: maxPatterns
            )
        }

        let inferredTriggers = (notes.continuityEnvironmentalFactors + notes.recurringTopicsSnapshot)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
        if !inferredTriggers.isEmpty {
            profile.knownTriggers = mergeUnique(
                existing: profile.knownTriggers,
                new: inferredTriggers,
                limit: maxTriggers
            )
        }

        // ── Bookkeeping ────────────────────────────────────────
        profile.sessionsAnalysed += 1
        profile.lastUpdated = Date()
        do {
            try context.save()
        } catch {
            print("[ProfileBuilder] Failed to save profile: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    /// Merge new items into the front of the list, deduplicate, and cap the length.
    private static func mergeUnique(existing: [String], new: [String], limit: Int) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        // New items go first (most recent)
        for item in new {
            let key = item.lowercased()
            if seen.insert(key).inserted {
                result.append(item)
            }
        }
        // Then existing items
        for item in existing {
            let key = item.lowercased()
            if seen.insert(key).inserted {
                result.append(item)
            }
        }
        return Array(result.prefix(limit))
    }
}
