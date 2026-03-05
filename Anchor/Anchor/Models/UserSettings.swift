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
    var liveActivityPrivateMode: Bool?
    var appLockEnabled: Bool?
    
    /// Subscription status
    var isSubscribed: Bool
    var subscriptionExpiryDate: Date?
    var isInTrialPeriod: Bool
    var trialStartDate: Date?
    
    /// App usage tracking (for user benefit, not analytics)
    var firstLaunchDate: Date
    var totalSessions: Int

    /// Age verification
    var dateOfBirth: Date?

    /// Onboarding profile
    var userName: String = ""
    var primaryConcerns: [String] = []
    var communicationStyle: String = "gentle"

    /// Conversation persona preference
    var conversationPersona: String = ConversationPersona.warmFriend.rawValue

    /// Free tier usage tracking (seconds per day)
    var dailyUsageSeconds: TimeInterval?
    var dailyUsageDate: Date?

    /// Streak tracking
    var currentStreak: Int = 0
    var lastSessionDate: Date?

    /// Learned daily check-in time
    var preferredCheckInHour: Int?
    var preferredCheckInMinute: Int?
    /// User override for daily check-in time
    var checkInTimeOverrideEnabled: Bool?

    /// Anchor Moment (daily calming micro-interaction)
    var anchorMomentsEnabled: Bool = false
    var anchorMomentHour: Int?
    var anchorMomentMinute: Int?

    /// Weekly sharing preference
    var weeklyShareEnabled: Bool = false
    var weeklyShareHour: Int?
    var weeklyShareMinute: Int?

    /// Rolling baseline for voice stress normalization
    var voiceStressBaseline: Double?
    var voiceStressBaselineCount: Int?
    
    init(
        hasCompletedOnboarding: Bool = false,
        hasSeenSafetyDisclaimer: Bool = false,
        notificationsEnabled: Bool = false,
        voiceSpeed: Double = 1.0,
        allowDataExport: Bool = true,
        liveActivityPrivateMode: Bool? = false,
        appLockEnabled: Bool? = false,
        isSubscribed: Bool = false,
        subscriptionExpiryDate: Date? = nil,
        isInTrialPeriod: Bool = false,
        trialStartDate: Date? = nil,
        firstLaunchDate: Date = Date(),
        totalSessions: Int = 0,
        dateOfBirth: Date? = nil,
        userName: String = "",
        primaryConcerns: [String] = [],
        communicationStyle: String = "gentle",
        conversationPersona: String = ConversationPersona.warmFriend.rawValue,
        dailyUsageSeconds: TimeInterval? = 0,
        dailyUsageDate: Date? = Date(),
        preferredCheckInHour: Int? = nil,
        preferredCheckInMinute: Int? = nil,
        checkInTimeOverrideEnabled: Bool? = nil,
        anchorMomentsEnabled: Bool = false,
        anchorMomentHour: Int? = nil,
        anchorMomentMinute: Int? = nil,
        weeklyShareEnabled: Bool = false,
        weeklyShareHour: Int? = nil,
        weeklyShareMinute: Int? = nil,
        voiceStressBaseline: Double? = nil,
        voiceStressBaselineCount: Int? = nil
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasSeenSafetyDisclaimer = hasSeenSafetyDisclaimer
        self.notificationsEnabled = notificationsEnabled
        self.voiceSpeed = voiceSpeed
        self.allowDataExport = allowDataExport
        self.liveActivityPrivateMode = liveActivityPrivateMode
        self.appLockEnabled = appLockEnabled
        self.isSubscribed = isSubscribed
        self.subscriptionExpiryDate = subscriptionExpiryDate
        self.isInTrialPeriod = isInTrialPeriod
        self.trialStartDate = trialStartDate
        self.firstLaunchDate = firstLaunchDate
        self.totalSessions = totalSessions
        self.dateOfBirth = dateOfBirth
        self.userName = userName
        self.primaryConcerns = primaryConcerns
        self.communicationStyle = communicationStyle
        self.conversationPersona = conversationPersona
        self.dailyUsageSeconds = dailyUsageSeconds
        self.dailyUsageDate = dailyUsageDate
        self.preferredCheckInHour = preferredCheckInHour
        self.preferredCheckInMinute = preferredCheckInMinute
        self.checkInTimeOverrideEnabled = checkInTimeOverrideEnabled
        self.anchorMomentsEnabled = anchorMomentsEnabled
        self.anchorMomentHour = anchorMomentHour
        self.anchorMomentMinute = anchorMomentMinute
        self.weeklyShareEnabled = weeklyShareEnabled
        self.weeklyShareHour = weeklyShareHour
        self.weeklyShareMinute = weeklyShareMinute
        self.voiceStressBaseline = voiceStressBaseline
        self.voiceStressBaselineCount = voiceStressBaselineCount
    }

    /// Update the rolling baseline used to normalize voice stress scores.
    /// Uses a damped exponential update to avoid outliers skewing calibration.
    func updateVoiceStressBaseline(with score: Double) {
        let clampedScore = max(0, min(100, score))
        let count = voiceStressBaselineCount ?? 0
        let current = voiceStressBaseline ?? clampedScore
        let newCount = count + 1

        let alpha: Double
        if count < 3 {
            alpha = 1.0 / Double(newCount)
        } else if count < 10 {
            alpha = 0.2
        } else {
            alpha = 0.1
        }

        let delta = clampedScore - current
        let cappedScore = current + max(-25, min(25, delta))
        let newMean = current + alpha * (cappedScore - current)

        voiceStressBaseline = newMean
        voiceStressBaselineCount = newCount
    }

    /// Baseline only becomes active after a few sessions to avoid early skew.
    var calibratedVoiceStressBaseline: Double? {
        guard let count = voiceStressBaselineCount, count >= 3 else { return nil }
        return voiceStressBaseline
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

    /// Whether the user has unlimited conversation time
    var hasUnlimitedAccess: Bool {
        hasActiveAccess
    }

    static let freeDailyLimitSeconds: TimeInterval = 10 * 60

    func refreshDailyUsageIfNeeded(now: Date = Date()) {
        guard let dailyUsageDate else {
            self.dailyUsageDate = now
            dailyUsageSeconds = 0
            return
        }
        if !Calendar.current.isDate(dailyUsageDate, inSameDayAs: now) {
            self.dailyUsageDate = now
            dailyUsageSeconds = 0
        }
    }

    func remainingFreeSeconds(now: Date = Date()) -> TimeInterval {
        refreshDailyUsageIfNeeded(now: now)
        let used = dailyUsageSeconds ?? 0
        return max(0, Self.freeDailyLimitSeconds - used)
    }

    func recordUsage(seconds: TimeInterval, now: Date = Date()) {
        guard seconds > 0 else { return }
        refreshDailyUsageIfNeeded(now: now)
        dailyUsageSeconds = (dailyUsageSeconds ?? 0) + seconds
    }

    /// Update check-in streak. Call once after a session completes.
    func recordSessionForStreak(now: Date = Date()) {
        let cal = Calendar.current
        if let last = lastSessionDate {
            if cal.isDate(last, inSameDayAs: now) {
                // Already counted today
                return
            } else if let yesterday = cal.date(byAdding: .day, value: -1, to: now),
                      cal.isDate(last, inSameDayAs: yesterday) {
                currentStreak += 1
            } else {
                // Streak broken
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }
        lastSessionDate = now
    }

    var preferredCheckInTime: DateComponents? {
        guard let hour = preferredCheckInHour else { return nil }
        let minute = preferredCheckInMinute ?? 0
        return DateComponents(hour: hour, minute: minute)
    }

    var preferredCheckInLabel: String? {
        guard let hour = preferredCheckInHour else { return nil }
        let minute = preferredCheckInMinute ?? 0
        return CheckInTimeEstimator.formatTime(hour: hour, minute: minute)
    }

    var isCheckInTimeOverridden: Bool {
        checkInTimeOverrideEnabled ?? false
    }

    var selectedPersona: ConversationPersona {
        ConversationPersona(rawValue: conversationPersona) ?? .warmFriend
    }

    var anchorMomentTime: DateComponents? {
        guard let hour = anchorMomentHour else { return nil }
        let minute = anchorMomentMinute ?? 0
        return DateComponents(hour: hour, minute: minute)
    }

    var anchorMomentLabel: String? {
        guard let hour = anchorMomentHour else { return nil }
        let minute = anchorMomentMinute ?? 0
        return CheckInTimeEstimator.formatTime(hour: hour, minute: minute)
    }

    var weeklyShareTime: DateComponents? {
        guard let hour = weeklyShareHour else { return nil }
        let minute = weeklyShareMinute ?? 0
        return DateComponents(hour: hour, minute: minute)
    }

    var weeklyShareLabel: String? {
        guard let hour = weeklyShareHour else { return nil }
        let minute = weeklyShareMinute ?? 0
        return CheckInTimeEstimator.formatTime(hour: hour, minute: minute)
    }
}
