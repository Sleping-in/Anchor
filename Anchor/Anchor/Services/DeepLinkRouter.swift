//
//  DeepLinkRouter.swift
//  Anchor
//
//  Routes deep links from widgets (and future sources) to
//  the correct in-app destination.
//
//  URL scheme: anchor://  (e.g. anchor://conversation, anchor://breathing)
//

import Foundation
import SwiftUI
import Observation

enum DeepLinkDestination: Equatable, Hashable {
    case home
    case conversation
    case breathing
    case insights
    case history
    case settings
    case anchorMoment
}

enum DeepLinkAction: String, Equatable, Hashable {
    case endSession
}

@Observable
@MainActor
final class DeepLinkRouter {
    var pendingDestination: DeepLinkDestination?
    var pendingAction: DeepLinkAction?

    func handle(_ url: URL) {
        guard url.scheme == "anchor" else { return }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let actionValue = components?.queryItems?.first(where: { $0.name == "action" })?.value?.lowercased()
        let endValue = components?.queryItems?.first(where: { $0.name == "end" })?.value

        switch url.host {
        case "conversation":
            pendingDestination = .conversation
            if actionValue == "end" || actionValue == "endsession" || endValue == "1" {
                pendingAction = .endSession
            }
        case "breathing":    pendingDestination = .breathing
        case "insights":     pendingDestination = .insights
        case "history":      pendingDestination = .history
        case "settings":     pendingDestination = .settings
        case "anchorMoment": pendingDestination = .anchorMoment
        default:             pendingDestination = .home
        }
    }

    func consume() -> DeepLinkDestination? {
        let dest = pendingDestination
        pendingDestination = nil
        return dest
    }

    func consumeAction() -> DeepLinkAction? {
        let action = pendingAction
        pendingAction = nil
        return action
    }
}
