//
//  HomeView.swift
//  Anchor
//
//  Created for Anchor - AI-Powered Emotional Support
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @Query(sort: \Session.timestamp, order: .reverse) private var recentSessions: [Session]
    
    @State private var showingConversation = false
    @State private var showingSafetyDisclaimer = false
    
    private var userSettings: UserSettings? {
        settings.first
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Welcome Header
                VStack(spacing: 8) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue.gradient)
                    
                    Text("Welcome to Anchor")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Your private emotional support companion")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Main Action Button
                Button(action: startConversation) {
                    VStack(spacing: 12) {
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: 50))
                        
                        Text("Start Conversation")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(Color.blue.gradient)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
                .padding(.horizontal, 40)
                
                // Quick Stats
                if let settings = userSettings {
                    VStack(spacing: 8) {
                        if settings.isInTrialPeriod, let daysRemaining = settings.trialDaysRemaining {
                            Text("\(daysRemaining) days left in trial")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        if settings.totalSessions > 0 {
                            Text("\(settings.totalSessions) sessions completed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Recent Sessions Preview
                if !recentSessions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Sessions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(recentSessions.prefix(3)) { session in
                            SessionRowView(session: session)
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: HistoryView()) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            .sheet(isPresented: $showingConversation) {
                ConversationView()
            }
            .sheet(isPresented: $showingSafetyDisclaimer) {
                SafetyDisclaimerView(isPresented: $showingSafetyDisclaimer)
            }
            .onAppear {
                initializeUserSettings()
                checkSafetyDisclaimer()
            }
        }
    }
    
    private func startConversation() {
        // Check if user has seen safety disclaimer
        if let settings = userSettings, !settings.hasSeenSafetyDisclaimer {
            showingSafetyDisclaimer = true
        } else {
            showingConversation = true
        }
    }
    
    private func initializeUserSettings() {
        if settings.isEmpty {
            let newSettings = UserSettings()
            modelContext.insert(newSettings)
            try? modelContext.save()
        }
    }
    
    private func checkSafetyDisclaimer() {
        if let settings = userSettings, !settings.hasSeenSafetyDisclaimer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingSafetyDisclaimer = true
            }
        }
    }
}

struct SessionRowView: View {
    let session: Session
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.timestamp, style: .date)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(session.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if session.completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Session.self, UserSettings.self], inMemory: true)
}
