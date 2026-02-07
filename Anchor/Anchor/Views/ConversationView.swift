//
//  ConversationView.swift
//  Anchor
//
//  Created for Anchor - AI-Powered Emotional Support
//

import SwiftUI

struct ConversationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isRecording = false
    @State private var conversationStartTime = Date()
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // AI Status Indicator
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.red.opacity(0.2) : Color.blue.opacity(0.2))
                            .frame(width: 200, height: 200)
                            .scaleEffect(isRecording ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isRecording)
                        
                        Image(systemName: isRecording ? "waveform.circle.fill" : "mic.circle.fill")
                            .font(.system(size: 100))
                            .foregroundStyle(isRecording ? .red.gradient : .blue.gradient)
                    }
                    
                    Text(isRecording ? "Listening..." : "Tap to start")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if isRecording {
                        Text(formattedElapsedTime)
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                }
                
                Spacer()
                
                // Transcript/Messages Area (Placeholder)
                VStack(alignment: .leading, spacing: 12) {
                    if isRecording {
                        MessageBubble(text: "I'm here to listen. How are you feeling today?", isUser: false)
                        MessageBubble(text: "Thank you for asking...", isUser: true)
                    } else {
                        Text("Your conversation will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal)
                
                Spacer()
                
                // Control Buttons
                HStack(spacing: 32) {
                    // End Session Button
                    Button(action: endConversation) {
                        VStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 40))
                            Text("End")
                                .font(.caption)
                        }
                        .foregroundColor(.red)
                    }
                    
                    // Main Record Button
                    Button(action: toggleRecording) {
                        VStack(spacing: 8) {
                            Image(systemName: isRecording ? "pause.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 60))
                            Text(isRecording ? "Pause" : "Start")
                                .font(.subheadline)
                        }
                        .foregroundStyle(isRecording ? .orange.gradient : .blue.gradient)
                    }
                    
                    // Emergency Button
                    NavigationLink(destination: EmergencyResourcesView()) {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                            Text("Help")
                                .font(.caption)
                        }
                        .foregroundColor(.orange)
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Conversation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        endConversation()
                    }
                }
            }
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func toggleRecording() {
        isRecording.toggle()
        
        if isRecording {
            startTimer()
            // TODO: Start voice recording and AI processing
        } else {
            stopTimer()
            // TODO: Pause voice recording
        }
    }
    
    private func endConversation() {
        stopTimer()
        // TODO: Save session data
        dismiss()
    }
    
    private func startTimer() {
        conversationStartTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime = Date().timeIntervalSince(conversationStartTime)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private var formattedElapsedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct MessageBubble: View {
    let text: String
    let isUser: Bool
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            
            Text(text)
                .padding(12)
                .background(isUser ? Color.blue : Color(.systemGray5))
                .foregroundColor(isUser ? .white : .primary)
                .cornerRadius(16)
                .frame(maxWidth: 250, alignment: isUser ? .trailing : .leading)
            
            if !isUser { Spacer() }
        }
    }
}

#Preview {
    ConversationView()
}
