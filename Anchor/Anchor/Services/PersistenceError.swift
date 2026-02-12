//
//  PersistenceError.swift
//  Anchor
//
//  Centralised SwiftData save helper with error surfacing.
//

import SwiftUI
import SwiftData
import os.log

private let logger = Logger(subsystem: "com.anchor.app", category: "Persistence")

// MARK: - Safe save

extension ModelContext {
    /// Attempts to save and logs on failure.
    /// Returns `true` on success.
    @discardableResult
    func safeSave() -> Bool {
        do {
            try save()
            return true
        } catch {
            logger.error("SwiftData save failed: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: - View modifier for surfacing save errors

/// Attach `.persistenceAlert(isPresented:)` to any view that performs saves.
struct PersistenceAlertModifier: ViewModifier {
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content
            .alert(String(localized: "Couldn't Save"), isPresented: $isPresented) {
                Button(String(localized: "OK"), role: .cancel) { }
            } message: {
                Text(String(localized: "Your change may not have been saved. Please try again. If the problem persists, restart the app."))
            }
    }
}

extension View {
    func persistenceAlert(isPresented: Binding<Bool>) -> some View {
        modifier(PersistenceAlertModifier(isPresented: isPresented))
    }
}
