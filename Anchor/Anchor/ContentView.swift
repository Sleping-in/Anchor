//
//  ContentView.swift
//  Anchor
//
//  Created by Mohammad Elhaj on 07/02/2026.
//

import SwiftUI
import SwiftData
import LocalAuthentication

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var settings: [UserSettings]
    @State private var isLocked = false
    @State private var isAuthenticating = false
    @State private var authErrorMessage: String?
    @State private var showingMigrationResetAlert = false

    private var userSettings: UserSettings? {
        settings.first
    }

    private var lockEnabled: Bool {
        userSettings?.appLockEnabled ?? false
    }

    var body: some View {
        ZStack {
            if let userSettings, userSettings.hasCompletedOnboarding {
                HomeView()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else if userSettings != nil {
                OnboardingView()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                Color.clear
                    .anchorScreenBackground()
            }

            if lockEnabled && isLocked {
                AppLockView(
                    isAuthenticating: isAuthenticating,
                    errorMessage: authErrorMessage,
                    onUnlock: authenticateIfNeeded
                )
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: userSettings?.hasCompletedOnboarding ?? false)
        .onAppear {
            ensureSettings()
            applyUITestOverrides()
            updateLockState()
            checkMigrationReset()
        }
        .onChange(of: lockEnabled) { _, _ in
            updateLockState()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard lockEnabled else { return }
            switch newPhase {
            case .background:
                isLocked = true
            case .active:
                authenticateIfNeeded()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
        .alert(String(localized: "Update Notice"), isPresented: $showingMigrationResetAlert) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            Text(String(localized: "We updated Anchor and had to reset local data. A backup of your previous sessions was saved on this device."))
        }
    }

    private func ensureSettings() {
        guard settings.isEmpty else { return }
        let newSettings = UserSettings()
        if ProcessInfo.processInfo.environment["UITEST_SKIP_ONBOARDING"] == "1" {
            newSettings.hasCompletedOnboarding = true
            newSettings.hasSeenSafetyDisclaimer = true
        }
        modelContext.insert(newSettings)
        modelContext.safeSave()
    }

    private func applyUITestOverrides() {
        guard ProcessInfo.processInfo.environment["UITEST_SKIP_ONBOARDING"] == "1" else { return }
        guard let settings = userSettings else { return }
        settings.hasCompletedOnboarding = true
        settings.hasSeenSafetyDisclaimer = true
        settings.appLockEnabled = false
        modelContext.safeSave()
    }

    private func checkMigrationReset() {
        let key = "AnchorDidResetStore"
        if UserDefaults.standard.bool(forKey: key) {
            showingMigrationResetAlert = true
            UserDefaults.standard.set(false, forKey: key)
        }
    }

    private func updateLockState() {
        if lockEnabled {
            isLocked = true
            authenticateIfNeeded()
        } else {
            isLocked = false
            authErrorMessage = nil
        }
    }

    private func authenticateIfNeeded() {
        guard lockEnabled, isLocked, !isAuthenticating else { return }
        let context = LAContext()
        context.localizedCancelTitle = String(localized: "Cancel")
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isAuthenticating = true
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: String(localized: "Unlock Anchor")
            ) { success, authError in
                DispatchQueue.main.async {
                    isAuthenticating = false
                    if success {
                        isLocked = false
                        authErrorMessage = nil
                    } else {
                        authErrorMessage = authError?.localizedDescription
                            ?? String(localized: "Face ID failed.")
                    }
                }
            }
            return
        }

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            isAuthenticating = true
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: String(localized: "Unlock Anchor")
            ) { success, authError in
                DispatchQueue.main.async {
                    isAuthenticating = false
                    if success {
                        isLocked = false
                        authErrorMessage = nil
                    } else {
                        authErrorMessage = authError?.localizedDescription
                            ?? String(localized: "Authentication failed.")
                    }
                }
            }
            return
        }

        authErrorMessage = String(localized: "Face ID isn’t available on this device.")
    }
}

private struct AppLockView: View {
    let isAuthenticating: Bool
    let errorMessage: String?
    let onUnlock: () -> Void

    var body: some View {
        ZStack {
            AnchorTheme.Colors.softParchment
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Circle()
                    .fill(AnchorTheme.Colors.sageLeaf.opacity(0.15))
                    .frame(width: 96, height: 96)
                    .overlay(
                        Image(systemName: "faceid")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(AnchorTheme.Colors.quietInk)
                    )

                Text(String(localized: "Unlock Anchor"))
                    .font(AnchorTheme.Typography.headline)
                    .anchorPrimaryText()

                Text(String(localized: "Use Face ID or your device passcode to continue."))
                    .font(AnchorTheme.Typography.subheadline)
                    .anchorSecondaryText()
                    .multilineTextAlignment(.center)

                if let errorMessage {
                    Text(errorMessage)
                        .font(AnchorTheme.Typography.caption)
                        .foregroundStyle(AnchorTheme.Colors.crisisRed)
                        .multilineTextAlignment(.center)
                }

                Button(action: onUnlock) {
                    HStack(spacing: 8) {
                        if isAuthenticating {
                            ProgressView()
                        }
                        Text(isAuthenticating
                             ? String(localized: "Authenticating…")
                             : String(localized: "Unlock"))
                            .font(AnchorTheme.Typography.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(AnchorPillButtonStyle(
                    background: AnchorTheme.Colors.sageLeaf,
                    foreground: AnchorTheme.Colors.softParchment
                ))
                .disabled(isAuthenticating)
                .padding(.horizontal, 24)
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Session.self, UserSettings.self], inMemory: true)
}
