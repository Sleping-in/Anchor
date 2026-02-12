//
//  AnchorSessionActivityAttributes.swift
//  Anchor
//
//  Shared Live Activity attributes for Anchor sessions.
//

import ActivityKit
import Foundation

struct AnchorSessionActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: Status
        var isPrivate: Bool
    }

    enum Status: String, Codable, Hashable {
        case connecting
        case listening
        case thinking
        case speaking
        case paused
        case ended
    }

    var sessionID: UUID
    var startedAt: Date
    var focusTitle: String?
}
