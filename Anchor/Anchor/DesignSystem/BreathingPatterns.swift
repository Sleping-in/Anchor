//
//  BreathingPatterns.swift
//  Anchor
//
//  Shared breathing pattern definitions.
//

import Foundation
import SwiftUI
import SwiftData

enum BreathingPhase: String {
    case ready
    case inhale
    case hold
    case exhale
    case complete

    var label: String {
        switch self {
        case .ready:
            return String(localized: "Get comfortable")
        case .inhale:
            return String(localized: "Breathe in")
        case .hold:
            return String(localized: "Hold")
        case .exhale:
            return String(localized: "Breathe out")
        case .complete:
            return String(localized: "Well done")
        }
    }
}

struct BreathingStep {
    let label: String
    let phase: BreathingPhase
    let duration: TimeInterval
    let scale: CGFloat
}

enum BreathingPatternKind: String, CaseIterable, Identifiable {
    case box
    case fourSevenEight
    case physiologicalSigh

    var id: String { rawValue }

    var title: String {
        switch self {
        case .box: return String(localized: "Box")
        case .fourSevenEight: return String(localized: "4-7-8")
        case .physiologicalSigh: return String(localized: "Physiological Sigh")
        }
    }

    static func from(actionValue: String) -> BreathingPatternKind? {
        let normalized = actionValue
            .lowercased()
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")
        switch normalized {
        case "box": return .box
        case "478", "fourseveneight": return .fourSevenEight
        case "physiologicalsigh", "sigh": return .physiologicalSigh
        default: return nil
        }
    }
}

struct BreathingPattern {
    let kind: BreathingPatternKind
    let name: String
    let description: String
    let steps: [BreathingStep]
    let cycles: Int
    let recommendedFor: String
}

enum BreathingPatternCatalog {
    static let patterns: [BreathingPattern] = [
        BreathingPattern(
            kind: .box,
            name: String(localized: "Box"),
            description: String(localized: "Even rhythm to steady anxiety."),
            steps: [
                BreathingStep(label: String(localized: "Inhale"), phase: .inhale, duration: 4, scale: 1.0),
                BreathingStep(label: String(localized: "Hold"), phase: .hold, duration: 4, scale: 1.0),
                BreathingStep(label: String(localized: "Exhale"), phase: .exhale, duration: 4, scale: 0.5),
                BreathingStep(label: String(localized: "Hold"), phase: .hold, duration: 4, scale: 0.5)
            ],
            cycles: 4,
            recommendedFor: String(localized: "Anxiety")
        ),
        BreathingPattern(
            kind: .fourSevenEight,
            name: String(localized: "4-7-8"),
            description: String(localized: "Longer exhale to invite sleep."),
            steps: [
                BreathingStep(label: String(localized: "Inhale"), phase: .inhale, duration: 4, scale: 1.0),
                BreathingStep(label: String(localized: "Hold"), phase: .hold, duration: 7, scale: 1.0),
                BreathingStep(label: String(localized: "Exhale"), phase: .exhale, duration: 8, scale: 0.5)
            ],
            cycles: 3,
            recommendedFor: String(localized: "Sleep")
        ),
        BreathingPattern(
            kind: .physiologicalSigh,
            name: String(localized: "Physiological Sigh"),
            description: String(localized: "Two quick inhales, long exhale."),
            steps: [
                BreathingStep(label: String(localized: "Inhale"), phase: .inhale, duration: 2, scale: 0.85),
                BreathingStep(label: String(localized: "Sip in"), phase: .inhale, duration: 1, scale: 1.0),
                BreathingStep(label: String(localized: "Long exhale"), phase: .exhale, duration: 6, scale: 0.5)
            ],
            cycles: 4,
            recommendedFor: String(localized: "Panic")
        )
    ]

    static func pattern(for kind: BreathingPatternKind?) -> BreathingPattern {
        patterns.first { $0.kind == kind } ?? patterns[0]
    }

    static func suggestedPattern(sessions: [Session], now: Date = Date()) -> BreathingPatternKind {
        let hour = Calendar.current.component(.hour, from: now)
        if hour >= 20 || hour <= 6 { return .fourSevenEight }
        if let lastMood = sessions.first?.moodAfter ?? sessions.first?.moodBefore, lastMood <= 2 {
            return .physiologicalSigh
        }
        return .box
    }
}
