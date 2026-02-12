//
//  ShareCardRenderTests.swift
//  AnchorTests
//
//  Tests for branded share card rendering.
//

import SwiftUI
import XCTest

@testable import Anchor

@MainActor
final class ShareCardRenderTests: XCTestCase {

    func testSummaryShareCardRendersImage() {
        let payload = populatedPayload()
        let view = SessionSummaryShareCardView(payload: payload, summaryStatus: .ready)
            .frame(width: 380)
            .padding(20)
            .background(Color.white)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 3

        let image = renderer.uiImage
        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image?.pngData()?.count ?? 0, 0)
    }

    func testNotesShareCardRendersImage() {
        let payload = populatedPayload()
        let view = SessionNotesShareCardView(payload: payload, summaryStatus: .ready)
            .frame(width: 380)
            .padding(20)
            .background(Color.white)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 3

        let image = renderer.uiImage
        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image?.pngData()?.count ?? 0, 0)
    }

    func testShareCardsRenderWithMinimalPayload() {
        let payload = minimalPayload()

        let summaryView = SessionSummaryShareCardView(payload: payload, summaryStatus: .ready)
            .frame(width: 380)
            .padding(20)
            .background(Color.white)
        let notesView = SessionNotesShareCardView(payload: payload, summaryStatus: .ready)
            .frame(width: 380)
            .padding(20)
            .background(Color.white)

        let summaryRenderer = ImageRenderer(content: summaryView)
        summaryRenderer.scale = 3
        let notesRenderer = ImageRenderer(content: notesView)
        notesRenderer.scale = 3

        let summaryImage = summaryRenderer.uiImage
        let notesImage = notesRenderer.uiImage

        XCTAssertNotNil(summaryImage)
        XCTAssertGreaterThan(summaryImage?.pngData()?.count ?? 0, 0)
        XCTAssertNotNil(notesImage)
        XCTAssertGreaterThan(notesImage?.pngData()?.count ?? 0, 0)
    }

    func testSummaryShareCardUsesNumericMoodShift() {
        let payload = populatedPayload()
        let view = SessionSummaryShareCardView(payload: payload, summaryStatus: .ready)
        let moodText = view.moodMetricText

        XCTAssertEqual(moodText, "2/5 → 4/5")
        XCTAssertFalse(moodText.contains("😕"))
        XCTAssertFalse(moodText.contains("😌"))
    }

    private func populatedPayload() -> SessionSummaryPayload {
        var payload = SessionSummaryPayload(
            sessionID: UUID(),
            date: Date(),
            duration: 960,
            moodBefore: 2,
            moodAfter: 4,
            topics: ["work stress", "sleep", "boundaries"],
            takeaway: "Small routines helped me feel more grounded.",
            observedMood: "Tense but hopeful",
            copingStrategies: ["Journaling"],
            suggestedFollowUp: "Check in on the evening routine this week.",
            narrativeSummary: "You reflected on stressors at work and identified one small boundary you can reinforce.",
            moodStartDescription: "Started the session feeling scattered and anxious.",
            moodEndDescription: "Ended feeling calmer with a clearer next step.",
            moodShiftDescription: "Shifted from overwhelm toward steadier focus.",
            keyInsight: "You are more consistent when your next step is concrete.",
            userQuotes: ["I can do one small thing tonight."],
            copingStrategiesExplored: ["Box breathing", "5-minute journaling"],
            actionItemsForTherapist: ["Discuss recurring perfectionism triggers."],
            recurringPatternAlert: "Stress spikes when deadlines are unclear.",
            homework: "",
            homeworkItems: ["Set one end-of-day boundary"],
            completedHomeworkItems: []
        )
        payload.primaryFocus = "Work anxiety"
        payload.relatedThemes = ["performance pressure", "sleep debt"]
        payload.actionItemsForUser = ["Take a 2-minute breathing pause before standup"]
        payload.patternRecognized = "Anxiety rises with ambiguity"
        payload.copingStrategiesWorked = ["Box breathing"]
        payload.copingStrategiesDidntWork = ["Avoidance"]
        payload.crisisRiskDetectedByModel = false
        payload.safetyRecommendation = "Share this with your therapist next session"
        return payload
    }

    private func minimalPayload() -> SessionSummaryPayload {
        SessionSummaryPayload(
            sessionID: UUID(),
            date: Date(),
            duration: 0,
            moodBefore: nil,
            moodAfter: nil,
            topics: [],
            takeaway: "",
            observedMood: "",
            copingStrategies: [],
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
            homeworkItems: [],
            completedHomeworkItems: []
        )
    }
}
