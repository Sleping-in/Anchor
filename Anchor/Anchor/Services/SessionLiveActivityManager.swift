//
//  SessionLiveActivityManager.swift
//  Anchor
//
//  Handles Live Activity lifecycle for active sessions.
//

import ActivityKit
import Foundation

@MainActor
final class SessionLiveActivityManager {
    static let shared = SessionLiveActivityManager()

    private var activity: Activity<AnchorSessionActivityAttributes>?
    private var authInfo: ActivityAuthorizationInfo?
    private var areActivitiesEnabled: Bool = false

    private init() {
        // Cache the authorization info to reduce entitlement checks
        self.authInfo = ActivityAuthorizationInfo()
        self.areActivitiesEnabled = authInfo?.areActivitiesEnabled ?? false
    }

    func start(
        sessionID: UUID,
        startedAt: Date,
        status: AnchorSessionActivityAttributes.Status,
        focusTitle: String?,
        isPrivate: Bool
    ) {
        // Re-check on start (in case settings changed), but cache the result
        areActivitiesEnabled = authInfo?.areActivitiesEnabled ?? false
        guard areActivitiesEnabled else { return }
        if activity != nil {
            Task { await update(status: status, isPrivate: isPrivate) }
            return
        }

        let attributes = AnchorSessionActivityAttributes(
            sessionID: sessionID,
            startedAt: startedAt,
            focusTitle: focusTitle
        )
        let state = AnchorSessionActivityAttributes.ContentState(status: status, isPrivate: isPrivate)
        do {
            let content = ActivityContent(state: state, staleDate: nil)
            activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            print("[LiveActivity] Failed to start: \(error.localizedDescription)")
        }
    }

    func update(status: AnchorSessionActivityAttributes.Status, isPrivate: Bool) async {
        guard let activity else { return }
        let state = AnchorSessionActivityAttributes.ContentState(status: status, isPrivate: isPrivate)
        await activity.update(ActivityContent(state: state, staleDate: nil))
    }

    func end() async {
        guard let activity else { return }
        let state = AnchorSessionActivityAttributes.ContentState(status: .ended, isPrivate: false)
        await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .immediate)
        self.activity = nil
    }
}
