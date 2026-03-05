//
//  WhisperKitTranscriber.swift
//  Anchor
//
//  WhisperKit-based local transcription with streaming support.
//  Requires: https://github.com/argmaxinc/WhisperKit
//

import AVFoundation
import Combine
import CoreML

#if canImport(WhisperKit)
import WhisperKit
#endif

/// WhisperKit-based transcriber for high-quality on-device STT
@available(iOS 17.0, *)
final class WhisperKitTranscriber: ObservableObject {
    
    @Published private(set) var transcript: String = ""
    @Published private(set) var isTyping = false
    @Published private(set) var error: Error?
    
    var onTranscription: ((String, Bool) -> Void)?
    
    #if canImport(WhisperKit)
    private var whisperKit: WhisperKit?
    #endif
    private var audioBuffer: [Float] = []
    private var transcriptionTask: Task<Void, Never>?
    private let sampleRate: Double = 16000
    
    /// Whether WhisperKit is available and initialized
    private(set) var isAvailable = false
    
    /// Model size to use - smaller = faster but less accurate
    var modelSize: String = "small"
    
    init() {
        // Check if WhisperKit is available at runtime
        #if canImport(WhisperKit)
        isAvailable = true
        #else
        isAvailable = false
        #endif
    }
    
    /// Initialize WhisperKit with the specified model
    func initialize() async throws {
        #if canImport(WhisperKit)
        guard isAvailable else {
            throw WhisperKitError.notAvailable
        }
        
        isTyping = true
        defer { isTyping = false }
        
        // Initialize WhisperKit with default compute options
        whisperKit = try await WhisperKit(
            model: modelSize,
            computeOptions: ModelComputeOptions(
                audioEncoderCompute: .cpuAndNeuralEngine,
                textDecoderCompute: .cpuAndNeuralEngine
            ),
            verbose: false
        )
        
        isAvailable = whisperKit != nil
        #else
        throw WhisperKitError.notAvailable
        #endif
    }
    
    /// Start transcription from audio buffer
    func start() throws {
        #if canImport(WhisperKit)
        guard isAvailable, whisperKit != nil else {
            throw WhisperKitError.notInitialized
        }
        
        // Reset state
        audioBuffer.removeAll()
        transcript = ""
        error = nil
        isTyping = true
        
        #else
        throw WhisperKitError.notAvailable
        #endif
    }
    
    /// Append audio buffer (16kHz, mono, Float32)
    func append(_ buffer: AVAudioPCMBuffer) {
        #if canImport(WhisperKit)
        guard isAvailable else { return }
        
        // Convert buffer to float array
        let channelData = buffer.floatChannelData?[0]
        let frameLength = Int(buffer.frameLength)
        
        guard let data = channelData else { return }
        
        let samples = Array(UnsafeBufferPointer(start: data, count: frameLength))
        audioBuffer.append(contentsOf: samples)
        
        // Process in chunks of ~3 seconds
        let samplesPerChunk = Int(sampleRate * 3)
        if audioBuffer.count >= samplesPerChunk {
            let chunk = Array(audioBuffer.prefix(samplesPerChunk))
            audioBuffer.removeFirst(samplesPerChunk)
            processAudioChunk(chunk, isFinal: false)
        }
        #endif
    }
    
    #if canImport(WhisperKit)
    private func processAudioChunk(_ samples: [Float], isFinal: Bool) {
        transcriptionTask?.cancel()
        
        transcriptionTask = Task { [weak self] in
            guard let self = self else { return }
            
            do {
                // Use WhisperKit's transcribe method with simplified options
                let result = try await self.whisperKit?.transcribe(
                    audioArray: samples
                )
                
                guard let text = result?.first?.text, !text.isEmpty else { return }
                
                // Fix WhisperKit spacing issues then apply vocabulary corrections
                let fixedText = Self.fixWhisperSpacing(text)
                let processedText = STTVocabulary.shared.postProcessTranscription(fixedText)
                
                await MainActor.run {
                    guard !Task.isCancelled else { return }
                    self.transcript = processedText
                    self.onTranscription?(processedText, isFinal)
                }
                
                await STTDiagnostics.shared.recordLocalTranscription(processedText, isFinal: isFinal)
                
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }
    #endif
    
    /// Stop and finalize transcription
    func stop() {
        #if canImport(WhisperKit)
        isTyping = false
        
        // Process any remaining audio
        guard !audioBuffer.isEmpty else {
            finalizeTranscription()
            return
        }
        
        let remainingSamples = audioBuffer
        audioBuffer.removeAll()
        
        transcriptionTask?.cancel()
        transcriptionTask = Task { [weak self] in
            guard let self = self else { return }
            
            do {
                let result = try await self.whisperKit?.transcribe(
                    audioArray: remainingSamples
                )
                
                let text = result?.first?.text ?? ""
                let fixedText = Self.fixWhisperSpacing(text)
                let processedText = STTVocabulary.shared.postProcessTranscription(fixedText)
                
                await MainActor.run {
                    guard !Task.isCancelled else { return }
                    self.transcript = processedText
                    self.onTranscription?(processedText, true)
                }
                
                await STTDiagnostics.shared.recordLocalTranscription(processedText, isFinal: true)
                
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
        }
        #endif
    }
    
    /// Cancel current transcription
    func cancel() {
        #if canImport(WhisperKit)
        transcriptionTask?.cancel()
        transcriptionTask = nil
        audioBuffer.removeAll()
        isTyping = false
        transcript = ""
        #endif
    }
    
    private func finalizeTranscription() {
        #if canImport(WhisperKit)
        onTranscription?(transcript, true)
        #endif
    }
    
    /// Fixes WhisperKit's tendency to insert spaces within words
    /// e.g., "ab solu tely" -> "absolutely", "che cking" -> "checking"
    static func fixWhisperSpacing(_ text: String) -> String {
        // Strategy: Look for patterns of short word segments (2-4 chars) 
        // separated by spaces that should form a single word
        
        // Common patterns that Whisper splits
        let splitPatterns: [(pattern: String, replacement: String)] = [
            // Specific common splits seen in testing
            (#"\bab\s+so\s+lu\s+tely\b"#, "absolutely"),
            (#"\bha\s+te\b"#, "hate"),
            (#"\btran\s+scrip\s+tion\b"#, "transcription"),
            (#"\bta\s+ken\b"#, "taken"),
            (#"\bche\s+cking\b"#, "checking"),
            (#"\bsolu\s+tely\b"#, "olutely"), // partial
            (#"\bscrip\s+tion\b"#, "scription"), // partial
            
            // General patterns for common suffixes
            (#"\b([a-zA-Z]+)\s+ing\b"#, "$1ing"),  // e.g., "che cking" -> "checking"
            (#"\b([a-zA-Z]+)\s+ly\b"#, "$1ly"),    // e.g., "abso lutely" -> "absolutely"
            (#"\b([a-zA-Z]+)\s+tion\b"#, "$1tion"), // e.g., "transcrip tion" -> "transcription"
            (#"\b([a-zA-Z]+)\s+ment\b"#, "$1ment"), // e.g., "move ment" -> "movement"
            (#"\b([a-zA-Z]+)\s+ness\b"#, "$1ness"), // e.g., "happy ness" -> "happiness"
        ]
        
        var result = text
        
        // Apply specific patterns first
        for (pattern, replacement) in splitPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(result.startIndex..., in: result)
                result = regex.stringByReplacingMatches(
                    in: result,
                    options: [],
                    range: range,
                    withTemplate: replacement
                )
            }
        }
        
        // Aggressive fix: Join any 2-3 consecutive short words (2-4 chars each) into one
        // This is more aggressive but handles cases we haven't seen before
        let aggressivePattern = #"\b([a-z]{2,4})\s+([a-z]{2,4})\s+([a-z]{2,4})\b"#
        if let regex = try? NSRegularExpression(pattern: aggressivePattern, options: .caseInsensitive) {
            let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))
            
            // Process in reverse to maintain string indices
            for match in matches.reversed() {
                guard let range = Range(match.range, in: result) else { continue }
                let matched = String(result[range])
                let joined = matched.replacingOccurrences(of: " ", with: "")
                
                // Only join if the result looks like a reasonable word
                if joined.count >= 6 && joined.count <= 15 {
                    // Check it has vowels and doesn't have too many consonants in a row
                    if hasValidWordStructure(joined) {
                        result.replaceSubrange(range, with: joined)
                    }
                }
            }
        }
        
        // Fix 2-word splits that form common words
        let twoWordPattern = #"\b([a-z]{2,5})\s+([a-z]{3,7})\b"#
        if let regex = try? NSRegularExpression(pattern: twoWordPattern, options: .caseInsensitive) {
            let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))
            
            for match in matches.reversed() {
                guard let range = Range(match.range, in: result) else { continue }
                let matched = String(result[range])
                let joined = matched.replacingOccurrences(of: " ", with: "")
                
                // Join if it's a known common word or passes heuristics
                if isCommonWord(joined) || (joined.count >= 5 && hasValidWordStructure(joined)) {
                    result.replaceSubrange(range, with: joined)
                }
            }
        }
        
        return result
    }
    
    private static func hasValidWordStructure(_ word: String) -> Bool {
        let lowercased = word.lowercased()
        
        // Must have at least one vowel
        let vowelSet = Set("aeiouy")
        guard lowercased.contains(where: { vowelSet.contains($0) }) else { return false }
        
        // No more than 4 consonants in a row
        let vowels = CharacterSet(charactersIn: "aeiouy")
        var consecutiveConsonants = 0
        for scalar in lowercased.unicodeScalars {
            if !vowels.contains(scalar) {
                consecutiveConsonants += 1
                if consecutiveConsonants > 4 { return false }
            } else {
                consecutiveConsonants = 0
            }
        }
        
        return true
    }
    
    private static func isCommonWord(_ word: String) -> Bool {
        let commonWords: Set<String> = [
            "absolutely", "hate", "transcription", "checking", "taking",
            "working", "thinking", "feeling", "talking", "walking",
            "looking", "making", "giving", "having", "going",
            "coming", "doing", "saying", "getting", "knowing",
            "seeing", "finding", "trying", "using", "nothing",
            "everything", "something", "anything", "someone",
            "however", "although", "because", "another", "through",
            "problem", "question", "answer", "person", "people",
            "morning", "evening", "probably", "definitely",
            "understand", "remember", "experience"
        ]
        return commonWords.contains(word.lowercased())
    }
    
    enum WhisperKitError: LocalizedError {
        case notAvailable
        case notInitialized
        case modelDownloadFailed
        
        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "WhisperKit is not available. Check Package Dependencies."
            case .notInitialized:
                return "WhisperKit not initialized. Call initialize() first."
            case .modelDownloadFailed:
                return "Failed to download Whisper model."
            }
        }
    }
}

// MARK: - Fallback for older iOS versions

@available(iOS, deprecated: 17.0, message: "Use WhisperKitTranscriber on iOS 17+")
final class WhisperKitFallbackTranscriber: ObservableObject {
    @Published var transcript: String = ""
    @Published var isTyping = false
    @Published var error: Error?
    
    var onTranscription: ((String, Bool) -> Void)?
    
    var isAvailable: Bool { false }
    
    func initialize() async throws {
        throw NSError(domain: "WhisperKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "iOS 17+ required"])
    }
    
    func start() throws {}
    func append(_ buffer: AVAudioPCMBuffer) {}
    func stop() {}
    func cancel() {}
}
