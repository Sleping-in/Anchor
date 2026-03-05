//
//  LogMoodIntent.swift
//  Anchor
//
//  App Intent: "Log my mood" — accepts an optional mood score
//  and opens the app to the conversation / mood check-in.
//

import AppIntents
import Foundation

struct LogMoodIntent: AppIntent {
    static var title: LocalizedStringResource = "Log my mood"
    static var description: IntentDescription = "Open Anchor and log how you're feeling."
    static var openAppWhenRun = true

    @Parameter(title: "Mood score", description: "Rate your mood from 1 (low) to 5 (great).")
    var moodScore: Int?

    static var parameterSummary: some ParameterSummary {
        Summary("Log mood at level \(\.$moodScore)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let score = moodScore.map { max(1, min(5, $0)) }
        if let score {
            DeepLinkBridge.post(destination: "conversation?mood=\(score)")
        } else {
            DeepLinkBridge.post(destination: "conversation")
        }

        let emoji: String
        switch score {
        case 1: emoji = "😞"
        case 2: emoji = "😔"
        case 3: emoji = "😐"
        case 4: emoji = "🙂"
        case 5: emoji = "😊"
        default: emoji = "🫶"
        }

        return .result(dialog: "Opening Anchor \(emoji)")
    }
}
