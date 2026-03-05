//
//  VoiceStateController.swift
//  Anchor
//
//  Lightweight bridge for voice pipeline state updates.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class VoiceStateController: ObservableObject {
    @Published private(set) var state: VoiceState = .idle

    nonisolated func update(_ newState: VoiceState) {
        Task { @MainActor in
            self.state = newState
        }
    }

    nonisolated func reset() {
        Task { @MainActor in
            self.state = .idle
        }
    }
}
