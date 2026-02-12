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
                            .foregroundColor(AnchorTheme.Colors.sageLeaf)
                            .accessibilityHidden(true)
                        
                        Text(String(localized: "Anchor Premium"))
                            .font(AnchorTheme.Typography.title)
                            .anchorPrimaryText()
                        
                        Text(String(localized: "Unlimited emotional support"))
                            .font(AnchorTheme.Typography.subheadline)
                            .anchorSecondaryText()
                    }
                    .padding(.top)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(icon: "bubble.left.and.bubble.right.fill", text: String(localized: "Unlimited conversations"))
                        FeatureRow(icon: "lock.shield.fill", text: String(localized: "Complete privacy & security"))
                        FeatureRow(icon: "clock.fill", text: String(localized: "24/7 availability"))
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", text: String(localized: "Track your emotional journey"))
                        FeatureRow(icon: "sparkles", text: String(localized: "Priority features & updates"))
                    }
                    .anchorCard()
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
                    
                    // Trial / Upgrade Info
                    if let settings = userSettings, !settings.isSubscribed {
                        VStack(spacing: 8) {
                            Image(systemName: settings.isInTrialPeriod ? "clock.fill" : "gift.fill")
                                .font(.title)
                                .foregroundColor(AnchorTheme.Colors.sageLeaf)
                                .accessibilityHidden(true)

                            Text(settings.isInTrialPeriod ? String(localized: "Trial in progress") : String(localized: "Start with 7-day free trial"))
                                .font(AnchorTheme.Typography.headline)
                                .anchorPrimaryText()

                            Text(settings.isInTrialPeriod
                                 ? String(localized: "Enjoy unlimited access during your trial.")
                                 : String(localized: "No credit card required"))
                                .font(AnchorTheme.Typography.subheadline)
                                .anchorSecondaryText()
                        }
                        .anchorCard()
                        .padding(.horizontal)
                    }
                    
                    // Subscribe Button
                    Button(action: subscribe) {
                        Text(subscribeButtonText)
                            .font(AnchorTheme.Typography.subheadline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AnchorPillButtonStyle(background: AnchorTheme.Colors.sageLeaf, foreground: AnchorTheme.Colors.softParchment))
                    .padding(.horizontal)
                    .accessibilityLabel(subscribeButtonText)
                    .accessibilityHint(String(localized: "Subscribe to Anchor Premium"))
                    .accessibilityIdentifier("subscription.subscribe")
                    
                    // Terms
                    VStack(spacing: 8) {
                        Text(String(localized: "Cancel anytime. No commitments."))
                            .font(AnchorTheme.Typography.caption)
                            .anchorSecondaryText()
                        
                        HStack(spacing: 4) {
                            Link(String(localized: "Terms of Service"), destination: URL(string: "https://anchor-app.com/terms")!)
                            Text(String(localized: "•"))
                            Link(String(localized: "Privacy Policy"), destination: URL(string: "https://anchor-app.com/privacy")!)
                        }
                        .font(AnchorTheme.Typography.caption)
                        .foregroundColor(AnchorTheme.Colors.quietInkSecondary)

                        Button(String(localized: "Restore Purchases")) {
                            restorePurchases()
                        }
                        .font(AnchorTheme.Typography.caption)
                        .foregroundColor(AnchorTheme.Colors.quietInkSecondary)
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle(String(localized: "Subscription"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "Done")) {
                        dismiss()
                    }
                }
            }
        }
        .anchorScreenBackground()
    }
    
    private var subscribeButtonText: String {
        if let settings = userSettings {
            if settings.isSubscribed {
                return String(localized: "Manage Subscription")
            } else if settings.isInTrialPeriod {
                return String(localized: "Subscribe Now")
            } else {
                return String(localized: "Start Free Trial")
            }
        }
        return String(localized: "Subscribe")
    }
    
    private func subscribe() {
        // PLACEHOLDER: StoreKit 2 integration pending — starts a local trial for now
        if let settings = userSettings, !settings.isInTrialPeriod && !settings.isSubscribed {
            settings.isInTrialPeriod = true
            settings.trialStartDate = Date()
            modelContext.safeSave()
            dismiss()
        }
    }

    private func restorePurchases() {
        // PLACEHOLDER: StoreKit 2 restore logic goes here.
        // For now, just dismiss to keep the flow responsive.
        dismiss()
    }
}

enum SubscriptionPlan: String {
    case monthly = "Monthly"
    case annual = "Annual"

    var displayName: String {
        String(localized: .init(rawValue))
    }
    
    var price: String {
        switch self {
        case .monthly: return String(localized: "$9.99")
        case .annual: return String(localized: "$79.99")
        }
    }
    
    var period: String {
        switch self {
        case .monthly: return String(localized: "/month")
        case .annual: return String(localized: "/year")
        }
    }
    
    var savings: String? {
        switch self {
        case .monthly: return nil
        case .annual: return String(localized: "Save 33%")
        }
    }
    
    var pricePerMonth: String {
        switch self {
        case .monthly: return String(localized: "$9.99/month")
        case .annual: return String(localized: "$6.67/month")
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
                        Text(plan.displayName)
                            .font(AnchorTheme.Typography.subheadline)
                            .anchorPrimaryText()
                        
                        if let savings = plan.savings {
                            Text(savings)
                                .font(AnchorTheme.Typography.caption)
                                .foregroundColor(AnchorTheme.Colors.quietInk)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AnchorTheme.Colors.warmSand.opacity(0.4))
                                .cornerRadius(8)
                        }
                    }
                    
                    Text(plan.pricePerMonth)
                        .font(AnchorTheme.Typography.caption)
                        .anchorSecondaryText()
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(plan.price)
                        .font(AnchorTheme.Typography.headline)
                        .anchorPrimaryText()
                    
                    Text(plan.period)
                        .font(AnchorTheme.Typography.caption)
                        .anchorSecondaryText()
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? AnchorTheme.Colors.sageLeaf : AnchorTheme.Colors.quietInkSecondary)
                    .accessibilityHidden(true)
            }
            .padding()
            .background(isSelected ? AnchorTheme.Colors.sageLeaf.opacity(0.12) : AnchorTheme.Colors.warmStone)
            .cornerRadius(AnchorTheme.Layout.cardRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AnchorTheme.Layout.cardRadius)
                    .stroke(isSelected ? AnchorTheme.Colors.sageLeaf.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel({
            let savingsText = plan.savings.map {
                String.localizedStringWithFormat(String(localized: ", %@"), $0)
            } ?? ""
            return String.localizedStringWithFormat(
                String(localized: "%@ plan, %@ %@, %@%@"),
                plan.displayName,
                plan.price,
                plan.period,
                plan.pricePerMonth,
                savingsText
            )
        }())
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint(isSelected ? String(localized: "Currently selected") : String(localized: "Double tap to select this plan"))
        .accessibilityIdentifier("subscription.plan.\(plan.rawValue.lowercased())")
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AnchorTheme.Colors.sageLeaf)
                .frame(width: 30)
                .accessibilityHidden(true)
            
            Text(text)
                .font(AnchorTheme.Typography.bodyText)
                .anchorPrimaryText()
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    SubscriptionView()
        .modelContainer(for: UserSettings.self, inMemory: true)
}
