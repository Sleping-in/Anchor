//
//  BookmarkedInsight.swift
//  Anchor
//
//  Stores a bookmarked AI response for quick revisit.
//

import Foundation
import SwiftData

@Model
final class BookmarkedInsight {
    var id: UUID
    var timestamp: Date
    var message: String
    var userContext: String
    var sessionId: UUID?
    var sessionDate: Date?

    init(
        message: String,
        userContext: String = "",
        sessionId: UUID? = nil,
        sessionDate: Date? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.message = message
        self.userContext = userContext
        self.sessionId = sessionId
        self.sessionDate = sessionDate
    }
}
