//
//  ProfileBuilderTests.swift
//  AnchorTests
//
//  Tests for aggregating session data into UserProfile.
//

import SwiftData
import XCTest

@testable import Anchor

@MainActor
final class ProfileBuilderTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var profile: UserProfile!

    override func setUpWithError() throws {
        let schema = Schema([UserProfile.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: config)
        context = container.mainContext

        profile = UserProfile()
        context.insert(profile)
    }

    func testIntegrate_AddsNewTopics() {
        let notes = SessionSummarizer.SessionNotes(
            mainTopics: ["Anxiety", "Work"],
            observedMood: "Tense",
            copingStrategies: [],
            keyInsights: "",
            suggestedFollowUp: "",
            narrativeSummary: "",
            moodStartDescription: "",
            moodEndDescription: "",
            moodShiftDescription: "",
            keyInsight: "",
            userQuotes: [],
            copingStrategiesExplored: [],
            actionItemsForTherapist: [],
            recurringPatternAlert: "",
            homework: ""
        )

        ProfileBuilder.integrate(
            notes: notes,
            moodBefore: 5,
            moodAfter: 7,
            into: profile,
            context: context
        )

        XCTAssertTrue(profile.recurringTopics.contains("anxiety"))
        XCTAssertTrue(profile.recurringTopics.contains("work"))
        XCTAssertEqual(profile.sessionsAnalysed, 1)
    }

    func testIntegrate_MergesStrategiesWithDeduplication() {
        // Pre-populate
        profile.preferredCopingStrategies = ["meditation"]

        let notes = SessionSummarizer.SessionNotes(
            mainTopics: [],
            observedMood: "",
            copingStrategies: ["Walking"],
            keyInsights: "",
            suggestedFollowUp: "",
            narrativeSummary: "",
            moodStartDescription: "",
            moodEndDescription: "",
            moodShiftDescription: "",
            keyInsight: "",
            userQuotes: [],
            copingStrategiesExplored: ["✅ Breathing→worked well", "⚠️ Journaling → mixed results"],
            actionItemsForTherapist: [],
            recurringPatternAlert: "",
            homework: "",
            copingStrategiesAttempted: ["Breathing", "Walking"],
            copingStrategiesWorked: ["Breathing"],
            copingStrategiesDidntWork: ["Avoidance"]
        )

        ProfileBuilder.integrate(
            notes: notes,
            moodBefore: nil,
            moodAfter: nil,
            into: profile,
            context: context
        )

        // Should merge legacy + expanded and strip effectiveness notes.
        XCTAssertEqual(profile.preferredCopingStrategies.count, 4)
        XCTAssertEqual(profile.preferredCopingStrategies[0], "walking")
        XCTAssertEqual(profile.preferredCopingStrategies[1], "breathing")
        XCTAssertEqual(profile.preferredCopingStrategies[2], "journaling")
        XCTAssertEqual(profile.preferredCopingStrategies[3], "meditation")
        XCTAssertTrue(profile.communicationNotes.contains("Less effective strategy: Avoidance"))
    }

    func testIntegrate_UpdatesMoodPattern() {
        let notes = SessionSummarizer.SessionNotes(
            mainTopics: [], observedMood: "", copingStrategies: [], keyInsights: "",
            suggestedFollowUp: "",
            narrativeSummary: "", moodStartDescription: "", moodEndDescription: "",
            moodShiftDescription: "",
            keyInsight: "", userQuotes: [], copingStrategiesExplored: [],
            actionItemsForTherapist: [], recurringPatternAlert: "", homework: ""
        )

        // Before 4, After 8 -> Improved notably
        ProfileBuilder.integrate(
            notes: notes, moodBefore: 4, moodAfter: 8, into: profile, context: context)

        XCTAssertEqual(profile.emotionalPatterns.count, 1)
        XCTAssertTrue(profile.emotionalPatterns[0].contains("Mood improved notably"))
    }

    func testIntegrate_EnforcesStrategyLimit() {
        profile.preferredCopingStrategies = (1...10).map { "existing-\($0)" }

        let notes = SessionSummarizer.SessionNotes(
            mainTopics: [],
            observedMood: "",
            copingStrategies: ["new-a", "new-b", "new-c", "new-d", "new-e"],
            keyInsights: "",
            suggestedFollowUp: "",
            narrativeSummary: "",
            moodStartDescription: "",
            moodEndDescription: "",
            moodShiftDescription: "",
            keyInsight: "",
            userQuotes: [],
            copingStrategiesExplored: [],
            actionItemsForTherapist: [],
            recurringPatternAlert: "",
            homework: ""
        )

        ProfileBuilder.integrate(
            notes: notes,
            moodBefore: nil,
            moodAfter: nil,
            into: profile,
            context: context
        )

        XCTAssertEqual(profile.preferredCopingStrategies.count, 12)
        XCTAssertEqual(
            Array(profile.preferredCopingStrategies.prefix(5)),
            ["new-a", "new-b", "new-c", "new-d", "new-e"]
        )
    }

    func testIntegrate_UsesV2SignalsForTopicsAndTriggers() {
        let notes = SessionSummarizer.SessionNotes(
            mainTopics: ["Work"],
            observedMood: "",
            copingStrategies: [],
            keyInsights: "",
            suggestedFollowUp: "",
            narrativeSummary: "",
            moodStartDescription: "",
            moodEndDescription: "",
            moodShiftDescription: "",
            keyInsight: "",
            userQuotes: [],
            copingStrategiesExplored: [],
            actionItemsForTherapist: [],
            recurringPatternAlert: "",
            homework: "",
            relatedThemes: ["Manager feedback"],
            recurringTopicsSnapshot: ["sleep debt"],
            continuityEnvironmentalFactors: ["Late-night caffeine"],
            dominantEmotions: ["anxiety", "fatigue"]
        )

        ProfileBuilder.integrate(
            notes: notes,
            moodBefore: nil,
            moodAfter: nil,
            into: profile,
            context: context
        )

        XCTAssertTrue(profile.recurringTopics.contains("work"))
        XCTAssertTrue(profile.recurringTopics.contains("manager feedback"))
        XCTAssertTrue(profile.recurringTopics.contains("sleep debt"))
        XCTAssertTrue(profile.knownTriggers.contains("late-night caffeine"))
        XCTAssertEqual(profile.moodBaseline, "anxiety, fatigue")
    }
}
