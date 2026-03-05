//
//  DataExporterTests.swift
//  AnchorTests
//
//  Tests for JSON data export.
//

import SwiftData
import XCTest

@testable import Anchor

@MainActor
final class DataExporterXCTest: XCTestCase {

    var container: ModelContainer!
    var session: Session!
    var profile: UserProfile!

    override func setUpWithError() throws {
        let schema = Schema([Session.self, UserProfile.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: config)

        session = Session(timestamp: Date())
        session.narrativeSummary = "Summary text"
        session.moodStartDescription = "Start mood"
        session.moodEndDescription = "End mood"
        session.moodShiftDescription = "Shifted to calmer."
        session.keyInsight = "I can pause before reacting."
        session.userQuotes = ["I feel less panicked now."]
        session.copingStrategiesExplored = ["✅ Box breathing → helped"]
        session.actionItemsForTherapist = ["Discuss boundary-setting."]
        session.recurringPatternAlert = "Work stress appears repeatedly."
        session.homeworkItems = ["Practice 4-7-8 breathing nightly."]
        session.completedHomeworkItems = ["Practice 4-7-8 breathing nightly."]
        session.summarySchemaVersion = 2
        session.summaryRawJSON = "{\"summary\":{\"primaryFocus\":\"work\"}}"
        session.sessionOrdinal = 12
        session.primaryFocus = "Work anxiety"
        session.relatedThemes = ["performance", "sleep"]
        session.moodStartIntensity = 8
        session.moodEndIntensity = 4
        session.patternRecognized = "Fear spikes before manager feedback."
        session.copingStrategiesAttempted = ["Box breathing"]
        session.copingStrategiesWorked = ["Box breathing"]
        session.copingStrategiesDidntWork = ["Avoidance"]
        session.previousHomeworkAssigned = "Journal nightly"
        session.previousHomeworkCompletion = "⚠️ Partial"
        session.previousHomeworkReflection = "It helped when I did it."
        session.therapyGoalProgress = ["Reduced panic intensity before meetings."]
        session.actionItemsForUser = ["Try breathing before standup."]
        session.continuityPeopleMentioned = ["Sarah (manager)"]
        session.continuityUpcomingEvents = ["Team presentation tomorrow"]
        session.continuityEnvironmentalFactors = ["Poor sleep"]
        session.crisisRiskDetectedByModel = false
        session.safetyRecommendation = "Share with therapist at next session"
        session.dominantEmotions = ["anxiety", "relief"]
        session.primaryCopingStyle = "Cognitive reframing"
        session.sessionEffectivenessSelfRating = 7

        profile = UserProfile()
        profile.recurringTopics = ["topic1"]

        container.mainContext.insert(session)
        container.mainContext.insert(profile)
    }

    func testExportAll_CreatesFileWithData() throws {
        let url = DataExporter.exportAll(sessions: [session], profile: profile)

        XCTAssertNotNil(url)
        let data = try Data(contentsOf: url!)

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)

        let sessions = json?["sessions"] as? [[String: Any]]
        XCTAssertEqual(sessions?.count, 1)

        let s = sessions?.first
        XCTAssertEqual(s?["narrativeSummary"] as? String, "Summary text")
        XCTAssertEqual(s?["moodStartDescription"] as? String, "Start mood")
        XCTAssertEqual(s?["moodShiftDescription"] as? String, "Shifted to calmer.")
        XCTAssertEqual(s?["keyInsight"] as? String, "I can pause before reacting.")
        XCTAssertEqual(s?["recurringPatternAlert"] as? String, "Work stress appears repeatedly.")
        XCTAssertEqual(
            s?["homeworkItems"] as? [String],
            ["Practice 4-7-8 breathing nightly."]
        )
        XCTAssertEqual(
            s?["completedHomeworkItems"] as? [String],
            ["Practice 4-7-8 breathing nightly."]
        )
        XCTAssertEqual(s?["summarySchemaVersion"] as? Int, 2)
        XCTAssertEqual(s?["sessionOrdinal"] as? Int, 12)
        XCTAssertEqual(s?["primaryFocus"] as? String, "Work anxiety")
        XCTAssertEqual(s?["relatedThemes"] as? [String], ["performance", "sleep"])
        XCTAssertEqual(s?["moodStartIntensity"] as? Int, 8)
        XCTAssertEqual(s?["moodEndIntensity"] as? Int, 4)
        XCTAssertEqual(s?["patternRecognized"] as? String, "Fear spikes before manager feedback.")
        XCTAssertEqual(s?["copingStrategiesWorked"] as? [String], ["Box breathing"])
        XCTAssertEqual(s?["previousHomeworkCompletion"] as? String, "⚠️ Partial")
        XCTAssertEqual(s?["actionItemsForUser"] as? [String], ["Try breathing before standup."])
        XCTAssertEqual(s?["sessionEffectivenessSelfRating"] as? Int, 7)

        let p = json?["learnedProfile"] as? [String: Any]
        XCTAssertNotNil(p)
        let topics = p?["recurringTopics"] as? [String]
        XCTAssertTrue(topics?.contains("topic1") ?? false)
    }
}
