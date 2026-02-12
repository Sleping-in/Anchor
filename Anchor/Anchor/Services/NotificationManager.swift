//
//  NotificationManager.swift
//  Anchor
//
//  Manages local notification scheduling for daily check-in reminders.
//

import Foundation
import Combine
@preconcurrency import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    @Published private(set) var isAuthorized: Bool = false

    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    private init() {
        Task { await refreshAuthorizationStatus() }
    }

    /// Request notification permission from the user.
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            return granted
        } catch {
            isAuthorized = false
            return false
        }
    }

    /// Check current authorization status.
    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Daily Check-in Reminder

    private let dailyCheckInIdentifier = "com.anchor.dailyCheckIn"
    private let anchorMomentIdentifier = "com.anchor.anchorMoment"
    private let weeklyShareIdentifier = "com.anchor.weeklyShare"

    /// Schedule a daily check-in reminder at the given hour and minute.
    func scheduleDailyCheckIn(preferredTime: DateComponents? = nil) {
        // Remove existing before re-scheduling
        center.removePendingNotificationRequests(withIdentifiers: [dailyCheckInIdentifier])

        let hour = preferredTime?.hour ?? 19
        let minute = preferredTime?.minute ?? 0
        let timeLabel = preferredTime.map { _ in
            CheckInTimeEstimator.formatTime(hour: hour, minute: minute)
        }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "How are you today?")
        if let timeLabel {
            content.body = String.localizedStringWithFormat(
                String(localized: "You usually check in around %@ — want to talk?"),
                timeLabel
            )
        } else {
            content.body = String(localized: "Take a moment to check in with Anchor. Your feelings matter.")
        }
        content.sound = .default
        content.categoryIdentifier = "DAILY_CHECKIN"
        content.userInfo = ["deepLink": "anchor://conversation"]

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: dailyCheckInIdentifier, content: content, trigger: trigger)

        center.add(request) { error in
            if let error {
                print("[NotificationManager] Failed to schedule: \(error.localizedDescription)")
            }
        }
    }

    /// Remove all scheduled check-in notifications.
    func cancelDailyCheckIn() {
        center.removePendingNotificationRequests(withIdentifiers: [dailyCheckInIdentifier])
    }

    /// Enable or disable notifications based on the user's preference.
    func updateSchedule(enabled: Bool, preferredTime: DateComponents? = nil) {
        if enabled {
            Task {
                let granted = await requestAuthorization()
                if granted {
                    scheduleDailyCheckIn(preferredTime: preferredTime)
                }
            }
        } else {
            cancelDailyCheckIn()
        }
    }

    // MARK: - Anchor Moments

    func scheduleAnchorMoment(time: DateComponents? = nil) {
        center.removePendingNotificationRequests(withIdentifiers: [anchorMomentIdentifier])

        let hour = time?.hour ?? 9
        let minute = time?.minute ?? 0

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Anchor Moment")
        content.body = String(localized: "Take 30 seconds to breathe and reset.")
        content.sound = .default
        content.categoryIdentifier = "ANCHOR_MOMENT"
        content.userInfo = ["deepLink": "anchor://anchorMoment"]

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: anchorMomentIdentifier, content: content, trigger: trigger)

        center.add(request) { error in
            if let error {
                print("[NotificationManager] Failed to schedule anchor moment: \(error.localizedDescription)")
            }
        }
    }

    func cancelAnchorMoment() {
        center.removePendingNotificationRequests(withIdentifiers: [anchorMomentIdentifier])
    }

    func updateAnchorMomentSchedule(enabled: Bool, time: DateComponents? = nil) {
        if enabled {
            Task {
                let granted = await requestAuthorization()
                if granted {
                    scheduleAnchorMoment(time: time)
                }
            }
        } else {
            cancelAnchorMoment()
        }
    }

    // MARK: - Weekly Share Reminder

    func scheduleWeeklyShareReminder(time: DateComponents? = nil) {
        center.removePendingNotificationRequests(withIdentifiers: [weeklyShareIdentifier])

        let hour = time?.hour ?? 18
        let minute = time?.minute ?? 0

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Share your weekly check-in")
        content.body = String(localized: "Send a quick mood summary to someone you trust.")
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_SHARE"
        content.userInfo = ["deepLink": "anchor://settings"]

        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: weeklyShareIdentifier, content: content, trigger: trigger)

        center.add(request) { error in
            if let error {
                print("[NotificationManager] Failed to schedule weekly share: \(error.localizedDescription)")
            }
        }
    }

    func cancelWeeklyShareReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [weeklyShareIdentifier])
    }

    func updateWeeklyShareSchedule(enabled: Bool, time: DateComponents? = nil) {
        if enabled {
            Task {
                let granted = await requestAuthorization()
                if granted {
                    scheduleWeeklyShareReminder(time: time)
                }
            }
        } else {
            cancelWeeklyShareReminder()
        }
    }
}
