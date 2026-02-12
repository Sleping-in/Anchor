//
//  ConversationPersona.swift
//  Anchor
//
//  Personas that shape Anchor's tone and style.
//

import Foundation

enum ConversationPersona: String, CaseIterable, Identifiable {
    case warmFriend
    case thoughtfulCoach
    case calmMentor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .warmFriend: return String(localized: "Warm Friend")
        case .thoughtfulCoach: return String(localized: "Thoughtful Coach")
        case .calmMentor: return String(localized: "Calm Mentor")
        }
    }

    var subtitle: String {
        switch self {
        case .warmFriend: return String(localized: "Gentle, validating, casual")
        case .thoughtfulCoach: return String(localized: "Socratic, curious, growth-oriented")
        case .calmMentor: return String(localized: "Structured, steady, goal-focused")
        }
    }

    var promptInstruction: String {
        switch self {
        case .warmFriend:
            return "Adopt a warm, friendly tone with gentle validation and soft encouragement."
        case .thoughtfulCoach:
            return "Use thoughtful, Socratic questions to help the user discover insights and options."
        case .calmMentor:
            return "Be calm, structured, and goal-oriented. Offer clear frameworks and next steps."
        }
    }
}
