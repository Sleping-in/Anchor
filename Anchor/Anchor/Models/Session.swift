//
//  Session.swift
//  Anchor
//
//  Created for Anchor - AI-Powered Emotional Support
//

import Foundation
import SwiftData

/// Represents a conversation session with the AI emotional support system
@Model
final class Session {
    /// Unique identifier for the session
    var id: UUID
    
    /// When the session was created
    var timestamp: Date
    
    /// Duration of the session in seconds
    var duration: TimeInterval
    
    /// Brief summary of the session (not full transcript for privacy)
    var summary: String
    
    /// User's mood at the start of session (1-5 scale)
    var moodBefore: Int?
    
    /// User's mood at the end of session (1-5 scale)
    var moodAfter: Int?
    
    /// Tags or categories for the session
    var tags: [String]
    
    /// Whether the session was completed or interrupted
    var completed: Bool
    
    /// Crisis flag - if crisis keywords were detected
    var crisisDetected: Bool
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        duration: TimeInterval = 0,
        summary: String = "",
        moodBefore: Int? = nil,
        moodAfter: Int? = nil,
        tags: [String] = [],
        completed: Bool = false,
        crisisDetected: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.duration = duration
        self.summary = summary
        self.moodBefore = moodBefore
        self.moodAfter = moodAfter
        self.tags = tags
        self.completed = completed
        self.crisisDetected = crisisDetected
    }
    
    /// Formatted duration string (e.g., "15 min 30 sec")
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes) min \(seconds) sec"
        } else {
            return "\(seconds) sec"
        }
    }
}
