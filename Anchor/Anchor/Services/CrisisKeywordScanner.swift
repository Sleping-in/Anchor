//
//  CrisisKeywordScanner.swift
//  Anchor
//
//  Extracted crisis-keyword detection for testability.
//

import Foundation

enum CrisisKeywordScanner {

    /// All crisis-related phrases (lowercased).
    static let keywords: [String] = [
        "kill myself", "killing myself", "want to die", "wanna die",
        "end my life", "ending my life", "take my life", "taking my life",
        "suicide", "suicidal", "self-harm", "self harm", "selfharm",
        "hurt myself", "hurting myself", "cut myself", "cutting myself",
        "overdose", "jump off", "hang myself", "shoot myself",
        "don't want to live", "dont want to live", "no reason to live",
        "better off dead", "wish i was dead", "wish i were dead",
        "not worth living", "can't go on", "cant go on", "end it all"
    ]

    /// Returns `true` when any crisis keyword is found in `text` (case-insensitive).
    static func containsCrisisLanguage(_ text: String) -> Bool {
        let lower = text.lowercased()
        for keyword in keywords {
            if lower.contains(keyword) {
                return true
            }
        }
        return false
    }
}
