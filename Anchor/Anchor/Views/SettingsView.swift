//
//  SettingsView.swift
//  Anchor
//
//  Created for Anchor - AI-Powered Emotional Support
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @State private var showingSubscriptionSheet = false
    @State private var showingSafetyResources = false
    
    private var userSettings: UserSettings? {
        settings.first
    }
    
    var body: some View {
        List {
            // Subscription Section
            Section {
                if let settings = userSettings {
                    if settings.isInTrialPeriod {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Free Trial")
                                .font(.headline)
                            
                            if let daysRemaining = settings.trialDaysRemaining {
                                Text("\(daysRemaining) days remaining")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else if settings.isSubscribed {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Premium")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                            
                            if let expiry = settings.subscriptionExpiryDate {
                                Text("Renews \(expiry, style: .date)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No Active Subscription")
                                .font(.headline)
                            
                            Text("Subscribe to continue using Anchor")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Button(action: { showingSubscriptionSheet = true }) {
                    HStack {
                        Text("Manage Subscription")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Subscription")
            }
            
            // App Settings
            Section {
                if let settings = userSettings {
                    Toggle("Notifications", isOn: Binding(
                        get: { settings.notificationsEnabled },
                        set: { newValue in
                            settings.notificationsEnabled = newValue
                            try? modelContext.save()
                        }
                    ))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Voice Speed")
                            .font(.subheadline)
                        
                        Slider(
                            value: Binding(
                                get: { settings.voiceSpeed },
                                set: { newValue in
                                    settings.voiceSpeed = newValue
                                    try? modelContext.save()
                                }
                            ),
                            in: 0.5...2.0,
                            step: 0.1
                        )
                        
                        HStack {
                            Text("Slower")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1fx", settings.voiceSpeed))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Faster")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("Preferences")
            }
            
            // Privacy & Data
            Section {
                NavigationLink(destination: PrivacyPolicyView()) {
                    Label("Privacy Policy", systemImage: "hand.raised.fill")
                }
                
                Button(action: exportData) {
                    Label("Export My Data", systemImage: "square.and.arrow.up")
                }
                
                Button(role: .destructive, action: deleteAllData) {
                    Label("Delete All My Data", systemImage: "trash")
                }
            } header: {
                Text("Privacy & Data")
            } footer: {
                Text("All your data is stored locally on this device. Export or delete your data at any time.")
            }
            
            // Safety
            Section {
                Button(action: { showingSafetyResources = true }) {
                    Label("Emergency Resources", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                }
                
                NavigationLink(destination: SafetyGuidelinesView()) {
                    Label("Safety Guidelines", systemImage: "shield.fill")
                }
            } header: {
                Text("Safety")
            }
            
            // About
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                NavigationLink(destination: TermsOfServiceView()) {
                    Text("Terms of Service")
                }
                
                NavigationLink(destination: AboutView()) {
                    Text("About Anchor")
                }
                
                Link("Contact Support", destination: URL(string: "mailto:support@anchor-app.com")!)
            } header: {
                Text("About")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingSubscriptionSheet) {
            SubscriptionView()
        }
        .sheet(isPresented: $showingSafetyResources) {
            EmergencyResourcesView()
        }
    }
    
    private func exportData() {
        // TODO: Implement data export
        print("Export data")
    }
    
    private func deleteAllData() {
        // TODO: Show confirmation alert
        print("Delete all data")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .modelContainer(for: UserSettings.self, inMemory: true)
    }
}
