//
//  StartBreathingIntent.swift
//  Anchor
//
//  App Intent: "Start a breathing exercise" — opens the breathing view.
//

import AppIntents
import Foundation

struct StartBreathingIntent: AppIntent {
    static var title: LocalizedStringResource = "Start a breathing exercise"
    static var description: IntentDescription =
        "Open Anchor and begin a calming breathing exercise."
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        DeepLinkBridge.post(destination: "breathing")
        return .result()
    }
}
