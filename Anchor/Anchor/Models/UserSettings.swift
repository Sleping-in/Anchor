//
//  UserSettings.swift
//  Anchor
//
//  Created for Anchor - AI-Powered Emotional Support
//

import Foundation
import SwiftData

/// User preferences and settings
@Model
final class UserSettings {
    /// Has the user completed onboarding
    var hasCompletedOnboarding: Bool
    
    /// Has the user seen safety disclaimers
    var hasSeenSafetyDisclaimer: Bool
    
    /// Notification preferences
    var notificationsEnabled: Bool
    
    /// Voice preferences
    var voiceSpeed: Double // 0.5 to 2.0
    
    /// Privacy preferences
    var allowDataExport: Bool
    
    /// Subscription status
    var isSubscribed: Bool
    var subscriptionExpiryDate: Date?
    var isInTrialPeriod: Bool
    var trialStartDate: Date?
    
    /// App usage tracking (for user benefit, not analytics)
    var firstLaunchDate: Date
    var totalSessions: Int
    
    init(
        hasCompletedOnboarding: Bool = false,
        hasSeenSafetyDisclaimer: Bool = false,
        notificationsEnabled: Bool = false,
        voiceSpeed: Double = 1.0,
        allowDataExport: Bool = true,
        isSubscribed: Bool = false,
        subscriptionExpiryDate: Date? = nil,
        isInTrialPeriod: Bool = false,
        trialStartDate: Date? = nil,
        firstLaunchDate: Date = Date(),
        totalSessions: Int = 0
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasSeenSafetyDisclaimer = hasSeenSafetyDisclaimer
        self.notificationsEnabled = notificationsEnabled
        self.voiceSpeed = voiceSpeed
        self.allowDataExport = allowDataExport
        self.isSubscribed = isSubscribed
        self.subscriptionExpiryDate = subscriptionExpiryDate
        self.isInTrialPeriod = isInTrialPeriod
        self.trialStartDate = trialStartDate
        self.firstLaunchDate = firstLaunchDate
        self.totalSessions = totalSessions
    }
    
    /// Check if user has active access (trial or subscription)
    var hasActiveAccess: Bool {
        if isInTrialPeriod, let trialStart = trialStartDate {
            // 7-day trial
            let trialEnd = Calendar.current.date(byAdding: .day, value: 7, to: trialStart) ?? trialStart
            return Date() < trialEnd
        }
        
        if isSubscribed, let expiry = subscriptionExpiryDate {
            return Date() < expiry
        }
        
        return false
    }
    
    /// Days remaining in trial
    var trialDaysRemaining: Int? {
        guard isInTrialPeriod, let trialStart = trialStartDate else { return nil }
        let trialEnd = Calendar.current.date(byAdding: .day, value: 7, to: trialStart) ?? trialStart
        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: trialEnd).day ?? 0
        return max(0, daysRemaining)
    }
}
