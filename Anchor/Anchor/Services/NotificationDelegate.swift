//
//  NotificationDelegate.swift
//  Anchor
//
//  Handles notification taps and foreground presentation.
//

import Foundation
import UserNotifications
import UIKit

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }
        guard let link = response.notification.request.content.userInfo["deepLink"] as? String,
              let url = URL(string: link) else {
            return
        }
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
    }
}
