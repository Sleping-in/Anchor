//
//  STTDiagnostics.swift
//  Anchor
//
//  Real-time STT quality monitoring and diagnostics.
//

import Foundation

/// Tracks STT system performance for debugging and quality assurance.
actor STTDiagnostics {
    static let shared = STTDiagnostics()
    
    // MARK: - Counters
    
    private(set) var totalLocalTranscriptions: Int = 0
    private(set) var totalServerTranscriptions: Int = 0
    private(set) var echoFalsePositives: Int = 0
    private(set) var bargeInAttempts: Int = 0
    private(set) var bargeInSuccesses: Int = 0
    private(set) var localSTTTimeouts: Int = 0
    private(set) var noiseCalibrationsCompleted: Int = 0
    
    // MARK: - Quality Metrics
    
    private(set) var localServerAgreementCount: Int = 0
    private(set) var localServerDisagreementCount: Int = 0
    private var transcriptionLatencies: [TimeInterval] = []
    private var recentTranscriptions: [(local: String, server: String, timestamp: Date)] = []
    private let maxStoredTranscriptions = 10
    
    // MARK: - Current Session State
    
    private(set) var isEchoSuppressionActive: Bool = false
    private(set) var currentAmbientNoiseFloor: Float = 0
    private(set) var currentBargeInThreshold: Float = 0.06
    private(set) var lastLocalTranscript: String = ""
    private(set) var lastServerTranscript: String = ""
    
    // MARK: - Preprocessing Metrics
    
    private(set) var totalAudioFramesProcessed: Int = 0
    private(set) var framesGatedByNoise: Int = 0
    private(set) var averagePreprocessingGain: Float = 1.0
    private var gainHistory: [Float] = []
    private let maxGainHistory = 100
    
    func recordPreprocessingMetrics(gainApplied: Float, wasGated: Bool) {
        totalAudioFramesProcessed += 1
        if wasGated {
            framesGatedByNoise += 1
        }
        
        gainHistory.append(gainApplied)
        if gainHistory.count > maxGainHistory {
            gainHistory.removeFirst()
        }
        
        // Update rolling average
        averagePreprocessingGain = gainHistory.reduce(0, +) / Float(gainHistory.count)
    }
    
    var noiseGateRate: Double {
        guard totalAudioFramesProcessed > 0 else { return 0 }
        return Double(framesGatedByNoise) / Double(totalAudioFramesProcessed)
    }
    
    // MARK: - Recording
    
    func recordLocalTranscription(_ text: String, isFinal: Bool) {
        totalLocalTranscriptions += 1
        if isFinal {
            lastLocalTranscript = text
        }
    }
    
    func recordServerTranscription(_ text: String, isFinal: Bool) {
        totalServerTranscriptions += 1
        if isFinal {
            lastServerTranscript = text
        }
    }
    
    func recordEchoFalsePositive(detectedText: String) {
        echoFalsePositives += 1
        print("[STTDiagnostics] ⚠️ Echo false positive detected: '\(detectedText)'")
    }
    
    func recordBargeInAttempt() {
        bargeInAttempts += 1
    }
    
    func recordBargeInSuccess() {
        bargeInSuccesses += 1
    }
    
    func recordLocalSTTTimeout() {
        localSTTTimeouts += 1
    }
    
    func recordNoiseCalibration(noiseFloor: Float, threshold: Float) {
        noiseCalibrationsCompleted += 1
        currentAmbientNoiseFloor = noiseFloor
        currentBargeInThreshold = threshold
    }
    
    func recordLatency(_ latency: TimeInterval) {
        transcriptionLatencies.append(latency)
        // Keep only recent latencies
        if transcriptionLatencies.count > 100 {
            transcriptionLatencies.removeFirst(transcriptionLatencies.count - 100)
        }
    }
    
    /// Compare local and server transcriptions to measure agreement
    func compareTranscriptions(local: String, server: String) {
        guard !local.isEmpty, !server.isEmpty else { return }
        
        // Simple similarity check (can be improved with Levenshtein distance)
        let localLower = local.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let serverLower = server.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        if localLower == serverLower {
            localServerAgreementCount += 1
        } else {
            localServerDisagreementCount += 1
        }
        
        // Store for analysis
        recentTranscriptions.append((local: local, server: server, timestamp: Date()))
        if recentTranscriptions.count > maxStoredTranscriptions {
            recentTranscriptions.removeFirst()
        }
    }
    
    func setEchoSuppressionState(_ active: Bool) {
        isEchoSuppressionActive = active
    }
    
    // MARK: - Queries
    
    var bargeInSuccessRate: Double {
        guard bargeInAttempts > 0 else { return 0 }
        return Double(bargeInSuccesses) / Double(bargeInAttempts)
    }
    
    var localServerAgreementRate: Double {
        let total = localServerAgreementCount + localServerDisagreementCount
        guard total > 0 else { return 0 }
        return Double(localServerAgreementCount) / Double(total)
    }
    
    var averageLatency: TimeInterval {
        guard !transcriptionLatencies.isEmpty else { return 0 }
        return transcriptionLatencies.reduce(0, +) / Double(transcriptionLatencies.count)
    }
    
    func getReport() -> String {
        """
        STT Diagnostics Report:
        ======================
        Local Transcriptions: \(totalLocalTranscriptions)
        Server Transcriptions: \(totalServerTranscriptions)
        Echo False Positives: \(echoFalsePositives)
        
        Barge-in Success: \(bargeInSuccesses)/\(bargeInAttempts) (\(Int(bargeInSuccessRate * 100))%)
        Local/Server Agreement: \(localServerAgreementCount)/\(localServerAgreementCount + localServerDisagreementCount) (\(Int(localServerAgreementRate * 100))%)
        
        Average Latency: \(String(format: "%.2f", averageLatency * 1000))ms
        Noise Calibrations: \(noiseCalibrationsCompleted)
        Current Noise Floor: \(String(format: "%.4f", currentAmbientNoiseFloor))
        Current Barge Threshold: \(String(format: "%.4f", currentBargeInThreshold))
        
        Audio Preprocessing:
        - Frames Processed: \(totalAudioFramesProcessed)
        - Noise Gate Rate: \(Int(noiseGateRate * 100))%
        - Avg Gain: \(String(format: "%.2f", averagePreprocessingGain))x
        """
    }
    
    func reset() {
        totalLocalTranscriptions = 0
        totalServerTranscriptions = 0
        echoFalsePositives = 0
        bargeInAttempts = 0
        bargeInSuccesses = 0
        localSTTTimeouts = 0
        noiseCalibrationsCompleted = 0
        localServerAgreementCount = 0
        localServerDisagreementCount = 0
        transcriptionLatencies.removeAll()
        recentTranscriptions.removeAll()
        lastLocalTranscript = ""
        lastServerTranscript = ""
        totalAudioFramesProcessed = 0
        framesGatedByNoise = 0
        gainHistory.removeAll()
        averagePreprocessingGain = 1.0
    }
}

// MARK: - Debug Overlay View

#if DEBUG
import SwiftUI

struct STTDiagnosticsOverlay: View {
    @State private var report: String = "Loading..."
    @State private var timer: Timer?
    
    var body: some View {
        ScrollView {
            Text(report)
                .font(.system(size: 10, design: .monospaced))
                .padding(8)
        }
        .background(Color.black.opacity(0.8))
        .foregroundColor(.green)
        .cornerRadius(8)
        .frame(width: 280, height: 200)
        .onAppear {
            updateReport()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                updateReport()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func updateReport() {
        Task {
            let diagReport = await STTDiagnostics.shared.getReport()
            await MainActor.run {
                report = diagReport
            }
        }
    }
}
#endif
