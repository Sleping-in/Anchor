//
//  SessionFocus.swift
//  Anchor
//
//  Session focus/playlist options to prime the conversation.
//

import Foundation

enum SessionFocus: String, CaseIterable, Identifiable {
    case vent
    case problemSolve
    case gratitude
    case justTalk

    var id: String { rawValue }

    var title: String {
        switch self {
        case .vent: return String(localized: "Vent")
        case .problemSolve: return String(localized: "Problem-solve")
        case .gratitude: return String(localized: "Gratitude")
        case .justTalk: return String(localized: "Just talk")
        }
    }

    var subtitle: String {
        switch self {
        case .vent: return String(localized: "Let it out")
        case .problemSolve: return String(localized: "Find next steps")
        case .gratitude: return String(localized: "Notice what's good")
        case .justTalk: return String(localized: "Go with the flow")
        }
    }

    var promptInstruction: String {
        switch self {
        case .vent:
            return "They want to vent. Focus on listening, validation, and gentle reflection before offering solutions."
        case .problemSolve:
            return "They want help problem-solving. Ask clarifying questions, then suggest concrete next steps."
        case .gratitude:
            return "They want a gratitude-focused session. Encourage noticing positives and small wins."
        case .justTalk:
            return "They want a free-form conversation. Follow their lead and keep it open-ended."
        }
    }
}
