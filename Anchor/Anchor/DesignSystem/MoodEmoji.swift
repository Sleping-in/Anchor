//
//  MoodEmoji.swift
//  Anchor
//
//  Shared mapping for mood scale → emoji.
//

import Foundation

enum MoodEmoji {
    static func emoji(for level: Int?) -> String {
        guard let level else { return "😐" }
        switch level {
        case 1: return "😞"
        case 2: return "😔"
        case 3: return "😐"
        case 4: return "🙂"
        case 5: return "😊"
        default: return "😐"
        }
    }
}
