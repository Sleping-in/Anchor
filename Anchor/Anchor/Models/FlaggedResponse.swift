//
//  FlaggedResponse.swift
//  Anchor
//
//  Model for user-reported problematic AI responses.
//  Stored locally alongside sessions for later review.
//

import Foundation
import SwiftData

@Model
final class FlaggedResponse {
    var id: UUID
    var timestamp: Date
    var aiMessage: String
    var userMessageBefore: String
    var reason: String
    var sessionId: UUID?
    var reviewed: Bool

    init(
        aiMessage: String,
        userMessageBefore: String = "",
        reason: String = "",
        sessionId: UUID? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.aiMessage = aiMessage
        self.userMessageBefore = userMessageBefore
        self.reason = reason
        self.sessionId = sessionId
        self.reviewed = false
    }
}
