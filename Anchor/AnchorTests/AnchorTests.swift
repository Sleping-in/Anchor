//
//  AnchorTests.swift
//  AnchorTests
//
//  Created by Mohammad Elhaj on 07/02/2026.
//

import Testing
import Foundation
import SwiftData
@testable import Anchor

// MARK: - Session Model Tests

struct SessionModelTests {

    @Test func sessionModelCreation() async throws {
        let session = Session(
            timestamp: Date(),
            duration: 300,
            summary: "Test session",
            completed: true
        )

        #expect(session.duration == 300)
        #expect(session.completed == true)
        #expect(session.summary == "Test session")
        #expect(session.crisisDetected == false)
    }

    @Test func sessionDurationFormattingMinutesAndSeconds() async throws {
        let session = Session(duration: 95) // 1 min 35 sec
        #expect(session.formattedDuration == expectedDurationString(95))
    }

    @Test func sessionDurationFormattingSecondsOnly() async throws {
        let session = Session(duration: 45)
        #expect(session.formattedDuration == expectedDurationString(45))
    }

    @Test func sessionDurationFormattingZero() async throws {
        let session = Session(duration: 0)
        #expect(session.formattedDuration == expectedDurationString(0))
    }

    @Test func sessionDurationFormattingExactMinute() async throws {
        let session = Session(duration: 120)
        #expect(session.formattedDuration == expectedDurationString(120))
    }

    @Test func sessionDefaultValues() async throws {
        let session = Session()
        #expect(session.duration == 0)
        #expect(session.summary == "")
        #expect(session.tags.isEmpty)
        #expect(session.completed == false)
        #expect(session.crisisDetected == false)
        #expect(session.moodBefore == nil)
        #expect(session.moodAfter == nil)
    }

    @Test func sessionWithMoodValues() async throws {
        let session = Session(moodBefore: 2, moodAfter: 4)
        #expect(session.moodBefore == 2)
        #expect(session.moodAfter == 4)
    }

    @Test func sessionWithTags() async throws {
        let session = Session(tags: ["anxiety", "work", "sleep"])
        #expect(session.tags.count == 3)
        #expect(session.tags.contains("anxiety"))
    }
}

private func expectedDurationString(_ duration: TimeInterval) -> String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = duration >= 60 ? [.minute, .second] : [.second]
    formatter.unitsStyle = .abbreviated
    formatter.zeroFormattingBehavior = .pad
    return formatter.string(from: duration) ?? ""
}

// MARK: - UserSettings Tests

struct UserSettingsTests {

    @Test func userSettingsDefaults() async throws {
        let settings = UserSettings()
        #expect(settings.hasCompletedOnboarding == false)
        #expect(settings.hasSeenSafetyDisclaimer == false)
        #expect(settings.voiceSpeed == 1.0)
        #expect(settings.isSubscribed == false)
        #expect(settings.isInTrialPeriod == false)
        #expect(settings.totalSessions == 0)
        #expect(settings.userName == "")
        #expect(settings.communicationStyle == "gentle")
        #expect(settings.primaryConcerns.isEmpty)
        #expect(settings.currentStreak == 0)
    }

    @Test func trialPeriodActive() async throws {
        let settings = UserSettings(
            isInTrialPeriod: true,
            trialStartDate: Date()
        )

        #expect(settings.isInTrialPeriod == true)
        #expect(settings.hasActiveAccess == true)

        let days = settings.trialDaysRemaining
        #expect(days != nil)
        #expect(days! >= 0)
        #expect(days! <= 7)
    }

    @Test func trialPeriodExpired() async throws {
        let expired = Calendar.current.date(byAdding: .day, value: -10, to: Date())
        let settings = UserSettings(
            isInTrialPeriod: true,
            trialStartDate: expired
        )

        #expect(settings.hasActiveAccess == false)
        #expect(settings.trialDaysRemaining == 0)
    }

    @Test func subscriptionActive() async throws {
        let future = Calendar.current.date(byAdding: .month, value: 1, to: Date())
        let settings = UserSettings(
            isSubscribed: true,
            subscriptionExpiryDate: future
        )

        #expect(settings.hasActiveAccess == true)
        #expect(settings.hasUnlimitedAccess == true)
    }

    @Test func subscriptionExpired() async throws {
        let past = Calendar.current.date(byAdding: .month, value: -1, to: Date())
        let settings = UserSettings(
            isSubscribed: true,
            subscriptionExpiryDate: past
        )

        #expect(settings.hasActiveAccess == false)
    }

    @Test func noTrialNoSubscription() async throws {
        let settings = UserSettings()
        #expect(settings.hasActiveAccess == false)
        #expect(settings.hasUnlimitedAccess == false)
    }

    // MARK: Free Tier Usage

    @Test func freeDailyLimitIs600Seconds() async throws {
        #expect(UserSettings.freeDailyLimitSeconds == 600)
    }

    @Test func remainingFreeSecondsFullWhenUnused() async throws {
        let settings = UserSettings()
        let remaining = settings.remainingFreeSeconds(now: Date())
        #expect(remaining == 600)
    }

    @Test func remainingFreeSecondsDecreasesWithUsage() async throws {
        let now = Date()
        let settings = UserSettings(dailyUsageSeconds: 0, dailyUsageDate: now)
        settings.recordUsage(seconds: 120, now: now)
        let remaining = settings.remainingFreeSeconds(now: now)
        #expect(remaining == 480)
    }

    @Test func remainingFreeSecondsNeverNegative() async throws {
        let now = Date()
        let settings = UserSettings(dailyUsageSeconds: 0, dailyUsageDate: now)
        settings.recordUsage(seconds: 1000, now: now)
        #expect(settings.remainingFreeSeconds(now: now) == 0)
    }

    @Test func usageResetsOnNewDay() async throws {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let settings = UserSettings(dailyUsageSeconds: 500, dailyUsageDate: yesterday)
        let remaining = settings.remainingFreeSeconds(now: Date())
        #expect(remaining == 600) // reset
    }

    @Test func recordUsageIgnoresZeroOrNegative() async throws {
        let now = Date()
        let settings = UserSettings(dailyUsageSeconds: 0, dailyUsageDate: now)
        settings.recordUsage(seconds: 0, now: now)
        settings.recordUsage(seconds: -10, now: now)
        #expect(settings.remainingFreeSeconds(now: now) == 600)
    }

    // MARK: Streak Tracking

    @Test func firstSessionStartsStreakAtOne() async throws {
        let settings = UserSettings()
        settings.recordSessionForStreak(now: Date())
        #expect(settings.currentStreak == 1)
    }

    @Test func sameDaySessionDoesNotIncrementStreak() async throws {
        let now = Date()
        let settings = UserSettings()
        settings.recordSessionForStreak(now: now)
        settings.recordSessionForStreak(now: now) // same day
        #expect(settings.currentStreak == 1)
    }

    @Test func consecutiveDayIncrementsStreak() async throws {
        let cal = Calendar.current
        let yesterday = cal.date(byAdding: .day, value: -1, to: Date())!
        let settings = UserSettings()
        settings.recordSessionForStreak(now: yesterday)
        #expect(settings.currentStreak == 1)

        settings.recordSessionForStreak(now: Date())
        #expect(settings.currentStreak == 2)
    }

    @Test func missedDayResetsStreak() async throws {
        let cal = Calendar.current
        let twoDaysAgo = cal.date(byAdding: .day, value: -2, to: Date())!
        let settings = UserSettings()
        settings.recordSessionForStreak(now: twoDaysAgo)
        #expect(settings.currentStreak == 1)

        settings.recordSessionForStreak(now: Date())
        #expect(settings.currentStreak == 1) // reset, not 2
    }

    @Test func longStreakBuildsCorrectly() async throws {
        let cal = Calendar.current
        let settings = UserSettings()
        for daysAgo in stride(from: 4, through: 0, by: -1) {
            let date = cal.date(byAdding: .day, value: -daysAgo, to: Date())!
            settings.recordSessionForStreak(now: date)
        }
        #expect(settings.currentStreak == 5)
    }
}

// MARK: - Crisis Keyword Scanner Tests

struct CrisisKeywordScannerTests {

    @Test func detectsExactKeyword() async throws {
        #expect(CrisisKeywordScanner.containsCrisisLanguage("I want to kill myself"))
    }

    @Test func caseInsensitive() async throws {
        #expect(CrisisKeywordScanner.containsCrisisLanguage("I WANT TO DIE"))
    }

    @Test func detectsSuicide() async throws {
        #expect(CrisisKeywordScanner.containsCrisisLanguage("thinking about suicide"))
    }

    @Test func detectsSelfHarmVariants() async throws {
        #expect(CrisisKeywordScanner.containsCrisisLanguage("I might self-harm"))
        #expect(CrisisKeywordScanner.containsCrisisLanguage("I want to self harm"))
        #expect(CrisisKeywordScanner.containsCrisisLanguage("selfharm"))
    }

    @Test func detectsOverdose() async throws {
        #expect(CrisisKeywordScanner.containsCrisisLanguage("I'm going to overdose"))
    }

    @Test func detectsEndItAll() async throws {
        #expect(CrisisKeywordScanner.containsCrisisLanguage("I want to end it all"))
    }

    @Test func detectsBetterOffDead() async throws {
        #expect(CrisisKeywordScanner.containsCrisisLanguage("everyone would be better off dead"))
    }

    @Test func detectsCantGoOn() async throws {
        #expect(CrisisKeywordScanner.containsCrisisLanguage("I can't go on anymore"))
        #expect(CrisisKeywordScanner.containsCrisisLanguage("i cant go on"))
    }

    @Test func safeTextReturnsNoCrisis() async throws {
        #expect(!CrisisKeywordScanner.containsCrisisLanguage("I had a good day today"))
    }

    @Test func emptyStringReturnsNoCrisis() async throws {
        #expect(!CrisisKeywordScanner.containsCrisisLanguage(""))
    }

    @Test func normalSadnessIsNotCrisis() async throws {
        #expect(!CrisisKeywordScanner.containsCrisisLanguage("I feel sad and lonely"))
    }

    @Test func anxietyIsNotCrisis() async throws {
        #expect(!CrisisKeywordScanner.containsCrisisLanguage("I'm anxious about my job interview"))
    }

    @Test func embeddedInSentence() async throws {
        #expect(CrisisKeywordScanner.containsCrisisLanguage("sometimes I just wish i was dead you know"))
    }

    @Test func allKeywordsAreDetected() async throws {
        // Verify every single keyword triggers detection
        for keyword in CrisisKeywordScanner.keywords {
            #expect(
                CrisisKeywordScanner.containsCrisisLanguage("I am \(keyword) today"),
                "Failed to detect keyword: \(keyword)"
            )
        }
    }
}

// MARK: - UserProfile Tests

struct UserProfileTests {

    @Test func emptyProfileHasNoContent() async throws {
        let profile = UserProfile()
        #expect(profile.hasContent == false)
        #expect(profile.promptContext == "")
    }

    @Test func profileWithTopicsHasContent() async throws {
        let profile = UserProfile(recurringTopics: ["anxiety", "work stress"])
        #expect(profile.hasContent == true)
    }

    @Test func profileWithMoodBaselineHasContent() async throws {
        let profile = UserProfile(moodBaseline: "generally anxious")
        #expect(profile.hasContent == true)
    }

    @Test func promptContextIncludesTopics() async throws {
        let profile = UserProfile(recurringTopics: ["sleep", "relationships"])
        let ctx = profile.promptContext
        #expect(ctx.contains("Recurring topics"))
        #expect(ctx.contains("sleep"))
        #expect(ctx.contains("relationships"))
    }

    @Test func promptContextIncludesTriggers() async throws {
        let profile = UserProfile(knownTriggers: ["deadlines", "crowds"])
        let ctx = profile.promptContext
        #expect(ctx.contains("Known triggers"))
        #expect(ctx.contains("deadlines"))
    }

    @Test func promptContextIncludesStrategies() async throws {
        let profile = UserProfile(preferredCopingStrategies: ["deep breathing", "journaling"])
        let ctx = profile.promptContext
        #expect(ctx.contains("Coping strategies"))
        #expect(ctx.contains("deep breathing"))
    }

    @Test func promptContextIncludesMoodBaseline() async throws {
        let profile = UserProfile(moodBaseline: "low energy")
        let ctx = profile.promptContext
        #expect(ctx.contains("mood baseline"))
        #expect(ctx.contains("low energy"))
    }

    @Test func promptContextPrefixLimits() async throws {
        // Topics capped at 8 in promptContext
        let manyTopics = (1...15).map { "topic\($0)" }
        let profile = UserProfile(recurringTopics: manyTopics)
        let ctx = profile.promptContext
        #expect(ctx.contains("topic8"))
        #expect(!ctx.contains("topic9"))
    }

    @Test func promptContextCombinesMultipleSections() async throws {
        let profile = UserProfile(
            recurringTopics: ["anxiety"],
            preferredCopingStrategies: ["breathing"],
            emotionalPatterns: ["mood dips at night"],
            communicationNotes: ["prefers validation"],
            knownTriggers: ["conflict"],
            moodBaseline: "moderate"
        )
        let ctx = profile.promptContext
        #expect(ctx.contains("Recurring topics"))
        #expect(ctx.contains("Known triggers"))
        #expect(ctx.contains("Coping strategies"))
        #expect(ctx.contains("emotional patterns"))
        #expect(ctx.contains("Communication preferences"))
        #expect(ctx.contains("mood baseline"))
    }
}

// MARK: - FlaggedResponse Tests

struct FlaggedResponseTests {

    @Test func flaggedResponseCreation() async throws {
        let flag = FlaggedResponse(
            aiMessage: "Some harmful text",
            userMessageBefore: "My question",
            reason: "Harmful or dangerous",
            sessionId: UUID()
        )

        #expect(flag.aiMessage == "Some harmful text")
        #expect(flag.userMessageBefore == "My question")
        #expect(flag.reason == "Harmful or dangerous")
        #expect(flag.reviewed == false)
        #expect(flag.sessionId != nil)
    }

    @Test func flaggedResponseDefaults() async throws {
        let flag = FlaggedResponse(aiMessage: "test")
        #expect(flag.userMessageBefore == "")
        #expect(flag.reason == "")
        #expect(flag.sessionId == nil)
        #expect(flag.reviewed == false)
    }

    @Test func flaggedResponseHasUniqueId() async throws {
        let a = FlaggedResponse(aiMessage: "a")
        let b = FlaggedResponse(aiMessage: "b")
        #expect(a.id != b.id)
    }
}

// MARK: - AnchorSystemPrompt Tests

struct AnchorSystemPromptTests {

    @Test func basePromptContainsRoleSection() async throws {
        #expect(AnchorSystemPrompt.text.contains("ROLE & IDENTITY"))
        #expect(AnchorSystemPrompt.text.contains("Anchor"))
    }

    @Test func basePromptContainsCrisisProtocol() async throws {
        #expect(AnchorSystemPrompt.text.contains("CRISIS PROTOCOL"))
        #expect(AnchorSystemPrompt.text.contains("988"))
    }

    @Test func basePromptContainsLimitations() async throws {
        #expect(AnchorSystemPrompt.text.contains("NEVER diagnose"))
        #expect(AnchorSystemPrompt.text.contains("NEVER recommend or discuss medications"))
    }

    @Test func basePromptContainsPlaceholder() async throws {
        #expect(AnchorSystemPrompt.text.contains("[User profile summary will be inserted here]"))
    }

    @Test func personalisedPromptInjectsUserName() async throws {
        let settings = UserSettings(userName: "Alex")
        let result = AnchorSystemPrompt.personalised(sessions: [], settings: settings)
        #expect(result.contains("Alex"))
        #expect(!result.contains("[User profile summary will be inserted here]"))
    }

    @Test func personalisedPromptInjectsCommunicationStyle() async throws {
        let settings = UserSettings(communicationStyle: "listener")
        let result = AnchorSystemPrompt.personalised(sessions: [], settings: settings)
        #expect(result.contains("listening approach"))
    }

    @Test func personalisedPromptInjectsDirectStyle() async throws {
        let settings = UserSettings(communicationStyle: "direct")
        let result = AnchorSystemPrompt.personalised(sessions: [], settings: settings)
        #expect(result.contains("direct communication"))
    }

    @Test func personalisedPromptInjectsConcerns() async throws {
        let settings = UserSettings(primaryConcerns: ["anxiety", "sleep"])
        let result = AnchorSystemPrompt.personalised(sessions: [], settings: settings)
        #expect(result.contains("anxiety"))
        #expect(result.contains("sleep"))
    }

    @Test func personalisedPromptShowsFirstSession() async throws {
        let settings = UserSettings(totalSessions: 0)
        let result = AnchorSystemPrompt.personalised(sessions: [], settings: settings)
        #expect(result.contains("first session"))
    }

    @Test func personalisedPromptShowsSessionCount() async throws {
        let settings = UserSettings(totalSessions: 10)
        let result = AnchorSystemPrompt.personalised(sessions: [], settings: settings)
        #expect(result.contains("10 previous session"))
    }

    @Test func personalisedPromptIncludesMoodHistory() async throws {
        let session = Session(moodBefore: 2, moodAfter: 4)
        let settings = UserSettings()
        let result = AnchorSystemPrompt.personalised(sessions: [session], settings: settings)
        #expect(result.contains("mood"))
        #expect(result.contains("2/5"))
        #expect(result.contains("4/5"))
    }

    @Test func personalisedPromptIncludesSummaries() async throws {
        let session = Session(summary: "Discussed work stress and coping")
        let settings = UserSettings()
        let result = AnchorSystemPrompt.personalised(sessions: [session], settings: settings)
        #expect(result.contains("work stress"))
    }

    @Test func personalisedPromptIncludesCrisisHistory() async throws {
        let session = Session(crisisDetected: true)
        let settings = UserSettings()
        let result = AnchorSystemPrompt.personalised(sessions: [session], settings: settings)
        #expect(result.contains("Crisis keywords were detected"))
    }

    @Test func personalisedPromptIncludesLearnedProfile() async throws {
        let profile = UserProfile(
            recurringTopics: ["burnout"],
            preferredCopingStrategies: ["meditation"],
            sessionsAnalysed: 5
        )
        let settings = UserSettings()
        let result = AnchorSystemPrompt.personalised(sessions: [], settings: settings, profile: profile)
        #expect(result.contains("LEARNED USER PROFILE"))
        #expect(result.contains("5 session"))
        #expect(result.contains("burnout"))
        #expect(result.contains("meditation"))
    }

    @Test func personalisedPromptReturnsBaseWhenNoContext() async throws {
        // Gentle style is the default and is skipped — with 0 sessions, it says "first session"
        // so context won't be fully empty. Test with nil settings.
        let result = AnchorSystemPrompt.personalised(sessions: [], settings: nil)
        // With nil settings and no sessions, contextBlock has "first session" line
        #expect(result.contains("ROLE & IDENTITY"))
    }
}

// MARK: - DataExporter Tests

struct DataExporterTests {

    @Test func exportCreatesValidJSON() async throws {
        let session = Session(
            duration: 120,
            summary: "Test export",
            moodBefore: 3,
            moodAfter: 4,
            tags: ["test"],
            completed: true
        )

        guard let url = DataExporter.exportAll(sessions: [session], profile: nil) else {
            #expect(Bool(false), "Export returned nil")
            return
        }

        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["exportDate"] != nil)
        let sessions = json["sessions"] as! [[String: Any]]
        #expect(sessions.count == 1)

        let exported = sessions[0]
        #expect(exported["duration"] as! Double == 120)
        #expect(exported["summary"] as! String == "Test export")
        #expect(exported["completed"] as! Bool == true)
        #expect(exported["moodBefore"] as! Int == 3)
        #expect(exported["moodAfter"] as! Int == 4)

        try? FileManager.default.removeItem(at: url)
    }

    @Test func exportOmitsNilMoods() async throws {
        let session = Session(summary: "no mood")

        guard let url = DataExporter.exportAll(sessions: [session], profile: nil) else {
            #expect(Bool(false), "Export returned nil")
            return
        }

        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let sessions = json["sessions"] as! [[String: Any]]
        let exported = sessions[0]
        #expect(exported["moodBefore"] == nil)
        #expect(exported["moodAfter"] == nil)

        try? FileManager.default.removeItem(at: url)
    }

    @Test func exportIncludesProfileWhenPresent() async throws {
        let profile = UserProfile(
            recurringTopics: ["work"],
            preferredCopingStrategies: ["breathing"],
            moodBaseline: "moderate",
            sessionsAnalysed: 3
        )

        guard let url = DataExporter.exportAll(sessions: [], profile: profile) else {
            #expect(Bool(false), "Export returned nil")
            return
        }

        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let profileDict = json["learnedProfile"] as! [String: Any]

        #expect(profileDict["sessionsAnalysed"] as! Int == 3)
        #expect((profileDict["recurringTopics"] as! [String]).contains("work"))
        #expect(profileDict["moodBaseline"] as! String == "moderate")

        try? FileManager.default.removeItem(at: url)
    }

    @Test func exportExcludesProfileWhenEmpty() async throws {
        let profile = UserProfile() // empty — hasContent == false

        guard let url = DataExporter.exportAll(sessions: [], profile: profile) else {
            #expect(Bool(false), "Export returned nil")
            return
        }

        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(json["learnedProfile"] == nil)

        try? FileManager.default.removeItem(at: url)
    }

    @Test func exportMultipleSessions() async throws {
        let sessions = (1...5).map { Session(summary: "Session \($0)") }

        guard let url = DataExporter.exportAll(sessions: sessions, profile: nil) else {
            #expect(Bool(false), "Export returned nil")
            return
        }

        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let exported = json["sessions"] as! [[String: Any]]
        #expect(exported.count == 5)

        try? FileManager.default.removeItem(at: url)
    }

    @Test func exportFileIsInTempDirectory() async throws {
        guard let url = DataExporter.exportAll(sessions: [], profile: nil) else {
            #expect(Bool(false), "Export returned nil")
            return
        }

        #expect(url.path().contains("tmp") || url.path().contains("Temp"))
        #expect(url.lastPathComponent.hasPrefix("Anchor_Export_"))
        #expect(url.pathExtension == "json")

        try? FileManager.default.removeItem(at: url)
    }
}
