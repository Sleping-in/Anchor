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

    private let region = CrisisRegion.current()
    @StateObject private var store = CrisisResourceStore()
    @State private var showingCallConfirmation = false
    @State private var pendingCallNumber: String?
    @State private var pendingCallName: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(AnchorTheme.Colors.crisisRed)
                            .accessibilityHidden(true)
                        
                        Text(String(localized: "You Are Not Alone"))
                            .font(AnchorTheme.Typography.title)
                            .anchorPrimaryText()
                        
                        Text(String(localized: "Help is available 24/7"))
                            .font(AnchorTheme.Typography.subheadline)
                            .anchorSecondaryText()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    
                    // Immediate Crisis
                    VStack(alignment: .leading, spacing: 16) {
                        Text(String(localized: "Immediate Crisis"))
                            .font(AnchorTheme.Typography.headline)
                            .anchorPrimaryText()

                        ForEach(store.immediate) { resource in
                            EmergencyResourceCard(
                                icon: icon(for: resource.action),
                                name: resource.name,
                                contact: resource.contact,
                                description: resource.description,
                                actionText: actionText(for: resource),
                                color: AnchorTheme.Colors.crisisRed,
                                action: { handle(resource.action, name: resource.name) }
                            )
                        }
                    }
                    
                    // Additional Support
                    VStack(alignment: .leading, spacing: 16) {
                        Text(String(localized: "Additional Support"))
                            .font(AnchorTheme.Typography.headline)
                            .anchorPrimaryText()

                        ForEach(store.additional) { resource in
                            Button {
                                handle(resource.action, name: resource.name)
                            } label: {
                                SupportResourceCard(
                                    name: resource.name,
                                    description: resource.description,
                                    contact: resource.contact
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(
                                String.localizedStringWithFormat(
                                    String(localized: "%@, %@"),
                                    resource.name,
                                    resource.contact
                                )
                            )
                            .accessibilityHint(String(localized: "Double tap to contact"))
                        }
                    }
                    
                    // International Resources
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "International Resources"))
                            .font(AnchorTheme.Typography.headline)
                            .anchorPrimaryText()
                        
                        Button(action: {
                            if let url = URL(string: "https://findahelpline.com") {
                                openURL(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "globe")
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading) {
                                    Text(String(localized: "Find a Helpline"))
                                        .font(AnchorTheme.Typography.subheadline)
                                        .anchorPrimaryText()
                                    Text(String(localized: "Crisis support worldwide"))
                                        .font(AnchorTheme.Typography.caption)
                                        .anchorSecondaryText()
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .accessibilityHidden(true)
                            }
                            .anchorCard()
                        }
                        .accessibilityLabel(String(localized: "Find a Helpline"))
                        .accessibilityHint(String(localized: "Open crisis support directory"))
                    }
                    
                    // Important Note
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "Important"))
                            .font(AnchorTheme.Typography.headline)
                            .anchorPrimaryText()
                        
                        Text(
                            String.localizedStringWithFormat(
                                String(localized: "If you are in immediate danger, please call emergency services (%@) or go to your nearest emergency room."),
                                region.emergencyNumber
                            )
                        )
                            .font(AnchorTheme.Typography.subheadline)
                            .anchorSecondaryText()
                    }
                    .anchorCard()
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 24)
                .padding(.vertical)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .navigationTitle(String(localized: "Emergency Resources"))
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
        .confirmationDialog(String(localized: "Place a call?"), isPresented: $showingCallConfirmation, titleVisibility: .visible) {
            if let number = pendingCallNumber {
                Button(String.localizedStringWithFormat(String(localized: "Call %@"), number)) {
                    callNumber(number)
                    pendingCallNumber = nil
                    pendingCallName = nil
                }
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            if let name = pendingCallName, let number = pendingCallNumber {
                Text(
                    String.localizedStringWithFormat(
                        String(localized: "Call %@ at %@?"),
                        name,
                        number
                    )
                )
            }
        }
        .task {
            await store.load(for: region)
        }
    }
    
    private func callNumber(_ number: String) {
        let allowed = CharacterSet(charactersIn: "+0123456789")
        let cleanNumber = number.unicodeScalars.filter { allowed.contains($0) }.map(String.init).joined()
        guard !cleanNumber.isEmpty else { return }
        if let url = URL(string: "tel://\(cleanNumber)") {
            openURL(url)
        }
    }
    
    private func sendText(_ number: String, message: String) {
        let allowed = CharacterSet(charactersIn: "+0123456789")
        let cleanNumber = number.unicodeScalars.filter { allowed.contains($0) }.map(String.init).joined()
        guard !cleanNumber.isEmpty else { return }
        var components = URLComponents()
        components.scheme = "sms"
        components.path = cleanNumber
        components.queryItems = [URLQueryItem(name: "body", value: message)]
        if let url = components.url {
            openURL(url)
        }
    }

    private func handle(_ action: CrisisAction, name: String?) {
        switch action {
        case .call(let number):
            pendingCallNumber = number
            pendingCallName = name
            showingCallConfirmation = true
        case .sms(let number, let message):
            sendText(number, message: message)
        case .url(let url):
            openURL(url)
        }
    }

    private func actionText(for resource: CrisisResource) -> String {
        switch resource.action {
        case .call(let number):
            return String.localizedStringWithFormat(String(localized: "Call %@"), number)
        case .sms:
            return String(localized: "Send Text")
        case .url:
            return String(localized: "Open")
        }
    }

    private func icon(for action: CrisisAction) -> String {
        switch action {
        case .call:
            return "phone.fill"
        case .sms:
            return "message.fill"
        case .url:
            return "globe"
        }
    }
}

struct EmergencyResourceCard: View {
    let icon: String
    let name: String
    let contact: String
    let description: String
    let actionText: String
    var color: Color = AnchorTheme.Colors.crisisRed
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(AnchorTheme.Typography.subheadline)
                        .anchorPrimaryText()
                    
                    Text(contact)
                        .font(AnchorTheme.Typography.headline)
                        .anchorPrimaryText()
                        .foregroundColor(color)
                    
                    Text(description)
                        .font(AnchorTheme.Typography.bodyText)
                        .anchorSecondaryText()
                }
            }
            
            Button(action: action) {
                Text(actionText)
                    .font(AnchorTheme.Typography.subheadline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AnchorPillButtonStyle(background: color, foreground: AnchorTheme.Colors.softParchment))
            .accessibilityLabel(actionText)
            .accessibilityHint(
                String.localizedStringWithFormat(
                    String(localized: "Double tap to %@"),
                    actionText
                )
            )
        }
        .anchorCard()
    }
}

struct SupportResourceCard: View {
    let name: String
    let description: String
    let contact: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(AnchorTheme.Typography.subheadline)
                .anchorPrimaryText()
            
            Text(description)
                .font(AnchorTheme.Typography.bodyText)
                .anchorSecondaryText()
            
            Text(contact)
                .font(AnchorTheme.Typography.subheadline)
                .anchorPrimaryText()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .anchorCard()
    }
}

#Preview {
    EmergencyResourcesView()
}
