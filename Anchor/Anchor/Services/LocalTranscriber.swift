//
//  LocalTranscriber.swift
//  Anchor
//
//  Local on-device speech transcription that runs in parallel with Gemini Live.
//  Supports: WhisperKit (iOS 17+), SpeechAnalyzer/SpeechTranscriber (iOS 26+),
//  and SFSpeechRecognizer fallback.
//

import AVFoundation
import Combine
import Speech

/// Transcribes user speech locally and streams partial/final text updates.
final class LocalTranscriber: NSObject, ObservableObject {

    // MARK: - Published State

    @Published private(set) var transcript: String = ""
    @Published private(set) var isTyping = false
    @Published private(set) var error: Error?

    // MARK: - Configuration

    /// Called with partial or final transcripts.
    /// (text, isFinal)
    var onTranscription: ((String, Bool) -> Void)?
    
    /// STT Engine selection
    enum STTEngine: String, CaseIterable, Identifiable {
        case whisperKit = "WhisperKit"
        case speechAnalyzer = "SpeechAnalyzer"
        case sfSpeechRecognizer = "SFSpeechRecognizer"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .whisperKit:
                return "WhisperKit (Best Quality)"
            case .speechAnalyzer:
                return "Apple Speech (iOS 26+)"
            case .sfSpeechRecognizer:
                return "Apple Speech (Legacy)"
            }
        }
        
        var isAvailable: Bool {
            switch self {
            case .whisperKit:
                if #available(iOS 17.0, *) {
                    return WhisperKitTranscriber().isAvailable
                }
                return false
            case .speechAnalyzer:
                if #available(iOS 26.0, *) {
                    return SpeechTranscriber.isAvailable
                }
                return false
            case .sfSpeechRecognizer:
                return SFSpeechRecognizer(locale: Locale(identifier: "en-US"))?.isAvailable ?? false
            }
        }
    }
    
    /// Current STT engine - defaults to WhisperKit if available
    static var preferredEngine: STTEngine = {
        if STTEngine.whisperKit.isAvailable {
            return .whisperKit
        } else if STTEngine.speechAnalyzer.isAvailable {
            return .speechAnalyzer
        } else {
            return .sfSpeechRecognizer
        }
    }()

    private enum ActiveEngine {
        case whisperKit
        case speechAnalyzer
        case sfSpeechRecognizer
    }

    private var activeEngine: ActiveEngine = .sfSpeechRecognizer
    
    // MARK: - WhisperKit (iOS 17+)
    
    @available(iOS 17.0, *)
    private var whisperKitTranscriber: WhisperKitTranscriber?

    // MARK: - SpeechAnalyzer (iOS 26+)

    @available(iOS 26.0, *)
    private var analyzer: SpeechAnalyzer?
    @available(iOS 26.0, *)
    private var transcriber: SpeechTranscriber?
    @available(iOS 26.0, *)
    private var analyzerTask: Task<Void, Never>?
    @available(iOS 26.0, *)
    private var resultsTask: Task<Void, Never>?
    @available(iOS 26.0, *)
    private var analyzerInputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    @available(iOS 26.0, *)
    private var analyzerInputFormat: AVAudioFormat?
    @available(iOS 26.0, *)
    private var reservedAnalyzerLocale: Locale?
    @available(iOS 26.0, *)
    private let fallbackAnalyzerInputFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: 16_000,
        channels: 1,
        interleaved: false
    )!

    // MARK: - SFSpeechRecognizer fallback

    private let recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    override init() {
        self.recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        super.init()
        self.recognizer?.delegate = self
    }

    // MARK: - Public API
    
    /// Initialize the preferred STT engine (call before first use for WhisperKit)
    func initializePreferredEngine() async {
        switch Self.preferredEngine {
        case .whisperKit:
            if #available(iOS 17.0, *) {
                do {
                    let transcriber = WhisperKitTranscriber()
                    try await transcriber.initialize()
                    whisperKitTranscriber = transcriber
                } catch {
                    print("[LocalTranscriber] WhisperKit init failed: \(error)")
                    // Fall back to next available
                    if STTEngine.speechAnalyzer.isAvailable {
                        Self.preferredEngine = .speechAnalyzer
                    } else {
                        Self.preferredEngine = .sfSpeechRecognizer
                    }
                }
            }
        default:
            break
        }
    }

    /// Start recognizing speech.
    func start() throws {
        cancel()  // Reset any previous task.
        error = nil
        
        // Use preferred engine
        switch Self.preferredEngine {
        case .whisperKit:
            if #available(iOS 17.0, *) {
                try startWhisperKit()
            } else {
                try startSFSpeechRecognizer()
            }
        case .speechAnalyzer:
            if #available(iOS 26.0, *), SpeechTranscriber.isAvailable {
                startSpeechAnalyzer()
            } else {
                try startSFSpeechRecognizer()
            }
        case .sfSpeechRecognizer:
            try startSFSpeechRecognizer()
        }
    }

    /// Append an audio buffer to the active transcription engine.
    func append(_ buffer: AVAudioPCMBuffer) {
        switch activeEngine {
        case .whisperKit:
            if #available(iOS 17.0, *) {
                whisperKitTranscriber?.append(buffer)
            }
        case .speechAnalyzer:
            if #available(iOS 26.0, *) {
                appendToSpeechAnalyzer(buffer)
            }
        case .sfSpeechRecognizer:
            request?.append(buffer)
        }
    }

    /// Stop recognizing speech.
    func stop() {
        switch activeEngine {
        case .whisperKit:
            if #available(iOS 17.0, *) {
                whisperKitTranscriber?.stop()
            }
        case .speechAnalyzer:
            if #available(iOS 26.0, *) {
                stopSpeechAnalyzer()
            }
        case .sfSpeechRecognizer:
            request?.endAudio()
            request = nil
            task = nil
        }

        DispatchQueue.main.async {
            self.isTyping = false
        }
    }

    /// Cancel the current recognition task and clear transient state.
    func cancel() {
        stop()
        
        switch activeEngine {
        case .whisperKit:
            if #available(iOS 17.0, *) {
                whisperKitTranscriber?.cancel()
            }
        case .speechAnalyzer:
            if #available(iOS 26.0, *) {
                analyzerTask?.cancel()
                resultsTask?.cancel()
            }
        case .sfSpeechRecognizer:
            task?.cancel()
        }

        task = nil
        request = nil

        DispatchQueue.main.async {
            self.transcript = ""
            self.isTyping = false
        }
    }

    /// Request authorization from the user.
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    // MARK: - WhisperKit path
    
    @available(iOS 17.0, *)
    private func startWhisperKit() throws {
        // Initialize transcriber if needed
        if whisperKitTranscriber == nil {
            whisperKitTranscriber = WhisperKitTranscriber()
            // Auto-initialize on first use
            Task {
                try? await whisperKitTranscriber?.initialize()
            }
        }
        
        guard let transcriber = whisperKitTranscriber, transcriber.isAvailable else {
            throw NSError(domain: "LocalTranscriber", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "WhisperKit not available"])
        }
        
        self.activeEngine = .whisperKit
        
        // Wire up transcription callback
        transcriber.onTranscription = { [weak self] text, isFinal in
            Task { @MainActor [weak self] in
                self?.transcript = text
                self?.isTyping = !isFinal
                self?.onTranscription?(text, isFinal)
            }
        }
        
        try transcriber.start()
    }

    // MARK: - SpeechAnalyzer path

    @available(iOS 26.0, *)
    private func startSpeechAnalyzer() {
        let locale = Locale(identifier: "en-US")
        
        // Enhanced transcriber with task hints for better accuracy
        let transcriber = SpeechTranscriber(
            locale: locale,
            preset: .timeIndexedProgressiveTranscription
        )
        self.transcriber = transcriber
        self.analyzer = SpeechAnalyzer(
            modules: [transcriber],
            options: .init(priority: .userInitiated, modelRetention: .whileInUse)
        )
        self.activeEngine = .speechAnalyzer

        let inputStream = AsyncStream<AnalyzerInput> { continuation in
            self.analyzerInputContinuation = continuation
        }

        analyzerTask = Task { [weak self] in
            guard let self, let analyzer = self.analyzer else { return }
            do {
                // Reserve locale assets so Speech modules are properly allocated.
                // This prevents "unallocated locales" warnings and future hard failures.
                do {
                    if try await AssetInventory.reserve(locale: locale) {
                        self.reservedAnalyzerLocale = locale
                    }
                } catch {
                    // Best effort: continue. If not reservable, Speech can still run.
                }

                let bestFormat = await SpeechAnalyzer.bestAvailableAudioFormat(
                    compatibleWith: [transcriber]
                )
                // AnalyzerInput currently requires Int16 PCM. If the reported
                // best format is not Int16, use a safe fallback to avoid
                // runtime precondition failures in the Speech framework.
                let chosenFormat: AVAudioFormat
                if let bestFormat, bestFormat.commonFormat == .pcmFormatInt16 {
                    chosenFormat = bestFormat
                } else {
                    chosenFormat = self.fallbackAnalyzerInputFormat
                }
                self.analyzerInputFormat = chosenFormat
                try await analyzer.prepareToAnalyze(in: chosenFormat)
                try await analyzer.start(inputSequence: inputStream)
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isTyping = false
                }
            }
        }

        resultsTask = Task { [weak self] in
            guard let self else { return }
            let startTime = Date()
            do {
                for try await result in transcriber.results {
                    let text = String(result.text.characters)
                    let isFinal = result.isFinal
                    
                    // Post-process to fix common misrecognitions
                    let processedText = STTVocabulary.shared.postProcessTranscription(text)
                    
                    await MainActor.run {
                        self.transcript = processedText
                        self.isTyping = !isFinal
                        self.onTranscription?(processedText, isFinal)
                    }
                    
                    // Record diagnostics
                    await STTDiagnostics.shared.recordLocalTranscription(processedText, isFinal: isFinal)
                    if isFinal {
                        let latency = Date().timeIntervalSince(startTime)
                        await STTDiagnostics.shared.recordLatency(latency)
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isTyping = false
                }
                await STTDiagnostics.shared.recordLocalSTTTimeout()
            }
        }
    }

    @available(iOS 26.0, *)
    private func appendToSpeechAnalyzer(_ buffer: AVAudioPCMBuffer) {
        guard let continuation = analyzerInputContinuation else { return }
        guard let copied = copyBuffer(buffer) else { return }
        guard let output = convertIfNeeded(copied),
            output.format.commonFormat == .pcmFormatInt16
        else {
            return
        }
        continuation.yield(AnalyzerInput(buffer: output))
    }

    private func stopSpeechAnalyzer() {
        guard #available(iOS 26.0, *) else { return }

        analyzerInputContinuation?.finish()
        analyzerInputContinuation = nil

        let analyzerToFinish = analyzer
        Task {
            try? await analyzerToFinish?.finalizeAndFinishThroughEndOfInput()
        }

        analyzerTask?.cancel()
        analyzerTask = nil

        resultsTask?.cancel()
        resultsTask = nil

        analyzer = nil
        transcriber = nil
        analyzerInputFormat = nil

        if let reservedAnalyzerLocale {
            let localeToRelease = reservedAnalyzerLocale
            self.reservedAnalyzerLocale = nil
            Task {
                _ = await AssetInventory.release(reservedLocale: localeToRelease)
            }
        }
    }

    @available(iOS 26.0, *)
    private func convertIfNeeded(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        let targetFormat = analyzerInputFormat ?? fallbackAnalyzerInputFormat
        if formatsMatch(buffer.format, targetFormat) {
            return buffer.format.commonFormat == .pcmFormatInt16 ? buffer : nil
        }

        guard let converter = AVAudioConverter(from: buffer.format, to: targetFormat) else {
            return nil
        }

        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let outputFrameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1
        guard
            let convertedBuffer = AVAudioPCMBuffer(
                pcmFormat: targetFormat,
                frameCapacity: outputFrameCapacity
            )
        else {
            return nil
        }

        var conversionError: NSError?
        var providedInput = false
        converter.convert(to: convertedBuffer, error: &conversionError) { _, outStatus in
            if providedInput {
                outStatus.pointee = .noDataNow
                return nil
            }
            providedInput = true
            outStatus.pointee = .haveData
            return buffer
        }

        if conversionError != nil {
            return nil
        }
        return convertedBuffer.format.commonFormat == .pcmFormatInt16 ? convertedBuffer : nil
    }

    private func formatsMatch(_ lhs: AVAudioFormat, _ rhs: AVAudioFormat) -> Bool {
        lhs.sampleRate == rhs.sampleRate
            && lhs.channelCount == rhs.channelCount
            && lhs.commonFormat == rhs.commonFormat
            && lhs.isInterleaved == rhs.isInterleaved
    }

    private func copyBuffer(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard
            let copy = AVAudioPCMBuffer(
                pcmFormat: buffer.format,
                frameCapacity: buffer.frameCapacity
            )
        else {
            return nil
        }
        copy.frameLength = buffer.frameLength

        let sourceBuffers = UnsafeMutableAudioBufferListPointer(buffer.mutableAudioBufferList)
        let destinationBuffers = UnsafeMutableAudioBufferListPointer(copy.mutableAudioBufferList)

        guard sourceBuffers.count == destinationBuffers.count else { return nil }

        for index in 0..<sourceBuffers.count {
            let source = sourceBuffers[index]
            var destination = destinationBuffers[index]
            let byteCount = Int(min(source.mDataByteSize, destination.mDataByteSize))
            if let sourceData = source.mData, let destinationData = destination.mData {
                memcpy(destinationData, sourceData, byteCount)
                destination.mDataByteSize = source.mDataByteSize
            }
            destinationBuffers[index] = destination
        }

        return copy
    }

    // MARK: - SFSpeechRecognizer fallback

    private func startSFSpeechRecognizer() throws {
        guard let recognizer = recognizer, recognizer.isAvailable else {
            throw SpeechError.unavailable
        }
        activeEngine = .sfSpeechRecognizer

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        
        // Add domain-specific vocabulary for better recognition
        request.contextualStrings = STTVocabulary.shared.contextualStrings
        
        // Configure for conversational speech
        if #available(iOS 16, *) {
            request.addsPunctuation = true
        }

        if #available(iOS 13, *) {
            request.requiresOnDeviceRecognition = true
        }

        self.request = request

        let startTime = Date()
        
        // Start task
        self.task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let text = result.bestTranscription.formattedString
                let isFinal = result.isFinal
                
                // Post-process to fix common misrecognitions
                let processedText = STTVocabulary.shared.postProcessTranscription(text)

                DispatchQueue.main.async {
                    self.transcript = processedText
                    self.isTyping = !isFinal
                    self.onTranscription?(processedText, isFinal)
                }
                
                // Record diagnostics
                Task {
                    await STTDiagnostics.shared.recordLocalTranscription(processedText, isFinal: isFinal)
                    if isFinal {
                        let latency = Date().timeIntervalSince(startTime)
                        await STTDiagnostics.shared.recordLatency(latency)
                    }
                }
            }

            if error != nil || result?.isFinal == true {
                self.stop()
                if error != nil {
                    Task {
                        await STTDiagnostics.shared.recordLocalSTTTimeout()
                    }
                }
            }
        }
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension LocalTranscriber: SFSpeechRecognizerDelegate {
    func speechRecognizer(
        _ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool
    ) {
        if !available {
            self.error = SpeechError.unavailable
            stop()
        }
    }
}

// MARK: - Errors

enum SpeechError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        switch self {
        case .unavailable: return "Speech recognition is not available."
        }
    }
}
