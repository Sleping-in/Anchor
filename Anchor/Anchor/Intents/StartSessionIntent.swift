//
//  StartSessionIntent.swift
//  Anchor
//
//  App Intent: "Start an Anchor session" — opens a new conversation.
//

import AppIntents
import Foundation

struct StartSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Start a session"
    static var description: IntentDescription = "Open Anchor and begin a new voice conversation."
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        DeepLinkBridge.post(destination: "conversation")
        return .result()
    }
}
