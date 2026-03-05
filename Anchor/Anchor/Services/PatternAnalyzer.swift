//
//  PatternAnalyzer.swift
//  Anchor
//
//  Analyzes session history to find longitudinal patterns in topics,
//  mood change, coping strategy effectiveness, and recurring risks.
//

import Foundation
import SwiftData

enum PatternAnalyzer {

    struct TopicFrequency: Identifiable {
        let topic: String
        let count: Int
        let ratio: Double
        var id: String { topic }
    }

    struct TriggerFrequency: Identifiable {
        let trigger: String
        let count: Int
        var id: String { trigger }
    }

    struct StrategyEffectiveness: Identifiable {
        let strategy: String
        let mentions: Int
        let averageMoodShift: Double?
        var id: String { strategy }
    }

    struct MoodTrend {
        let averageShift: Double
        let positiveShiftRate: Double
        let recentDelta: Double?
        let crisisSessionCount: Int

        var isImproving: Bool {
            guard let recentDelta else { return averageShift > 0 }
            return recentDelta > 0.15
        }
    }

    struct AnalysisResult {
        let topicMoodCorrelations: [String: Double]  // Topic -> Avg Mood Shift
        let timeOfDayMood: [Int: Double]  // Hour (0-23) -> Avg Mood Shift
        let frequentTopics: [(topic: String, count: Int)]
        let totalSessionsAnalyzed: Int
        let topicFrequency: [TopicFrequency]
        let moodTrend: MoodTrend
        let effectiveStrategies: [StrategyEffectiveness]
        let riskyPatterns: [String]
        let triggerFrequency: [TriggerFrequency]
    }

    /// Analyzes recent sessions to find cross-session patterns.
    static func analyze(sessions: [Session], profile: UserProfile? = nil, limit: Int = 20)
        -> AnalysisResult
    {
        let recent = Array(sessions.prefix(limit))
        var topicMoodSums: [String: Double] = [:]
        var topicCounts: [String: Int] = [:]
        var hourMoodSums: [Int: Double] = [:]
        var hourCounts: [Int: Int] = [:]
        var strategyMoodSums: [String: Double] = [:]
        var strategyMoodCounts: [String: Int] = [:]
        var strategyMentionCounts: [String: Int] = [:]
        var triggerCounts: [String: Int] = [:]
        var shiftSeries: [Double] = []
        let crisisSessionCount = recent.filter(\.crisisDetected).count

        for session in recent {
            for trigger in session.moodTriggers ?? [] {
                let key = trigger.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !key.isEmpty else { continue }
                triggerCounts[key, default: 0] += 1
            }

            let strategies = normalizedStrategies(from: session)
            for strategy in strategies {
                strategyMentionCounts[strategy, default: 0] += 1
            }

            guard let before = session.moodBefore, let after = session.moodAfter else {
                continue
            }
            let shift = Double(after - before)
            shiftSeries.append(shift)

            // Time of day analysis
            let hour = Calendar.current.component(.hour, from: session.timestamp)
            hourMoodSums[hour, default: 0] += shift
            hourCounts[hour, default: 0] += 1

            // Topic analysis
            for topic in session.tags {
                let key = topic.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    .lowercased()
                guard !key.isEmpty else { continue }

                topicMoodSums[key, default: 0] += shift
                topicCounts[key, default: 0] += 1
            }

            for strategy in strategies {
                strategyMoodSums[strategy, default: 0] += shift
                strategyMoodCounts[strategy, default: 0] += 1
            }
        }

        // Calculate averages
        var topicCorrelations: [String: Double] = [:]
        for (topic, sum) in topicMoodSums {
            let count = topicCounts[topic] ?? 1
            if count >= 2 {  // Only consider topics appearing at least twice
                topicCorrelations[topic] = sum / Double(count)
            }
        }

        var timeCorrelations: [Int: Double] = [:]
        for (hour, sum) in hourMoodSums {
            let count = hourCounts[hour] ?? 1
            timeCorrelations[hour] = sum / Double(count)
        }

        // Frequent topics
        let sortedTopics = topicCounts.map { ($0.key, $0.value) }
            .sorted { $0.1 > $1.1 }

        let total = max(1, recent.count)
        let topicFrequency = sortedTopics.map {
            TopicFrequency(topic: $0.0, count: $0.1, ratio: Double($0.1) / Double(total))
        }

        let sortedTriggers = triggerCounts
            .map { TriggerFrequency(trigger: $0.key, count: $0.value) }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.trigger < rhs.trigger
                }
                return lhs.count > rhs.count
            }

        let effectiveStrategies = strategyMentionCounts.keys
            .map { strategy -> StrategyEffectiveness in
                let mentions = strategyMentionCounts[strategy, default: 0]
                let moodCount = strategyMoodCounts[strategy, default: 0]
                let averageShift =
                    moodCount > 0
                    ? strategyMoodSums[strategy, default: 0] / Double(moodCount)
                    : nil
                return StrategyEffectiveness(
                    strategy: strategy,
                    mentions: mentions,
                    averageMoodShift: averageShift
                )
            }
            .sorted { lhs, rhs in
                let left = lhs.averageMoodShift ?? -999
                let right = rhs.averageMoodShift ?? -999
                if left == right {
                    return lhs.mentions > rhs.mentions
                }
                return left > right
            }

        let moodTrend = buildMoodTrend(
            shifts: shiftSeries,
            crisisSessionCount: crisisSessionCount
        )

        let riskyPatterns = buildRiskPatterns(
            topicCorrelations: topicCorrelations,
            topicCounts: topicCounts,
            triggerCounts: triggerCounts,
            moodTrend: moodTrend,
            crisisSessionCount: crisisSessionCount,
            profile: profile
        )

        return AnalysisResult(
            topicMoodCorrelations: topicCorrelations,
            timeOfDayMood: timeCorrelations,
            frequentTopics: sortedTopics,
            totalSessionsAnalyzed: recent.count,
            topicFrequency: topicFrequency,
            moodTrend: moodTrend,
            effectiveStrategies: effectiveStrategies,
            riskyPatterns: riskyPatterns,
            triggerFrequency: sortedTriggers
        )
    }

    private static func normalizedStrategies(from session: Session) -> [String] {
        let explored = session.copingStrategiesExplored ?? []
        let legacy = session.copingStrategies ?? []
        let attempted = session.copingStrategiesAttempted ?? []
        let worked = session.copingStrategiesWorked ?? []
        let raw = explored.isEmpty ? (attempted.isEmpty ? legacy : attempted) : explored

        var seen = Set<String>()
        var output: [String] = []
        for item in raw + worked {
            let normalized = item
                .replacingOccurrences(of: "✅ ", with: "")
                .replacingOccurrences(of: "⚠️ ", with: "")
                .components(separatedBy: "→").first?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased() ?? ""
            guard !normalized.isEmpty else { continue }
            if seen.insert(normalized).inserted {
                output.append(normalized)
            }
        }
        return output
    }

    private static func buildMoodTrend(shifts: [Double], crisisSessionCount: Int) -> MoodTrend {
        guard !shifts.isEmpty else {
            return MoodTrend(
                averageShift: 0,
                positiveShiftRate: 0,
                recentDelta: nil,
                crisisSessionCount: crisisSessionCount
            )
        }

        let averageShift = shifts.reduce(0, +) / Double(shifts.count)
        let positiveShiftRate =
            Double(shifts.filter { $0 > 0 }.count) / Double(shifts.count)

        let recentDelta: Double?
        if shifts.count >= 4 {
            let midpoint = shifts.count / 2
            let firstHalf = Array(shifts.prefix(midpoint))
            let secondHalf = Array(shifts.suffix(shifts.count - midpoint))
            let firstMean = firstHalf.reduce(0, +) / Double(max(1, firstHalf.count))
            let secondMean = secondHalf.reduce(0, +) / Double(max(1, secondHalf.count))
            recentDelta = secondMean - firstMean
        } else {
            recentDelta = nil
        }

        return MoodTrend(
            averageShift: averageShift,
            positiveShiftRate: positiveShiftRate,
            recentDelta: recentDelta,
            crisisSessionCount: crisisSessionCount
        )
    }

    private static func buildRiskPatterns(
        topicCorrelations: [String: Double],
        topicCounts: [String: Int],
        triggerCounts: [String: Int],
        moodTrend: MoodTrend,
        crisisSessionCount: Int,
        profile: UserProfile?
    ) -> [String] {
        var patterns: [String] = []

        let negativeTopics = topicCorrelations
            .filter { topic, averageShift in
                averageShift < -0.2 && (topicCounts[topic] ?? 0) >= 3
            }
            .sorted { lhs, rhs in
                lhs.value < rhs.value
            }
            .prefix(3)
            .map { $0.key }
        if !negativeTopics.isEmpty {
            patterns.append(
                "Topics with repeated negative mood shifts: " + negativeTopics.joined(separator: ", ")
            )
        }

        let highTriggers = triggerCounts
            .filter { $0.value >= 3 }
            .sorted { lhs, rhs in
                if lhs.value == rhs.value { return lhs.key < rhs.key }
                return lhs.value > rhs.value
            }
            .prefix(3)
            .map { $0.key }
        if !highTriggers.isEmpty {
            patterns.append(
                "Recurring triggers across sessions: " + highTriggers.joined(separator: ", ")
            )
        }

        if crisisSessionCount > 0 {
            patterns.append("Crisis indicators were detected in \(crisisSessionCount) recent session(s).")
        }

        if !moodTrend.isImproving && moodTrend.averageShift < 0 {
            patterns.append("Recent sessions trend toward lower post-session mood scores.")
        }

        if let profile, !profile.knownTriggers.isEmpty {
            patterns.append(
                "Previously learned triggers: " + profile.knownTriggers.prefix(3).joined(separator: ", ")
            )
        }

        return patterns
    }
}
