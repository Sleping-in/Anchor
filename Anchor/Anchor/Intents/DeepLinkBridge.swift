//
//  DeepLinkBridge.swift
//  Anchor
//
//  Lightweight bridge for App Intents to trigger navigation.
//  Posts a notification that `DeepLinkRouter` observes, or
//  falls back to opening the URL scheme directly.
//

import Foundation
import UIKit

enum DeepLinkBridge {
    /// Post a deep link destination so the running app can navigate to it.
    /// If the app is cold-launching, `UIApplication.open` handles it.
    static func post(destination: String) {
        guard let url = URL(string: "anchor://\(destination)") else { return }
        Task { @MainActor in
            UIApplication.shared.open(url)
        }
    }
}
