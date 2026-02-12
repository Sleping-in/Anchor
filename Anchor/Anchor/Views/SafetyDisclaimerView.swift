//
//  SafetyDisclaimerView.swift
//  Anchor
//
//  Created for Anchor - AI-Powered Emotional Support
//

import SwiftUI
import SwiftData

struct SafetyDisclaimerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @Binding var isPresented: Bool

    private let region = CrisisRegion.current()
    @StateObject private var store = CrisisResourceStore()
    @State private var didLoadResources = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.shield.fill")
                            .font(.system(size: 60))
                            .foregroundColor(AnchorTheme.Colors.crisisRed)
                            .accessibilityHidden(true)
                        
                        Text(String(localized: "Important Safety Information"))
                            .font(AnchorTheme.Typography.title)
                            .anchorPrimaryText()
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    
                    // Critical Disclaimers
                    DisclaimerSection(
                        icon: "stethoscope",
                        title: String(localized: "Not a Replacement for Professional Care"),
                        description: String(localized: "Anchor is an AI-powered emotional support tool, NOT a medical device or replacement for professional mental health care, therapy, or medical advice.")
                    )
                    
                    DisclaimerSection(
                        icon: "exclamationmark.triangle.fill",
                        title: String(localized: "Emergency Situations"),
                        description: String(localized: "If you are experiencing a mental health crisis, having thoughts of suicide or self-harm, or are in immediate danger, please contact emergency services immediately.")
                    )
                    
                    DisclaimerSection(
                        icon: "lock.shield.fill",
                        title: String(localized: "Your Privacy Matters"),
                        description: String(localized: "All conversations are stored locally on your device and encrypted. We never upload your conversations to the cloud or share them with third parties.")
                    )
                    
                    DisclaimerSection(
                        icon: "person.fill.checkmark",
                        title: String(localized: "For Adults Only"),
                        description: String(localized: "Anchor is designed for adults (18+) with mild-to-moderate mental health challenges. It is not suitable for children or adolescents.")
                    )
                    
                    // Emergency Resources
                    VStack(alignment: .center, spacing: 12) {
                        Text(String(localized: "Emergency Resources"))
                            .font(AnchorTheme.Typography.headline)
                            .anchorPrimaryText()
                            .multilineTextAlignment(.center)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(store.immediate) { resource in
                                EmergencyResourceRow(
                                    service: resource.name,
                                    contact: resource.contact,
                                    description: resource.description
                                )
                            }
                        }
                        .anchorCard()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    // Agreement
                    VStack(spacing: 16) {
                        Text(String(localized: "By continuing, you acknowledge that:"))
                            .font(AnchorTheme.Typography.subheadline)
                            .anchorPrimaryText()
                            .multilineTextAlignment(.center)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint(text: String(localized: "You are 18 years or older"))
                            BulletPoint(text: String(localized: "You understand this is not professional medical care"))
                            BulletPoint(text: String(localized: "You will seek professional help if needed"))
                            BulletPoint(text: String(localized: "You will contact emergency services in crisis situations"))
                        }
                    }
                    .anchorCard()
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    // Accept Button
                    Button(action: acceptDisclaimer) {
                        Text(String(localized: "I Understand and Accept"))
                            .font(AnchorTheme.Typography.subheadline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AnchorPillButtonStyle(background: AnchorTheme.Colors.sageLeaf, foreground: AnchorTheme.Colors.softParchment))
                    .padding(.vertical)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityIdentifier("safety.accept")
                }
                .padding()
            }
            .navigationTitle(String(localized: "Safety First"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .anchorScreenBackground()
        .task {
            guard !didLoadResources else { return }
            didLoadResources = true
            await store.load(for: region)
        }
    }
    
    private func acceptDisclaimer() {
        if let settings = settings.first {
            settings.hasSeenSafetyDisclaimer = true
            modelContext.safeSave()
        }
        isPresented = false
    }
}

struct DisclaimerSection: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AnchorTheme.Colors.crisisRed)
                .frame(width: 30)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AnchorTheme.Typography.subheadline)
                    .anchorPrimaryText()
                
                Text(description)
                    .font(AnchorTheme.Typography.bodyText)
                    .anchorSecondaryText()
            }
        }
    }
}

struct EmergencyResourceRow: View {
    let service: String
    let contact: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(service)
                .font(AnchorTheme.Typography.subheadline)
                .anchorPrimaryText()
            
            Text(contact)
                .font(AnchorTheme.Typography.headline)
                .foregroundColor(AnchorTheme.Colors.crisisRed)
            
            Text(description)
                .font(AnchorTheme.Typography.caption)
                .anchorSecondaryText()
        }
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(String(localized: "•"))
                .font(AnchorTheme.Typography.subheadline)
                .anchorSecondaryText()
            Text(text)
                .font(AnchorTheme.Typography.bodyText)
                .anchorPrimaryText()
        }
    }
}

#Preview {
    SafetyDisclaimerView(isPresented: .constant(true))
        .modelContainer(for: UserSettings.self, inMemory: true)
}
