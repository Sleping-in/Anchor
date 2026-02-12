//
//  ConversationMessage.swift
//  Anchor
//
//  Simple message model for live conversation.
//

import Foundation

struct ConversationMessage: Identifiable, Equatable {
    enum Role: String {
        case user
        case assistant
    }

    let id: UUID
    let role: Role
    var text: String
    var isStreaming: Bool
    let timestamp: Date

    init(
        id: UUID = UUID(),
        role: Role,
        text: String,
        isStreaming: Bool = false,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.isStreaming = isStreaming
        self.timestamp = timestamp
    }
}
