//
//  Session.swift
//  Anchor
//
//  Created for Anchor - AI-Powered Emotional Support
//

import Combine
import Foundation
import SwiftData

/// Represents a conversation session with the AI emotional support system
@Model
final class Session {
    /// Unique identifier for the session
    var id: UUID

    /// When the session was created
    var timestamp: Date

    /// Duration of the session in seconds
    var duration: TimeInterval

    /// Brief summary of the session (not full transcript for privacy)
    var summary: String

    /// User's mood at the start of session (1-5 scale)
    var moodBefore: Int?

    /// User's mood at the end of session (1-5 scale)
    var moodAfter: Int?

    /// Tags or categories for the session
    var tags: [String]

    /// Mood triggers selected after the session
    var moodTriggers: [String]? = []

    /// Observed mood summary from the post-session notes
    var observedMood: String?

    /// Coping strategies mentioned in the session notes
    var copingStrategies: [String]? = []

    /// Suggested follow-up from the session notes
    var suggestedFollowUp: String?

    /// Rich narrative summary (2-3 sentences, "you" language)
    var narrativeSummary: String?

    /// Starting mood description (e.g., "Anxious (8/10), tense")
    var moodStartDescription: String?

    /// Ending mood description (e.g., "Anxious but grounded (5/10)")
    var moodEndDescription: String?

    /// What shifted during the session
    var moodShiftDescription: String?

    /// Core insight the user had during the session
    var keyInsight: String?

    /// Direct quotes from the user
    var userQuotes: [String]?

    /// Coping strategies with effectiveness markers
    var copingStrategiesExplored: [String]?

    /// Action items / questions for the therapist
    var actionItemsForTherapist: [String]?

    /// Recurring pattern alert (topic appeared 3+ times across sessions)
    var recurringPatternAlert: String?

    /// Summary schema version used to generate notes (1 = legacy flat, 2 = nested clinical schema).
    var summarySchemaVersion: Int?

    /// Raw summary JSON payload returned by the model for forward compatibility/debugging.
    var summaryRawJSON: String?

    /// Session number used by the summarizer prompt context.
    var sessionOrdinal: Int?

    /// Primary focus for the session (v2 notes).
    var primaryFocus: String?

    /// Related themes extracted from the session (v2 notes).
    var relatedThemes: [String]? = []

    /// Mood intensity at session start (1-10 when provided by model).
    var moodStartIntensity: Int?

    /// Mood intensity at session end (1-10 when provided by model).
    var moodEndIntensity: Int?

    /// Physical symptoms reported at session start.
    var moodStartPhysicalSymptoms: [String]? = []

    /// Physical symptoms reported at session end.
    var moodEndPhysicalSymptoms: [String]? = []

    /// Pattern recognized by the user during the session.
    var patternRecognized: String?

    /// Snapshot of recurring topics at summary time.
    var recurringTopicsSnapshot: [String]? = []

    /// Trend label for recurring topics (e.g., Increasing/Stable/Decreasing).
    var recurringTopicsTrend: String?

    /// Normalized attempted coping strategies for the session.
    var copingStrategiesAttempted: [String]? = []

    /// Strategies marked as working.
    var copingStrategiesWorked: [String]? = []

    /// Strategies marked as not working.
    var copingStrategiesDidntWork: [String]? = []

    /// Previous homework carried into this session.
    var previousHomeworkAssigned: String?

    /// Completion status of previous homework.
    var previousHomeworkCompletion: String?

    /// User reflection on previous homework.
    var previousHomeworkReflection: String?

    /// Progress notes for therapy goals.
    var therapyGoalProgress: [String]? = []

    /// Action items intended for the user.
    var actionItemsForUser: [String]? = []

    /// People mentioned for continuity context.
    var continuityPeopleMentioned: [String]? = []

    /// Upcoming events mentioned for continuity context.
    var continuityUpcomingEvents: [String]? = []

    /// Environmental/context factors that may affect wellbeing.
    var continuityEnvironmentalFactors: [String]? = []

    /// Safety risk flag produced by the model.
    var crisisRiskDetectedByModel: Bool?

    /// Safety risk details produced by the model.
    var crisisNotes: String?

    /// Protective factors identified in the session.
    var protectiveFactors: [String]? = []

    /// Safety recommendation text from model output.
    var safetyRecommendation: String?

    /// Dominant emotions identified in the session.
    var dominantEmotions: [String]? = []

    /// Dominant coping style observed in the session.
    var primaryCopingStyle: String?

    /// User-reported session effectiveness (1-10).
    var sessionEffectivenessSelfRating: Int?

    /// Voice stress score (0–100) derived from tone analysis
    var voiceStressScore: Double?

    /// Session focus/playlist selection
    var sessionFocus: String?

    /// Whether the session was completed or interrupted
    var completed: Bool

    /// Crisis flag - if crisis keywords were detected
    var crisisDetected: Bool

    /// Actionable homework or exercise for the user to practice before next session
    var homework: String?

    /// Structured homework items parsed from the generated homework text.
    var homeworkItems: [String]? = []

    /// Homework items reported as completed by the user.
    var completedHomeworkItems: [String]? = []

    /// Whether the user has marked the homework as done
    var homeworkCompleted: Bool = false

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        duration: TimeInterval = 0,
        summary: String = "",
        moodBefore: Int? = nil,
        moodAfter: Int? = nil,
        tags: [String] = [],
        moodTriggers: [String]? = [],
        observedMood: String? = nil,
        copingStrategies: [String]? = [],
        suggestedFollowUp: String? = nil,
        narrativeSummary: String? = nil,
        moodStartDescription: String? = nil,
        moodEndDescription: String? = nil,
        moodShiftDescription: String? = nil,
        keyInsight: String? = nil,
        userQuotes: [String]? = nil,
        copingStrategiesExplored: [String]? = nil,
        actionItemsForTherapist: [String]? = nil,
        recurringPatternAlert: String? = nil,
        summarySchemaVersion: Int? = nil,
        summaryRawJSON: String? = nil,
        sessionOrdinal: Int? = nil,
        primaryFocus: String? = nil,
        relatedThemes: [String]? = [],
        moodStartIntensity: Int? = nil,
        moodEndIntensity: Int? = nil,
        moodStartPhysicalSymptoms: [String]? = [],
        moodEndPhysicalSymptoms: [String]? = [],
        patternRecognized: String? = nil,
        recurringTopicsSnapshot: [String]? = [],
        recurringTopicsTrend: String? = nil,
        copingStrategiesAttempted: [String]? = [],
        copingStrategiesWorked: [String]? = [],
        copingStrategiesDidntWork: [String]? = [],
        previousHomeworkAssigned: String? = nil,
        previousHomeworkCompletion: String? = nil,
        previousHomeworkReflection: String? = nil,
        therapyGoalProgress: [String]? = [],
        actionItemsForUser: [String]? = [],
        continuityPeopleMentioned: [String]? = [],
        continuityUpcomingEvents: [String]? = [],
        continuityEnvironmentalFactors: [String]? = [],
        crisisRiskDetectedByModel: Bool? = nil,
        crisisNotes: String? = nil,
        protectiveFactors: [String]? = [],
        safetyRecommendation: String? = nil,
        dominantEmotions: [String]? = [],
        primaryCopingStyle: String? = nil,
        sessionEffectivenessSelfRating: Int? = nil,
        completed: Bool = false,
        crisisDetected: Bool = false,
        voiceStressScore: Double? = nil,
        sessionFocus: String? = nil,
        homework: String? = nil,
        homeworkItems: [String]? = [],
        completedHomeworkItems: [String]? = [],
        homeworkCompleted: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.duration = duration
        self.summary = summary
        self.moodBefore = moodBefore
        self.moodAfter = moodAfter
        self.tags = tags
        self.moodTriggers = moodTriggers
        self.observedMood = observedMood
        self.copingStrategies = copingStrategies
        self.suggestedFollowUp = suggestedFollowUp
        self.narrativeSummary = narrativeSummary
        self.moodStartDescription = moodStartDescription
        self.moodEndDescription = moodEndDescription
        self.moodShiftDescription = moodShiftDescription
        self.keyInsight = keyInsight
        self.userQuotes = userQuotes
        self.copingStrategiesExplored = copingStrategiesExplored
        self.actionItemsForTherapist = actionItemsForTherapist
        self.recurringPatternAlert = recurringPatternAlert
        self.summarySchemaVersion = summarySchemaVersion
        self.summaryRawJSON = summaryRawJSON
        self.sessionOrdinal = sessionOrdinal
        self.primaryFocus = primaryFocus
        self.relatedThemes = relatedThemes
        self.moodStartIntensity = moodStartIntensity
        self.moodEndIntensity = moodEndIntensity
        self.moodStartPhysicalSymptoms = moodStartPhysicalSymptoms
        self.moodEndPhysicalSymptoms = moodEndPhysicalSymptoms
        self.patternRecognized = patternRecognized
        self.recurringTopicsSnapshot = recurringTopicsSnapshot
        self.recurringTopicsTrend = recurringTopicsTrend
        self.copingStrategiesAttempted = copingStrategiesAttempted
        self.copingStrategiesWorked = copingStrategiesWorked
        self.copingStrategiesDidntWork = copingStrategiesDidntWork
        self.previousHomeworkAssigned = previousHomeworkAssigned
        self.previousHomeworkCompletion = previousHomeworkCompletion
        self.previousHomeworkReflection = previousHomeworkReflection
        self.therapyGoalProgress = therapyGoalProgress
        self.actionItemsForUser = actionItemsForUser
        self.continuityPeopleMentioned = continuityPeopleMentioned
        self.continuityUpcomingEvents = continuityUpcomingEvents
        self.continuityEnvironmentalFactors = continuityEnvironmentalFactors
        self.crisisRiskDetectedByModel = crisisRiskDetectedByModel
        self.crisisNotes = crisisNotes
        self.protectiveFactors = protectiveFactors
        self.safetyRecommendation = safetyRecommendation
        self.dominantEmotions = dominantEmotions
        self.primaryCopingStyle = primaryCopingStyle
        self.sessionEffectivenessSelfRating = sessionEffectivenessSelfRating
        self.completed = completed
        self.crisisDetected = crisisDetected
        self.voiceStressScore = voiceStressScore
        self.sessionFocus = sessionFocus
        self.homework = homework
        self.homeworkItems = homeworkItems
        self.completedHomeworkItems = completedHomeworkItems
        self.homeworkCompleted = homeworkCompleted
    }

    /// Formatted duration string (localized, e.g., "15m 30s")
    var formattedDuration: String {
        let formatter =
            duration >= 60 ? Self.durationFormatterMinutesSeconds : Self.durationFormatterSeconds
        return formatter.string(from: duration) ?? ""
    }

    private static let durationFormatterMinutesSeconds: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    private static let durationFormatterSeconds: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.second]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
}

enum MoodTriggerTag: String, CaseIterable, Identifiable {
    case work = "Work"
    case relationships = "Relationships"
    case health = "Health"
    case sleep = "Sleep"
    case finances = "Finances"
    case weather = "Weather"
    case family = "Family"
    case social = "Social"
    case selfCare = "Self-care"
    case school = "School"

    var id: String { rawValue }

    var label: String {
        String(localized: .init(rawValue))
    }

    static func label(for rawValue: String) -> String {
        MoodTriggerTag(rawValue: rawValue)?.label ?? rawValue
    }
}
