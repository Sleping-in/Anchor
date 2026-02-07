//
//  SupportViews.swift
//  Anchor
//
//  Created for Anchor - AI-Powered Emotional Support
//  Placeholder views for Terms, Privacy, Safety, and About
//

import SwiftUI

// MARK: - Privacy Policy View
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Last Updated: February 7, 2026")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                PolicySection(
                    title: "Your Privacy Matters",
                    content: "At Anchor, we take your privacy seriously. All your conversations are stored locally on your device and are never uploaded to the cloud."
                )
                
                PolicySection(
                    title: "Data Collection",
                    content: "We collect minimal data:\n• Conversation history (stored locally)\n• User preferences (stored locally)\n• Anonymous usage analytics (optional)"
                )
                
                PolicySection(
                    title: "Data Storage",
                    content: "All personal data is encrypted and stored only on your device. We cannot access your conversations or personal information."
                )
                
                PolicySection(
                    title: "Third-Party Services",
                    content: "We use AI services for conversation processing. Only anonymous conversation text is sent to our AI provider, never any identifying information."
                )
                
                PolicySection(
                    title: "Your Rights",
                    content: "You have the right to:\n• Access your data\n• Export your data\n• Delete your data at any time"
                )
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Terms of Service View
struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Service")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Last Updated: February 7, 2026")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                PolicySection(
                    title: "Acceptance of Terms",
                    content: "By using Anchor, you agree to these terms of service."
                )
                
                PolicySection(
                    title: "Service Description",
                    content: "Anchor provides AI-powered emotional support through voice conversations. It is NOT a replacement for professional mental health care."
                )
                
                PolicySection(
                    title: "Age Requirement",
                    content: "You must be 18 years or older to use Anchor."
                )
                
                PolicySection(
                    title: "Disclaimer",
                    content: "Anchor is not a medical device and does not provide medical advice, diagnosis, or treatment. Always seek the advice of a qualified healthcare provider."
                )
                
                PolicySection(
                    title: "Limitation of Liability",
                    content: "We are not liable for any decisions or actions taken based on conversations with Anchor."
                )
                
                PolicySection(
                    title: "Subscription Terms",
                    content: "Subscriptions auto-renew unless cancelled. You can cancel anytime through your App Store account settings."
                )
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Safety Guidelines View
struct SafetyGuidelinesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Safety Guidelines")
                    .font(.title)
                    .fontWeight(.bold)
                
                PolicySection(
                    title: "When to Use Anchor",
                    content: "Anchor is designed for:\n• Emotional support during stressful times\n• Processing daily challenges\n• Exploring feelings and emotions\n• General mental wellness"
                )
                
                PolicySection(
                    title: "When NOT to Use Anchor",
                    content: "Do NOT rely on Anchor for:\n• Medical emergencies\n• Crisis situations\n• Suicidal thoughts or self-harm urges\n• Severe mental health conditions"
                )
                
                PolicySection(
                    title: "Crisis Resources",
                    content: "If you're in crisis, contact:\n• 988 - Suicide & Crisis Lifeline\n• 911 - Emergency services\n• Crisis Text Line: Text HOME to 741741"
                )
                
                PolicySection(
                    title: "Seeking Professional Help",
                    content: "Consider professional help if you:\n• Have persistent symptoms\n• Feel unable to cope\n• Experience thoughts of self-harm\n• Need medication management"
                )
                
                PolicySection(
                    title: "Best Practices",
                    content: "• Use Anchor in a quiet, private space\n• Be honest about your feelings\n• Take breaks if needed\n• Seek professional care when appropriate"
                )
            }
            .padding()
        }
        .navigationTitle("Safety Guidelines")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - About View
struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue.gradient)
                    .padding()
                
                VStack(spacing: 8) {
                    Text("Anchor")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text("AI-Powered Emotional Support")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 16) {
                    PolicySection(
                        title: "Our Mission",
                        content: "To provide accessible, private, and immediate emotional support to anyone who needs it, anytime."
                    )
                    
                    PolicySection(
                        title: "Our Values",
                        content: "• Privacy First\n• User Safety\n• Accessibility\n• Ethical AI\n• Compassionate Care"
                    )
                    
                    PolicySection(
                        title: "Contact Us",
                        content: "Email: support@anchor-app.com\n\nWe'd love to hear from you!"
                    )
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Helper Components
struct PolicySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            Text(content)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Previews
#Preview("Privacy Policy") {
    NavigationStack {
        PrivacyPolicyView()
    }
}

#Preview("Terms of Service") {
    NavigationStack {
        TermsOfServiceView()
    }
}

#Preview("Safety Guidelines") {
    NavigationStack {
        SafetyGuidelinesView()
    }
}

#Preview("About") {
    NavigationStack {
        AboutView()
    }
}
