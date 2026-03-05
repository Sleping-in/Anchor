//
//  DataExporter.swift
//  Anchor
//
//  Shared data export utility. Produces a JSON file containing
//  all sessions and the learned user profile, ready for sharing.
//

import Foundation

enum DataExporter {

    /// Build and write the full export JSON (sessions + profile) to a temp file.
    /// Returns the file URL on success, or nil on failure.
    static func exportAll(
        sessions: [Session],
        profile: UserProfile?
    ) -> URL? {
        let sessionDicts: [[String: Any]] = sessions.map { session in
            var dict: [String: Any] = [
                "id": session.id.uuidString,
                "date": ISO8601DateFormatter().string(from: session.timestamp),
                "duration": session.duration,
                "summary": session.summary,
                "tags": session.tags,
                "moodTriggers": session.moodTriggers ?? [],
                "completed": session.completed,
                "crisisDetected": session.crisisDetected,
            ]
            if let mood = session.moodBefore { dict["moodBefore"] = mood }
            if let mood = session.moodAfter { dict["moodAfter"] = mood }
            if let stress = session.voiceStressScore { dict["voiceStressScore"] = stress }
            if let focus = session.sessionFocus { dict["sessionFocus"] = focus }
            if let observedMood = session.observedMood, !observedMood.isEmpty {
                dict["observedMood"] = observedMood
            }
            if let coping = session.copingStrategies, !coping.isEmpty {
                dict["copingStrategies"] = coping
            }
            if let followUp = session.suggestedFollowUp, !followUp.isEmpty {
                dict["suggestedFollowUp"] = followUp
            }
            if let narrative = session.narrativeSummary, !narrative.isEmpty {
                dict["narrativeSummary"] = narrative
            }
            if let moodStart = session.moodStartDescription, !moodStart.isEmpty {
                dict["moodStartDescription"] = moodStart
            }
            if let moodEnd = session.moodEndDescription, !moodEnd.isEmpty {
                dict["moodEndDescription"] = moodEnd
            }
            if let moodShift = session.moodShiftDescription, !moodShift.isEmpty {
                dict["moodShiftDescription"] = moodShift
            }
            if let insight = session.keyInsight, !insight.isEmpty {
                dict["keyInsight"] = insight
            }
            if let quotes = session.userQuotes, !quotes.isEmpty {
                dict["userQuotes"] = quotes
            }
            if let explored = session.copingStrategiesExplored, !explored.isEmpty {
                dict["copingStrategiesExplored"] = explored
            }
            if let items = session.actionItemsForTherapist, !items.isEmpty {
                dict["actionItemsForTherapist"] = items
            }
            if let pattern = session.recurringPatternAlert, !pattern.isEmpty {
                dict["recurringPatternAlert"] = pattern
            }
            if let homeworkItems = session.homeworkItems, !homeworkItems.isEmpty {
                dict["homeworkItems"] = homeworkItems
            }
            if let completedHomeworkItems = session.completedHomeworkItems,
                !completedHomeworkItems.isEmpty
            {
                dict["completedHomeworkItems"] = completedHomeworkItems
            }
            if let homework = session.homework, !homework.isEmpty {
                dict["homework"] = homework
                dict["homeworkCompleted"] = session.homeworkCompleted
            }
            if let schemaVersion = session.summarySchemaVersion {
                dict["summarySchemaVersion"] = schemaVersion
            }
            if let summaryRawJSON = session.summaryRawJSON, !summaryRawJSON.isEmpty {
                dict["summaryRawJSON"] = summaryRawJSON
            }
            if let sessionOrdinal = session.sessionOrdinal {
                dict["sessionOrdinal"] = sessionOrdinal
            }
            if let primaryFocus = session.primaryFocus, !primaryFocus.isEmpty {
                dict["primaryFocus"] = primaryFocus
            }
            if let relatedThemes = session.relatedThemes, !relatedThemes.isEmpty {
                dict["relatedThemes"] = relatedThemes
            }
            if let moodStartIntensity = session.moodStartIntensity {
                dict["moodStartIntensity"] = moodStartIntensity
            }
            if let moodEndIntensity = session.moodEndIntensity {
                dict["moodEndIntensity"] = moodEndIntensity
            }
            if let startPhysical = session.moodStartPhysicalSymptoms, !startPhysical.isEmpty {
                dict["moodStartPhysicalSymptoms"] = startPhysical
            }
            if let endPhysical = session.moodEndPhysicalSymptoms, !endPhysical.isEmpty {
                dict["moodEndPhysicalSymptoms"] = endPhysical
            }
            if let patternRecognized = session.patternRecognized, !patternRecognized.isEmpty {
                dict["patternRecognized"] = patternRecognized
            }
            if let recurringTopicsSnapshot = session.recurringTopicsSnapshot,
                !recurringTopicsSnapshot.isEmpty
            {
                dict["recurringTopicsSnapshot"] = recurringTopicsSnapshot
            }
            if let recurringTopicsTrend = session.recurringTopicsTrend, !recurringTopicsTrend.isEmpty {
                dict["recurringTopicsTrend"] = recurringTopicsTrend
            }
            if let attempted = session.copingStrategiesAttempted, !attempted.isEmpty {
                dict["copingStrategiesAttempted"] = attempted
            }
            if let worked = session.copingStrategiesWorked, !worked.isEmpty {
                dict["copingStrategiesWorked"] = worked
            }
            if let didntWork = session.copingStrategiesDidntWork, !didntWork.isEmpty {
                dict["copingStrategiesDidntWork"] = didntWork
            }
            if let previousAssigned = session.previousHomeworkAssigned, !previousAssigned.isEmpty {
                dict["previousHomeworkAssigned"] = previousAssigned
            }
            if let previousCompletion = session.previousHomeworkCompletion, !previousCompletion.isEmpty
            {
                dict["previousHomeworkCompletion"] = previousCompletion
            }
            if let previousReflection = session.previousHomeworkReflection, !previousReflection.isEmpty {
                dict["previousHomeworkReflection"] = previousReflection
            }
            if let goalProgress = session.therapyGoalProgress, !goalProgress.isEmpty {
                dict["therapyGoalProgress"] = goalProgress
            }
            if let actionItemsForUser = session.actionItemsForUser, !actionItemsForUser.isEmpty {
                dict["actionItemsForUser"] = actionItemsForUser
            }
            if let people = session.continuityPeopleMentioned, !people.isEmpty {
                dict["continuityPeopleMentioned"] = people
            }
            if let events = session.continuityUpcomingEvents, !events.isEmpty {
                dict["continuityUpcomingEvents"] = events
            }
            if let factors = session.continuityEnvironmentalFactors, !factors.isEmpty {
                dict["continuityEnvironmentalFactors"] = factors
            }
            if let risk = session.crisisRiskDetectedByModel {
                dict["crisisRiskDetectedByModel"] = risk
            }
            if let crisisNotes = session.crisisNotes, !crisisNotes.isEmpty {
                dict["crisisNotes"] = crisisNotes
            }
            if let protectiveFactors = session.protectiveFactors, !protectiveFactors.isEmpty {
                dict["protectiveFactors"] = protectiveFactors
            }
            if let safetyRecommendation = session.safetyRecommendation, !safetyRecommendation.isEmpty {
                dict["safetyRecommendation"] = safetyRecommendation
            }
            if let dominantEmotions = session.dominantEmotions, !dominantEmotions.isEmpty {
                dict["dominantEmotions"] = dominantEmotions
            }
            if let primaryCopingStyle = session.primaryCopingStyle, !primaryCopingStyle.isEmpty {
                dict["primaryCopingStyle"] = primaryCopingStyle
            }
            if let effectiveness = session.sessionEffectivenessSelfRating {
                dict["sessionEffectivenessSelfRating"] = effectiveness
            }
            return dict
        }

        var root: [String: Any] = [
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "sessions": sessionDicts,
        ]

        // Include learned profile if it has content
        if let profile, profile.hasContent {
            var profileDict: [String: Any] = [
                "sessionsAnalysed": profile.sessionsAnalysed,
                "lastUpdated": ISO8601DateFormatter().string(from: profile.lastUpdated),
            ]
            if !profile.recurringTopics.isEmpty {
                profileDict["recurringTopics"] = profile.recurringTopics
            }
            if !profile.preferredCopingStrategies.isEmpty {
                profileDict["preferredCopingStrategies"] = profile.preferredCopingStrategies
            }
            if !profile.emotionalPatterns.isEmpty {
                profileDict["emotionalPatterns"] = profile.emotionalPatterns
            }
            if !profile.communicationNotes.isEmpty {
                profileDict["communicationNotes"] = profile.communicationNotes
            }
            if !profile.knownTriggers.isEmpty {
                profileDict["knownTriggers"] = profile.knownTriggers
            }
            if !profile.moodBaseline.isEmpty {
                profileDict["moodBaseline"] = profile.moodBaseline
            }
            root["learnedProfile"] = profileDict
        }

        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(
                withJSONObject: root, options: [.prettyPrinted, .sortedKeys])
        } catch {
            print("[DataExporter] Failed to encode export JSON: \(error.localizedDescription)")
            return nil
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "Anchor_Export_\(UUID().uuidString).json"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try jsonData.write(to: fileURL)
            return fileURL
        } catch {
            print("[DataExporter] Failed to write export file: \(error.localizedDescription)")
            return nil
        }
    }
}
