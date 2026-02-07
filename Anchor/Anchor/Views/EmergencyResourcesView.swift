//
//  EmergencyResourcesView.swift
//  Anchor
//
//  Created for Anchor - AI-Powered Emotional Support
//

import SwiftUI

struct EmergencyResourcesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.red.gradient)
                        
                        Text("You Are Not Alone")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Help is available 24/7")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    
                    // Immediate Crisis
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Immediate Crisis")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        EmergencyResourceCard(
                            icon: "phone.fill",
                            name: "Suicide & Crisis Lifeline",
                            contact: "988",
                            description: "24/7 free and confidential support",
                            actionText: "Call 988",
                            action: { callNumber("988") }
                        )
                        
                        EmergencyResourceCard(
                            icon: "message.fill",
                            name: "Crisis Text Line",
                            contact: "Text HOME to 741741",
                            description: "24/7 text-based crisis support",
                            actionText: "Send Text",
                            action: { sendText("741741", message: "HOME") }
                        )
                        
                        EmergencyResourceCard(
                            icon: "exclamationmark.triangle.fill",
                            name: "Emergency Services",
                            contact: "911",
                            description: "For immediate life-threatening emergencies",
                            actionText: "Call 911",
                            color: .red,
                            action: { callNumber("911") }
                        )
                    }
                    
                    // Additional Support
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Additional Support")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        SupportResourceCard(
                            name: "SAMHSA National Helpline",
                            description: "Treatment referral and information service",
                            contact: "1-800-662-4357"
                        )
                        
                        SupportResourceCard(
                            name: "Veterans Crisis Line",
                            description: "Support for veterans and their families",
                            contact: "1-800-273-8255 (Press 1)"
                        )
                        
                        SupportResourceCard(
                            name: "LGBTQ+ Support - Trevor Project",
                            description: "Crisis support for LGBTQ+ young people",
                            contact: "1-866-488-7386"
                        )
                        
                        SupportResourceCard(
                            name: "Disaster Distress Helpline",
                            description: "For those affected by disasters",
                            contact: "1-800-985-5990"
                        )
                    }
                    
                    // International Resources
                    VStack(alignment: .leading, spacing: 12) {
                        Text("International Resources")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Button(action: {
                            if let url = URL(string: "https://findahelpline.com") {
                                openURL(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "globe")
                                VStack(alignment: .leading) {
                                    Text("Find a Helpline")
                                        .fontWeight(.medium)
                                    Text("Crisis support worldwide")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Important Note
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Important")
                            .font(.headline)
                        
                        Text("If you are in immediate danger, please call emergency services (911 in the US) or go to your nearest emergency room.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Emergency Resources")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func callNumber(_ number: String) {
        let cleanNumber = number.replacingOccurrences(of: " ", with: "")
        if let url = URL(string: "tel://\(cleanNumber)") {
            openURL(url)
        }
    }
    
    private func sendText(_ number: String, message: String) {
        if let url = URL(string: "sms:\(number)&body=\(message)") {
            openURL(url)
        }
    }
}

struct EmergencyResourceCard: View {
    let icon: String
    let name: String
    let contact: String
    let description: String
    let actionText: String
    var color: Color = .blue
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)
                    
                    Text(contact)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: action) {
                Text(actionText)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(color.gradient)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SupportResourceCard: View {
    let name: String
    let description: String
    let contact: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.headline)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(contact)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    EmergencyResourcesView()
}
