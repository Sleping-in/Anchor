//
//  SubscriptionView.swift
//  Anchor
//
//  Created for Anchor - AI-Powered Emotional Support
//

import SwiftUI
import SwiftData

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @State private var selectedPlan: SubscriptionPlan = .monthly
    
    private var userSettings: UserSettings? {
        settings.first
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 70))
                            .foregroundStyle(.blue.gradient)
                        
                        Text("Anchor Premium")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Unlimited emotional support")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(icon: "bubble.left.and.bubble.right.fill", text: "Unlimited conversations")
                        FeatureRow(icon: "lock.shield.fill", text: "Complete privacy & security")
                        FeatureRow(icon: "clock.fill", text: "24/7 availability")
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Track your emotional journey")
                        FeatureRow(icon: "sparkles", text: "Priority features & updates")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Plans
                    VStack(spacing: 16) {
                        PlanCard(
                            plan: .monthly,
                            isSelected: selectedPlan == .monthly,
                            action: { selectedPlan = .monthly }
                        )
                        
                        PlanCard(
                            plan: .annual,
                            isSelected: selectedPlan == .annual,
                            action: { selectedPlan = .annual }
                        )
                    }
                    .padding(.horizontal)
                    
                    // Trial Info
                    if let settings = userSettings, !settings.isInTrialPeriod && !settings.isSubscribed {
                        VStack(spacing: 8) {
                            Image(systemName: "gift.fill")
                                .font(.title)
                                .foregroundColor(.green)
                            
                            Text("Start with 7-day free trial")
                                .font(.headline)
                            
                            Text("No credit card required")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Subscribe Button
                    Button(action: subscribe) {
                        Text(subscribeButtonText)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.gradient)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Terms
                    VStack(spacing: 8) {
                        Text("Cancel anytime. No commitments.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Link("Terms of Service", destination: URL(string: "https://anchor-app.com/terms")!)
                            Text("•")
                            Link("Privacy Policy", destination: URL(string: "https://anchor-app.com/privacy")!)
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle("Subscription")
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
    
    private var subscribeButtonText: String {
        if let settings = userSettings {
            if settings.isSubscribed {
                return "Manage Subscription"
            } else if settings.isInTrialPeriod {
                return "Subscribe Now"
            } else {
                return "Start Free Trial"
            }
        }
        return "Subscribe"
    }
    
    private func subscribe() {
        // TODO: Implement StoreKit subscription flow
        // For now, just start a trial
        if let settings = userSettings, !settings.isInTrialPeriod && !settings.isSubscribed {
            settings.isInTrialPeriod = true
            settings.trialStartDate = Date()
            try? modelContext.save()
            dismiss()
        }
    }
}

enum SubscriptionPlan: String {
    case monthly = "Monthly"
    case annual = "Annual"
    
    var price: String {
        switch self {
        case .monthly: return "$9.99"
        case .annual: return "$79.99"
        }
    }
    
    var period: String {
        switch self {
        case .monthly: return "/month"
        case .annual: return "/year"
        }
    }
    
    var savings: String? {
        switch self {
        case .monthly: return nil
        case .annual: return "Save 33%"
        }
    }
    
    var pricePerMonth: String {
        switch self {
        case .monthly: return "$9.99/month"
        case .annual: return "$6.67/month"
        }
    }
}

struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(plan.rawValue)
                            .font(.headline)
                        
                        if let savings = plan.savings {
                            Text(savings)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.gradient)
                                .cornerRadius(8)
                        }
                    }
                    
                    Text(plan.pricePerMonth)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(plan.price)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(plan.period)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

#Preview {
    SubscriptionView()
        .modelContainer(for: UserSettings.self, inMemory: true)
}
