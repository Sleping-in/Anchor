//
//  SessionSummarizerTests.swift
//  AnchorTests
//
//  Tests for prompt generation and JSON parsing in SessionSummarizer.
//

import XCTest

@testable import Anchor

final class SessionSummarizerTests: XCTestCase {

    func testGeneratePrompt_Basic() {
        let messages = [
            (role: "user", text: "I feel sad."),
            (role: "model", text: "I'm sorry to hear that."),
        ]
        let prompt = SessionSummarizer.generatePrompt(messages: messages, profileContext: "")

        XCTAssertNotNil(prompt)
        XCTAssertTrue(prompt!.contains("TRANSCRIPT:"))
        XCTAssertTrue(prompt!.contains("[USER]: I feel sad."))
        XCTAssertTrue(prompt!.contains("[MODEL]: I'm sorry to hear that."))
        XCTAssertFalse(prompt!.contains("USER PROFILE CONTEXT"))
    }

    func testGeneratePrompt_WithProfile() {
        let messages = [(role: "user", text: "Hi")]
        let profile = "User often mentions anxiety."
        let prompt = SessionSummarizer.generatePrompt(messages: messages, profileContext: profile)

        XCTAssertNotNil(prompt)
        XCTAssertTrue(prompt!.contains("USER PROFILE CONTEXT"))
        XCTAssertTrue(prompt!.contains(profile))
    }

    func testGeneratePrompt_V2IncludesSummaryContext() {
        let messages = [(role: "user", text: "I feel overwhelmed at work.")]
        let context = SessionSummarizer.SummaryContext(
            sessionDate: Date(timeIntervalSince1970: 1_738_000_000),
            durationMinutes: 24,
            sessionOrdinal: 6,
            previousTopics: ["work stress", "sleep"],
            therapyGoals: ["Practice boundaries"],
            previousHomework: ["Short evening check-in"],
            profileContext: "- Recurring topics: work stress"
        )

        let prompt = SessionSummarizer.generatePrompt(
            messages: messages,
            summaryContext: context,
            promptVersion: .v2
        )

        XCTAssertNotNil(prompt)
        XCTAssertTrue(prompt!.contains("SESSION METADATA"))
        XCTAssertTrue(prompt!.contains("Session Number: 6"))
        XCTAssertTrue(prompt!.contains("Previous session topics: work stress, sleep"))
        XCTAssertTrue(prompt!.contains("Active therapy goals: Practice boundaries"))
        XCTAssertTrue(prompt!.contains("Previous homework: Short evening check-in"))
    }

    func testParseResponse_ValidJSON() {
        let json = """
            {
              "candidates": [
                {
                  "content": {
                    "parts": [
                      {
                        "text": "{\\"narrativeSummary\\": \\"The user felt sad.\\", \\"observedMood\\": \\"Sad\\"}"
                      }
                    ]
                  }
                }
              ]
            }
            """
        let data = json.data(using: .utf8)!
        let notes = SessionSummarizer.parseResponse(data)

        XCTAssertNotNil(notes)
        XCTAssertEqual(notes?.narrativeSummary, "The user felt sad.")
        XCTAssertEqual(notes?.observedMood, "Sad")
    }

    func testParseResponse_WithMarkdownFences() {
        let json = """
            {
              "candidates": [
                {
                  "content": {
                    "parts": [
                      {
                        "text": "```json\\n{\\"narrativeSummary\\": \\"Cleaned.\\"}\\n```"
                      }
                    ]
                  }
                }
              ]
            }
            """
        let data = json.data(using: .utf8)!
        let notes = SessionSummarizer.parseResponse(data)

        XCTAssertNotNil(notes)
        XCTAssertEqual(notes?.narrativeSummary, "Cleaned.")
    }

    func testParseResponse_V2FullNestedJSON() {
        let noteJSON = #"""
        {
          "sessionMetadata": {
            "date": "2026-02-11T20:35:00Z",
            "durationMinutes": 19,
            "sessionNumber": 8
          },
          "summary": {
            "narrativeSummary": "You processed stress about tomorrow's presentation and identified a concrete next step.",
            "primaryFocus": "Work anxiety",
            "relatedThemes": ["performance pressure", "self-criticism"]
          },
          "moodJourney": {
            "starting": {
              "description": "Tense and restless",
              "intensity": 8,
              "physicalSymptoms": ["tight chest", "shallow breathing"]
            },
            "ending": {
              "description": "Calmer and clearer",
              "intensity": 4,
              "physicalSymptoms": ["slower breathing"]
            },
            "whatShifted": "Naming your fear and planning one concrete action reduced uncertainty."
          },
          "insights": {
            "keyInsight": "The anxiety is driven by fear of judgment, not lack of preparation.",
            "userQuotes": ["I know the content, I fear being judged."],
            "patternRecognized": "You seek reassurance when outcomes feel ambiguous."
          },
          "copingStrategies": {
            "attempted": [
              {
                "strategy": "Box breathing",
                "effectiveness": "✅ Helped",
                "userFeedback": "I felt my body settle."
              }
            ],
            "whatWorked": ["Box breathing"],
            "whatDidntWork": ["Avoiding prep conversation"]
          },
          "patterns": {
            "recurringTopics": [
              {
                "topic": "Fear of manager judgment",
                "frequency": "5 of last 6 sessions",
                "firstMentioned": "Session 2",
                "trend": "Stable"
              }
            ],
            "alertForTherapist": "Explore external validation and authority dynamics."
          },
          "progressTracking": {
            "previousHomework": {
              "assigned": "Write one compassionate self-statement nightly",
              "completion": "⚠️ Partial",
              "userReflection": "I did it twice and felt more grounded."
            },
            "therapyGoals": [
              {
                "goal": "Reduce anxiety spikes before presentations",
                "progress": "Some progress",
                "evidence": "Reported lower anxiety after breathing."
              }
            ]
          },
          "actionItems": {
            "forUser": ["Practice a 2-minute breathing reset before tomorrow's meeting"],
            "forTherapist": ["Discuss fear of authority evaluation"],
            "newHomework": "Track one anxious thought and one balanced reframe each evening."
          },
          "contextForContinuity": {
            "peoplesMentioned": [
              {
                "name": "Sarah",
                "relationship": "Manager",
                "significance": "Primary trigger for evaluation fear"
              }
            ],
            "upcomingEvents": [
              {
                "event": "Leadership presentation",
                "date": "Tomorrow 2 PM",
                "anxietyLevel": "High (8/10)"
              }
            ],
            "environmentalFactors": ["Slept 4 hours", "Skipped exercise this week"]
          },
          "safetyAssessment": {
            "crisisRiskDetected": false,
            "crisisNotes": null,
            "protectiveFactors": ["Supportive partner"],
            "recommendation": "Share with therapist at next session"
          },
          "clinicalObservations": {
            "dominantEmotions": ["anxiety", "fear", "relief"],
            "primaryCopingStyle": "Cognitive reframing",
            "sessionEffectiveness": 7
          }
        }
        """#

        let responseData = makeGeminiResponse(noteJSON: noteJSON)
        let notes = SessionSummarizer.parseResponse(responseData, preferredVersion: .v2)

        XCTAssertNotNil(notes)
        XCTAssertEqual(notes?.summarySchemaVersion, 2)
        XCTAssertEqual(notes?.sessionOrdinal, 8)
        XCTAssertEqual(notes?.primaryFocus, "Work anxiety")
        XCTAssertEqual(notes?.relatedThemes, ["performance pressure", "self-criticism"])
        XCTAssertEqual(notes?.moodStartIntensity, 8)
        XCTAssertEqual(notes?.moodEndIntensity, 4)
        XCTAssertEqual(notes?.copingStrategiesWorked, ["Box breathing"])
        XCTAssertEqual(notes?.copingStrategiesDidntWork, ["Avoiding prep conversation"])
        XCTAssertEqual(notes?.actionItemsForUser.count, 1)
        XCTAssertEqual(notes?.crisisRiskDetectedByModel, false)
        XCTAssertEqual(notes?.primaryCopingStyle, "Cognitive reframing")
        XCTAssertEqual(notes?.sessionEffectivenessSelfRating, 7)
    }

    func testParseResponse_V2PartialJSONMissingBlocksStillParses() {
        let noteJSON = #"""
        {
          "summary": {
            "narrativeSummary": "You named one stressor and one next step.",
            "primaryFocus": "Stress"
          },
          "actionItems": {
            "newHomework": "Write down one worry and one alternative perspective."
          }
        }
        """#

        let responseData = makeGeminiResponse(noteJSON: noteJSON)
        let notes = SessionSummarizer.parseResponse(responseData, preferredVersion: .v2)

        XCTAssertNotNil(notes)
        XCTAssertEqual(notes?.summarySchemaVersion, 2)
        XCTAssertEqual(notes?.narrativeSummary, "You named one stressor and one next step.")
        XCTAssertEqual(notes?.primaryFocus, "Stress")
        XCTAssertEqual(notes?.homework, "Write down one worry and one alternative perspective.")
        XCTAssertEqual(notes?.actionItemsForTherapist, [])
    }

    func testParseResponse_V2PreferredFallsBackToLegacyFlatJSON() {
        let responseData = makeGeminiResponse(
            noteJSON: #"{"mainTopics":["work"],"keyInsights":"Small win today","narrativeSummary":"You reflected on one win."}"#
        )

        let notes = SessionSummarizer.parseResponse(responseData, preferredVersion: .v2)

        XCTAssertNotNil(notes)
        XCTAssertEqual(notes?.summarySchemaVersion, 1)
        XCTAssertEqual(notes?.mainTopics, ["work"])
        XCTAssertEqual(notes?.keyInsights, "Small win today")
        XCTAssertEqual(notes?.narrativeSummary, "You reflected on one win.")
    }

    func testParseResponse_PartialJSONMissingFieldsUsesDefaults() {
        let responseData = makeGeminiResponse(
            noteJSON:
                #"{"mainTopics":["work"],"keyInsights":"Small win today","narrativeSummary":"You reflected on one win."}"#
        )

        let notes = SessionSummarizer.parseResponse(responseData)

        XCTAssertNotNil(notes)
        XCTAssertEqual(notes?.mainTopics, ["work"])
        XCTAssertEqual(notes?.keyInsights, "Small win today")
        XCTAssertEqual(notes?.narrativeSummary, "You reflected on one win.")
        XCTAssertEqual(notes?.observedMood, "")
        XCTAssertEqual(notes?.copingStrategies, [])
        XCTAssertEqual(notes?.suggestedFollowUp, "")
        XCTAssertEqual(notes?.homework, "")
    }

    func testParseResponse_EmptyStringFieldsAreHandled() {
        let responseData = makeGeminiResponse(
            noteJSON:
                #"{"mainTopics":[],"observedMood":"","copingStrategies":[],"keyInsights":"","suggestedFollowUp":"","narrativeSummary":"","moodStartDescription":"","moodEndDescription":"","moodShiftDescription":"","keyInsight":"","userQuotes":[],"copingStrategiesExplored":[],"actionItemsForTherapist":[],"recurringPatternAlert":"","homework":""}"#
        )

        let notes = SessionSummarizer.parseResponse(responseData)

        XCTAssertNotNil(notes)
        XCTAssertEqual(notes?.observedMood, "")
        XCTAssertEqual(notes?.narrativeSummary, "")
        XCTAssertEqual(notes?.moodStartDescription, "")
        XCTAssertEqual(notes?.moodEndDescription, "")
        XCTAssertEqual(notes?.moodShiftDescription, "")
        XCTAssertEqual(notes?.keyInsight, "")
        XCTAssertEqual(notes?.userQuotes, [])
        XCTAssertEqual(notes?.copingStrategiesExplored, [])
        XCTAssertEqual(notes?.actionItemsForTherapist, [])
        XCTAssertEqual(notes?.recurringPatternAlert, "")
        XCTAssertEqual(notes?.homework, "")
    }

    func testParseResponse_MalformedInnerJSONReturnsNil() {
        let responseData = makeGeminiResponse(noteJSON: #"{"narrativeSummary":"broken""#)
        let notes = SessionSummarizer.parseResponse(responseData)
        XCTAssertNil(notes)
    }

    private func makeGeminiResponse(noteJSON: String) -> Data {
        let escaped = noteJSON
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
        let envelope = """
            {
              "candidates": [
                {
                  "content": {
                    "parts": [
                      {
                        "text": "\(escaped)"
                      }
                    ]
                  }
                }
              ]
            }
            """
        return Data(envelope.utf8)
    }
}
