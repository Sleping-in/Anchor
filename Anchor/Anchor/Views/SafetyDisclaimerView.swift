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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.shield.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.orange.gradient)
                        
                        Text("Important Safety Information")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    
                    // Critical Disclaimers
                    DisclaimerSection(
                        icon: "stethoscope",
                        title: "Not a Replacement for Professional Care",
                        description: "Anchor is an AI-powered emotional support tool, NOT a medical device or replacement for professional mental health care, therapy, or medical advice."
                    )
                    
                    DisclaimerSection(
                        icon: "exclamationmark.triangle.fill",
                        title: "Emergency Situations",
                        description: "If you are experiencing a mental health crisis, having thoughts of suicide or self-harm, or are in immediate danger, please contact emergency services immediately."
                    )
                    
                    DisclaimerSection(
                        icon: "lock.shield.fill",
                        title: "Your Privacy Matters",
                        description: "All conversations are stored locally on your device and encrypted. We never upload your conversations to the cloud or share them with third parties."
                    )
                    
                    DisclaimerSection(
                        icon: "person.fill.checkmark",
                        title: "For Adults Only",
                        description: "Anchor is designed for adults (18+) with mild-to-moderate mental health challenges. It is not suitable for children or adolescents."
                    )
                    
                    // Emergency Resources
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Emergency Resources")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            EmergencyResourceRow(
                                service: "Suicide & Crisis Lifeline",
                                contact: "988",
                                description: "24/7 support in the US"
                            )
                            
                            EmergencyResourceRow(
                                service: "Crisis Text Line",
                                contact: "Text HOME to 741741",
                                description: "24/7 text support"
                            )
                            
                            EmergencyResourceRow(
                                service: "Emergency Services",
                                contact: "911",
                                description: "For immediate danger"
                            )
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Agreement
                    VStack(spacing: 16) {
                        Text("By continuing, you acknowledge that:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint(text: "You are 18 years or older")
                            BulletPoint(text: "You understand this is not professional medical care")
                            BulletPoint(text: "You will seek professional help if needed")
                            BulletPoint(text: "You will contact emergency services in crisis situations")
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Accept Button
                    Button(action: acceptDisclaimer) {
                        Text("I Understand and Accept")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.gradient)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.vertical)
                }
                .padding()
            }
            .navigationTitle("Safety First")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func acceptDisclaimer() {
        if let settings = settings.first {
            settings.hasSeenSafetyDisclaimer = true
            try? modelContext.save()
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
                .foregroundColor(.orange)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(contact)
                .font(.headline)
                .foregroundColor(.blue)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.headline)
            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    SafetyDisclaimerView(isPresented: .constant(true))
        .modelContainer(for: UserSettings.self, inMemory: true)
}
