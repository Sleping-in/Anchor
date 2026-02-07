//
//  AnchorTests.swift
//  AnchorTests
//
//  Created by Mohammad Elhaj on 07/02/2026.
//

import Testing
import SwiftData
@testable import Anchor

struct AnchorTests {
    
    @Test func sessionModelCreation() async throws {
        // Test Session model initialization
        let session = Session(
            timestamp: Date(),
            duration: 300, // 5 minutes
            summary: "Test session",
            completed: true
        )
        
        #expect(session.duration == 300)
        #expect(session.completed == true)
        #expect(session.summary == "Test session")
        #expect(session.crisisDetected == false)
    }
    
    @Test func sessionDurationFormatting() async throws {
        // Test formatted duration
        let session = Session(duration: 95) // 1 min 35 sec
        let formatted = session.formattedDuration
        #expect(formatted == "1 min 35 sec")
        
        let shortSession = Session(duration: 45) // 45 sec
        #expect(shortSession.formattedDuration == "45 sec")
    }
    
    @Test func userSettingsInitialization() async throws {
        // Test UserSettings model
        let settings = UserSettings()
        
        #expect(settings.hasCompletedOnboarding == false)
        #expect(settings.hasSeenSafetyDisclaimer == false)
        #expect(settings.voiceSpeed == 1.0)
        #expect(settings.isSubscribed == false)
        #expect(settings.isInTrialPeriod == false)
        #expect(settings.totalSessions == 0)
    }
    
    @Test func trialPeriodTracking() async throws {
        // Test trial period logic
        let settings = UserSettings(
            isInTrialPeriod: true,
            trialStartDate: Date()
        )
        
        #expect(settings.isInTrialPeriod == true)
        #expect(settings.hasActiveAccess == true)
        
        let daysRemaining = settings.trialDaysRemaining
        #expect(daysRemaining != nil)
        #expect(daysRemaining! >= 0)
        #expect(daysRemaining! <= 7)
    }
    
    @Test func subscriptionStatus() async throws {
        // Test subscription active access
        let futureDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
        let settings = UserSettings(
            isSubscribed: true,
            subscriptionExpiryDate: futureDate
        )
        
        #expect(settings.hasActiveAccess == true)
        
        // Test expired subscription
        let pastDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())
        let expiredSettings = UserSettings(
            isSubscribed: true,
            subscriptionExpiryDate: pastDate
        )
        
        #expect(expiredSettings.hasActiveAccess == false)
    }

}
