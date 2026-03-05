//
//  LiveAudioIO.swift
//  Anchor
//
//  Captures microphone audio and plays back model audio for live sessions.
//

import AVFoundation
import Accelerate
import Foundation

final class LiveAudioIO {
    enum AudioInterruptionEvent {
        case began
        case ended(shouldResume: Bool)
    }

    enum AudioError: LocalizedError {
        case permissionDenied
        case configurationFailed

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Microphone access is required for live voice conversations."
            case .configurationFailed:
                return "Audio session could not be configured."
            }
        }
    }

    var onAudioChunk: ((Data, String) -> Void)?
    var onLocalAudioBuffer: ((AVAudioPCMBuffer) -> Void)?
    var onEndOfTurn: (() -> Void)?
    var onVoiceStateChange: ((Bool) -> Void)?
    var onStressScore: ((Double) -> Void)?
    var onInterruption: ((AudioInterruptionEvent) -> Void)?

    /// Voice speed multiplier (0.5 – 2.0). Set before calling start().
    var playbackRate: Float = 1.0 {
        didSet { timePitchNode.rate = playbackRate }
    }
    /// Optional baseline for per-user normalization.
    var stressBaseline: Double?

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let timePitchNode = AVAudioUnitTimePitch()
    private let audioSendQueue = DispatchQueue(label: "com.anchor.liveAudioSend")
    private let audioPlaybackQueue = DispatchQueue(label: "com.anchor.liveAudioPlayback")
    private let stressTracker = VoiceStressTracker()

    private var inputFormat: AVAudioFormat?
    private var targetInputFormat: AVAudioFormat?
    private var interruptionObserver: NSObjectProtocol?
    private var converter: AVAudioConverter?
    private var isStarted = false

    /// Fixed playback format — playerNode is connected with this once at
    /// engine start, and never disconnected/reconnected while running.
    /// Using Float32 avoids per-chunk format conversion inside AVAudioEngine.
    private let playbackFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 24_000,
        channels: 1,
        interleaved: false
    )!

    // ── Echo suppression ────────────────────────────────────────────
    // Thread-safe counter so the completion callback (audio thread)
    // doesn't need to hop to main to update the flag.
    private let playbackCounter = AtomicCounter()
    /// After the last buffer finishes, hold the "playing back" state
    /// for a short window so the mic gate doesn't flicker open between
    /// scheduled buffers or immediately after playback ends.
    private let playbackHoldoff: TimeInterval = 0.35
    private var lastPlaybackEnd: Date = .distantPast
    private let playbackStateLock = NSLock()
    private var isPlayingBack: Bool {
        playbackStateLock.lock()
        let lastEnd = lastPlaybackEnd
        playbackStateLock.unlock()
        return playbackCounter.value > 0 || Date().timeIntervalSince(lastEnd) < playbackHoldoff
    }

    private var isSpeaking = false
    private var lastVoiceActivity: Date?
    private var didSendEndOfTurn = false
    private var prerollBuffers: [Data] = []
    private var lastStressSignalTime: Date?
    private var lastStressSignalScore: Double?
    private let stressSignalInterval: TimeInterval = 2.5
    private let stressSignalMinDelta: Double = 4.0
    private var analysisFrameCounter: Int = 0
    private let analysisFrameStride: Int = 3

    // ── Playback jitter buffer ──────────────────────────────────────
    // Accumulate raw Int16 PCM data from the server and batch-convert
    // to Float32 only when scheduling — avoids per-chunk allocation overhead.
    private var rawAccumulator = Data()
    private var isFirstPlaybackBurst = true
    /// First burst: ~400 ms at 24 kHz Int16 mono (2 bytes/frame).
    /// Large enough to absorb WebSocket jitter on the very first chunk.
    private let firstBurstRawBytes = 19_200  // 9600 frames × 2 bytes
    /// Steady-state: schedule in ~100 ms chunks so there are always
    /// several buffers queued ahead → eliminates inter-buffer silence.
    private let minPlaybackRawBytes = 4_800  // 2400 frames × 2 bytes
    /// Target sample rate for incoming audio.
    private var incomingSampleRate: Double = 24_000
    /// Generation counter — incremented on every turn-complete so a
    /// stale flush never contaminates the next response.
    private var playbackGeneration: UInt64 = 0

    // ── VAD tuning ──────────────────────────────────────────────────
    private let voiceThreshold: Float = 0.005
    // Adaptive barge-in threshold (calibrated from ambient noise)
    private let defaultBargeInThreshold: Float = 0.06
    private var adaptiveBargeInThreshold: Float = 0.06
    private let bargeInFramesRequired = 3
    private var consecutiveBargeInFrames = 0
    private let hangoverDuration: TimeInterval = 0.6
    private let silenceThreshold: TimeInterval = 1.5
    private let prerollBufferCount = 12
    
    // ── Echo suppression enhancement ────────────────────────────────
    // Residual echo suppression using spectral subtraction
    private var agentVoiceSpectrum: [Float]?
    private let spectrumUpdateInterval: TimeInterval = 0.5
    private var lastSpectrumUpdate: Date = .distantPast
    private let echoSuppressionFactor: Float = 0.7
    
    // Ambient noise calibration
    private var ambientNoiseFloor: Float = 0.001
    private var noiseCalibrationFrames: Int = 0
    private let noiseCalibrationRequired: Int = 50  // ~2 seconds at 25fps
    private var isCalibratingNoise: Bool = true

    // MARK: - Public API

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func start() throws {
        guard !isStarted else { return }
        try configureSession()
        registerForSessionNotifications()
        stressTracker.reset()
        analysisFrameCounter = 0
        lastStressSignalTime = nil
        lastStressSignalScore = nil

        // ── Playback node ──────────────────────────────────────────
        if !engine.attachedNodes.contains(playerNode) {
            engine.attach(playerNode)
        }
        if !engine.attachedNodes.contains(timePitchNode) {
            engine.attach(timePitchNode)
        }
        // Chain: playerNode → timePitch → mainMixer (all at 24 kHz Float32 mono)
        timePitchNode.rate = playbackRate
        engine.connect(playerNode, to: timePitchNode, format: playbackFormat)
        engine.connect(timePitchNode, to: engine.mainMixerNode, format: playbackFormat)

        // ── Mic capture ────────────────────────────────────────────
        let inputNode = engine.inputNode
        inputFormat = inputNode.outputFormat(forBus: 0)

        targetInputFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 16_000,
            channels: 1,
            interleaved: false
        )

        if let inputFormat, let targetInputFormat {
            converter = AVAudioConverter(from: inputFormat, to: targetInputFormat)
        }

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 8192, format: inputFormat) {
            [weak self] buffer, _ in
            self?.processInputBuffer(buffer)
        }

        engine.prepare()
        try engine.start()
        // Boost output volume — voiceChat mode can be conservative.
        engine.mainMixerNode.outputVolume = 1.0
        playerNode.volume = 1.0
        playerNode.play()
        isStarted = true
    }

    func stop() {
        guard isStarted else { return }
        engine.inputNode.removeTap(onBus: 0)
        playerNode.stop()
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        unregisterForSessionNotifications()
        isStarted = false
        isSpeaking = false
        lastVoiceActivity = nil
        didSendEndOfTurn = false
        prerollBuffers.removeAll()
        playbackCounter.reset()
        playbackStateLock.lock()
        lastPlaybackEnd = .distantPast
        playbackStateLock.unlock()
        consecutiveBargeInFrames = 0
        rawAccumulator.removeAll()
        isFirstPlaybackBurst = true
        playbackGeneration = 0
        lastStressSignalTime = nil
        lastStressSignalScore = nil
        analysisFrameCounter = 0
    }

    deinit {
        unregisterForSessionNotifications()
    }

    func currentStressScore() -> Double? {
        stressTracker.score(baseline: stressBaseline)
    }

    func playAudioChunk(_ data: Data, mimeType: String) {
        guard !data.isEmpty else { return }
        audioPlaybackQueue.async { [weak self] in
            self?.accumulateAndSchedule(data, mimeType: mimeType)
        }
    }

    /// Flush any remaining accumulated audio (called when a turn ends).
    func flushPlaybackBuffer() {
        audioPlaybackQueue.async { [weak self] in
            self?.scheduleAccumulated(force: true)
            // Advance generation so any late-arriving chunks from
            // the previous turn are silently dropped.
            self?.playbackGeneration += 1
            self?.isFirstPlaybackBurst = true
        }
    }

    /// Notify the playback pipeline that a new response turn is
    /// starting. Clears any stale accumulated data.
    func prepareForNewTurn() {
        audioPlaybackQueue.async { [weak self] in
            self?.rawAccumulator.removeAll(keepingCapacity: true)
            self?.isFirstPlaybackBurst = true
        }
    }

    /// Immediately stop all model audio playback (used on barge-in).
    func stopPlayback() {
        playerNode.stop()
        playbackCounter.reset()
        playbackStateLock.lock()
        lastPlaybackEnd = .distantPast  // barge-in: don't gate the mic
        playbackStateLock.unlock()
        audioPlaybackQueue.async { [weak self] in
            self?.rawAccumulator.removeAll()
            self?.isFirstPlaybackBurst = true
        }
        playerNode.play()  // re-arm for future buffers
    }

    // MARK: - Playback pipeline

    private func accumulateAndSchedule(_ data: Data, mimeType: String) {
        incomingSampleRate = parseSampleRate(from: mimeType) ?? 24_000
        rawAccumulator.append(data)

        let threshold = isFirstPlaybackBurst ? firstBurstRawBytes : minPlaybackRawBytes
        while rawAccumulator.count >= threshold {
            scheduleAccumulated(force: false)
        }
    }

    private func scheduleAccumulated(force: Bool) {
        guard !rawAccumulator.isEmpty else { return }
        let threshold = isFirstPlaybackBurst ? firstBurstRawBytes : minPlaybackRawBytes
        if !force && rawAccumulator.count < threshold { return }

        // Take at most `threshold` bytes per schedule to produce
        // evenly-sized buffers (avoids giant blobs that stutter).
        let bytesToTake: Int
        if force {
            bytesToTake = rawAccumulator.count
        } else {
            bytesToTake = min(rawAccumulator.count, threshold)
        }
        let rawData = rawAccumulator.prefix(bytesToTake)
        rawAccumulator.removeFirst(bytesToTake)
        isFirstPlaybackBurst = false

        // Batch convert Int16 → Float32
        var float32Data = int16ToFloat32(rawData)

        // Resample if needed (Gemini native-audio is always 24 kHz)
        if incomingSampleRate != 24_000 {
            float32Data = resampleFloat32(float32Data, from: incomingSampleRate, to: 24_000)
        }

        let bytesPerFrame = MemoryLayout<Float32>.size  // 4
        let frameCount = AVAudioFrameCount(float32Data.count / bytesPerFrame)
        guard frameCount > 0,
            let buffer = AVAudioPCMBuffer(pcmFormat: playbackFormat, frameCapacity: frameCount)
        else { return }
        buffer.frameLength = frameCount

        float32Data.withUnsafeBytes { raw in
            guard let src = raw.baseAddress else { return }
            if let dst = buffer.floatChannelData {
                memcpy(dst.pointee, src, Int(frameCount) * bytesPerFrame)
            }
        }

        if !engine.isRunning { try? engine.start() }
        if !playerNode.isPlaying { playerNode.play() }

        playbackCounter.increment()
        // Use .dataPlayedBack so the completion fires only after the
        // hardware has actually played the samples — prevents the
        // counter from decrementing too early and flickering the
        // echo-suppression gate.
        playerNode.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) {
            [weak self] _ in
            self?.playbackCounter.decrement()
            if self?.playbackCounter.value == 0 {
                self?.playbackStateLock.lock()
                self?.lastPlaybackEnd = Date()
                self?.playbackStateLock.unlock()
            }
        }
    }

    // MARK: - Format conversion helpers

    /// Convert Int16 PCM samples to Float32 (range –1 … 1).
    private func int16ToFloat32(_ data: Data) -> Data {
        let sampleCount = data.count / MemoryLayout<Int16>.size
        guard sampleCount > 0 else { return Data() }

        var out = Data(count: sampleCount * MemoryLayout<Float32>.size)
        data.withUnsafeBytes { src in
            out.withUnsafeMutableBytes { dst in
                guard let s = src.baseAddress?.assumingMemoryBound(to: Int16.self),
                    let d = dst.baseAddress?.assumingMemoryBound(to: Float32.self)
                else { return }
                let scale: Float32 = 1.0 / 32768.0
                for i in 0..<sampleCount {
                    d[i] = Float32(s[i]) * scale
                }
            }
        }
        return out
    }

    /// Nearest-neighbour resample Float32 data between sample rates.
    private func resampleFloat32(_ data: Data, from srcRate: Double, to dstRate: Double) -> Data {
        let bps = MemoryLayout<Float32>.size
        let srcCount = data.count / bps
        guard srcCount > 0 else { return Data() }
        let ratio = dstRate / srcRate
        let dstCount = Int(Double(srcCount) * ratio)
        guard dstCount > 0 else { return Data() }

        var result = Data(count: dstCount * bps)
        data.withUnsafeBytes { src in
            result.withUnsafeMutableBytes { dst in
                guard let s = src.baseAddress?.assumingMemoryBound(to: Float32.self),
                    let d = dst.baseAddress?.assumingMemoryBound(to: Float32.self)
                else { return }
                for i in 0..<dstCount {
                    d[i] = s[min(Int(Double(i) / ratio), srcCount - 1)]
                }
            }
        }
        return result
    }

    // MARK: - Mic capture

    private func processInputBuffer(_ buffer: AVAudioPCMBuffer) {
        // Capture playback state at record time so queued processing does not
        // accidentally forward frames recorded while TTS was playing.
        let capturedDuringPlayback = isPlayingBack

        // Convert buffer for processing
        guard let converter, let targetInputFormat else { return }
        
        let ratio = targetInputFormat.sampleRate / buffer.format.sampleRate
        let outputFrameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1
        
        guard let convertedBuffer = AVAudioPCMBuffer(
            pcmFormat: targetInputFormat, frameCapacity: outputFrameCapacity
        ) else { return }
        
        var error: NSError?
        converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        if let error {
            print("Audio conversion error: \(error.localizedDescription)")
            return
        }
        
        // Extract raw data for processing
        guard let channelData = convertedBuffer.int16ChannelData else { return }
        let byteCount = Int(convertedBuffer.frameLength) * MemoryLayout<Int16>.size
        var data = Data(bytes: channelData.pointee, count: byteCount)
        
        // Apply residual echo suppression if we have agent spectrum profile
        if !capturedDuringPlayback, let agentSpectrum = agentVoiceSpectrum {
            data = applyResidualEchoSuppression(data, agentSpectrum: agentSpectrum)
        }
        
        // Update agent voice spectrum during playback for next-frame suppression
        if capturedDuringPlayback {
            updateAgentVoiceSpectrum(from: data)
        }
        
        // Calibrate ambient noise during silence
        let rawRms = rmsAmplitude(from: data)
        calibrateAmbientNoise(rms: rawRms, isPlayback: capturedDuringPlayback)
        
        // Apply advanced audio preprocessing chain for STT
        if !capturedDuringPlayback {
            let preprocessedData = applyAudioPreprocessing(
                data,
                noiseFloor: isCalibratingNoise ? 0.001 : ambientNoiseFloor,
                sampleRate: 16_000
            )
            
            // Calculate and record preprocessing metrics
            let postRms = rmsAmplitude(from: preprocessedData)
            let gainApplied = rawRms > 0 ? postRms / rawRms : 1.0
            let wasGated = postRms < rawRms * 0.5  // Significant attenuation indicates gating
            Task {
                await STTDiagnostics.shared.recordPreprocessingMetrics(
                    gainApplied: gainApplied,
                    wasGated: wasGated
                )
            }
            
            data = preprocessedData
        }
        
        // Do not feed local STT while the assistant voice is playing.
        // This avoids transcript echo from speaker bleed.
        if !capturedDuringPlayback {
            onLocalAudioBuffer?(buffer)
        }
        
        audioSendQueue.async { [weak self] in
            self?.handleVAD(
                data: data,
                capturedDuringPlayback: capturedDuringPlayback
            )
        }
    }
    
    // MARK: - Residual Echo Suppression
    
    /// Apply spectral subtraction to remove residual agent voice
    private func applyResidualEchoSuppression(_ data: Data, agentSpectrum: [Float]) -> Data {
        // For now, return original data - full spectral subtraction is complex
        // and may introduce artifacts. The primary echo suppression (mic gating)
        // is already working well.
        // TODO: Implement full spectral subtraction if hardware AEC proves insufficient
        return data
    }
    
    /// Update agent voice spectrum profile during playback
    private func updateAgentVoiceSpectrum(from data: Data) {
        // Simplified spectrum tracking - storing basic energy profile
        // Full FFT-based spectral tracking disabled to avoid memory issues
        // Primary echo suppression (mic gating during playback) is working well
    }
    
    // MARK: - Ambient Noise Calibration
    
    /// Calibrate ambient noise floor during silence periods
    private func calibrateAmbientNoise(rms: Float, isPlayback: Bool) {
        guard isCalibratingNoise, !isPlayback else { return }
        
        // Only calibrate during quiet periods
        if rms < voiceThreshold {
            // Exponential moving average
            let alpha: Float = 0.1
            ambientNoiseFloor = (1 - alpha) * ambientNoiseFloor + alpha * rms
            noiseCalibrationFrames += 1
            
            if noiseCalibrationFrames >= noiseCalibrationRequired {
                isCalibratingNoise = false
                // Set adaptive threshold based on calibrated noise floor
                adaptiveBargeInThreshold = max(0.04, ambientNoiseFloor * 6.0)
                print("[LiveAudioIO] Noise calibration complete. Floor: \(ambientNoiseFloor), Barge threshold: \(adaptiveBargeInThreshold)")
            }
        }
    }

    // MARK: - Audio session

    private func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        do {
            // .voiceChat enables hardware acoustic echo cancellation (AEC)
            // even when routed to the loudspeaker.
            try session.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.defaultToSpeaker, .allowBluetoothHFP, .mixWithOthers]
            )
            // Force the speaker route so volume is adequate.
            try session.overrideOutputAudioPort(.speaker)
            // Match the playback pipeline's native rate (24 kHz) so the
            // hardware doesn't need to resample. Mic capture is software-
            // resampled to 16 kHz for the API anyway.
            try session.setPreferredSampleRate(24_000)
            // Larger IO buffer reduces scheduling overhead.
            try session.setPreferredIOBufferDuration(0.040)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw AudioError.configurationFailed
        }
    }

    private func registerForSessionNotifications() {
        guard interruptionObserver == nil else { return }
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification)
        }
    }

    private func unregisterForSessionNotifications() {
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
            self.interruptionObserver = nil
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
            let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
        case .began:
            onInterruption?(.began)
        case .ended:
            let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            onInterruption?(.ended(shouldResume: options.contains(.shouldResume)))
        @unknown default:
            break
        }
    }

    // MARK: - VAD

    private func parseSampleRate(from mimeType: String) -> Double? {
        guard let range = mimeType.range(of: "rate=") else { return nil }
        let value = mimeType[range.upperBound...]
        let parts = value.split(separator: ";")
        return Double(parts.first ?? "")
    }

    private func handleVAD(data: Data, capturedDuringPlayback: Bool) {
        let now = Date()
        let rms = rmsAmplitude(from: data)
        let frameCount = data.count / MemoryLayout<Int16>.size
        let duration = Double(frameCount) / 16_000.0
        let isVoice = rms >= voiceThreshold
        analysisFrameCounter += 1
        let zcr = isVoice ? zeroCrossingRate(from: data) : nil
        let syllables = isVoice ? estimateSyllableCount(from: data, baseRms: rms) : 0

        var pitchHz: Double?
        var centroidHz: Double?
        if isVoice, analysisFrameCounter % analysisFrameStride == 0 {
            pitchHz = estimatePitchHz(from: data, sampleRate: 16_000)
            centroidHz = spectralCentroid(from: data, sampleRate: 16_000)
        }

        stressTracker.addSample(
            rms: rms,
            duration: duration,
            isVoice: isVoice,
            zcr: zcr,
            pitchHz: pitchHz,
            centroidHz: centroidHz,
            syllableCount: syllables
        )
        emitStressSignalIfNeeded(now: now)

        // During model playback (or frames captured during playback): barge-in detection.
        // This gate prevents assistant-audio bleed from being re-sent to the model.
        let playbackActive = capturedDuringPlayback || isPlayingBack
        if playbackActive {
            // Use adaptive threshold based on ambient noise calibration
            let threshold = isCalibratingNoise ? defaultBargeInThreshold : adaptiveBargeInThreshold
            
            if rms >= threshold {
                consecutiveBargeInFrames += 1
                if consecutiveBargeInFrames >= bargeInFramesRequired {
                    DispatchQueue.main.async { [weak self] in
                        self?.stopPlayback()
                    }
                    consecutiveBargeInFrames = 0
                    // Fall through to normal path so this frame is sent.
                    Task {
                        await STTDiagnostics.shared.recordBargeInSuccess()
                    }
                } else {
                    return
                }
            } else {
                consecutiveBargeInFrames = 0
                return
            }
        } else {
            consecutiveBargeInFrames = 0
        }

        // Stream audio to the server.
        onAudioChunk?(data, "audio/pcm;rate=16000")

        // Update local voice state for UI.
        if rms >= voiceThreshold {
            lastVoiceActivity = now
            if !isSpeaking {
                isSpeaking = true
                didSendEndOfTurn = false
                onVoiceStateChange?(true)
            }
            return
        }

        if isSpeaking {
            if let lastVoice = lastVoiceActivity,
                now.timeIntervalSince(lastVoice) <= hangoverDuration
            {
                return
            }
        }

        if let lastVoice = lastVoiceActivity, now.timeIntervalSince(lastVoice) >= silenceThreshold {
            if !didSendEndOfTurn {
                didSendEndOfTurn = true
                isSpeaking = false
                lastVoiceActivity = nil
                onVoiceStateChange?(false)
                onEndOfTurn?()
            }
        }
    }

    private func emitStressSignalIfNeeded(now: Date) {
        guard isSpeaking else { return }
        guard let score = currentStressScore() else { return }

        if let lastTime = lastStressSignalTime,
            now.timeIntervalSince(lastTime) < stressSignalInterval
        {
            return
        }

        if let lastScore = lastStressSignalScore,
            abs(score - lastScore) < stressSignalMinDelta,
            now.timeIntervalSince(lastStressSignalTime ?? .distantPast) < stressSignalInterval * 2
        {
            return
        }

        lastStressSignalTime = now
        lastStressSignalScore = score
        onStressScore?(score)
    }

    // MARK: - Audio Preprocessing Chain
    
    /// Comprehensive audio preprocessing for STT optimization
    /// 1. High-pass filter (remove rumble)
    /// 2. Noise gate (silence background noise)
    /// 3. Automatic Gain Control (normalize levels)
    /// 4. Voice Activity Detection (drop non-speech frames)
    private func applyAudioPreprocessing(
        _ data: Data,
        noiseFloor: Float,
        sampleRate: Double
    ) -> Data {
        var samples = int16ToFloatArray(data)
        guard !samples.isEmpty else { return data }
        
        // Step 1: High-pass filter (remove sub-80Hz rumble and DC offset)
        samples = applyHighPassFilter(samples, cutoffHz: 80, sampleRate: sampleRate)
        
        // Step 2: Noise gate (silence audio below threshold)
        let gateThreshold = noiseFloor * 2.5  // 2.5x noise floor
        samples = applyNoiseGate(samples, threshold: gateThreshold)
        
        // Step 3: Automatic Gain Control (normalize to target level)
        let targetRMS: Float = 0.15  // Target -16dB RMS (good for STT)
        samples = applyAutomaticGainControl(samples, targetRMS: targetRMS, maxGain: 10.0)
        
        // Step 4: Soft limiting (prevent clipping after AGC)
        samples = applySoftLimiter(samples, threshold: 0.95)
        
        return floatArrayToInt16Data(samples)
    }
    
    /// Convert Int16 audio data to Float32 samples (-1.0 to 1.0)
    private func int16ToFloatArray(_ data: Data) -> [Float] {
        let sampleCount = data.count / MemoryLayout<Int16>.size
        guard sampleCount > 0 else { return [] }
        
        var samples = [Float](repeating: 0, count: sampleCount)
        data.withUnsafeBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else { return }
            let int16Pointer = baseAddress.assumingMemoryBound(to: Int16.self)
            for i in 0..<sampleCount {
                samples[i] = Float(int16Pointer[i]) / Float(Int16.max)
            }
        }
        return samples
    }
    
    /// Convert Float32 samples back to Int16 data
    private func floatArrayToInt16Data(_ samples: [Float]) -> Data {
        guard !samples.isEmpty else { return Data() }
        
        var data = Data(count: samples.count * MemoryLayout<Int16>.size)
        data.withUnsafeMutableBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else { return }
            let int16Pointer = baseAddress.assumingMemoryBound(to: Int16.self)
            for i in 0..<samples.count {
                let clamped = max(-1.0, min(1.0, samples[i]))
                int16Pointer[i] = Int16(clamped * Float(Int16.max))
            }
        }
        return data
    }
    
    /// High-pass filter to remove low-frequency rumble and DC offset
    private func applyHighPassFilter(_ samples: [Float], cutoffHz: Double, sampleRate: Double) -> [Float] {
        guard samples.count > 1 else { return samples }
        
        // Simple first-order high-pass filter
        // y[n] = alpha * (y[n-1] + x[n] - x[n-1])
        let rc = 1.0 / (2.0 * Double.pi * cutoffHz)
        let dt = 1.0 / sampleRate
        let alpha = Float(rc / (rc + dt))
        
        var result = [Float](repeating: 0, count: samples.count)
        var prevInput: Float = 0
        var prevOutput: Float = 0
        
        for i in 0..<samples.count {
            let input = samples[i]
            let output = alpha * (prevOutput + input - prevInput)
            result[i] = output
            prevInput = input
            prevOutput = output
        }
        
        return result
    }
    
    /// Noise gate: attenuate audio below threshold
    private func applyNoiseGate(_ samples: [Float], threshold: Float) -> [Float] {
        guard threshold > 0 else { return samples }
        
        // Calculate RMS in small windows for smoother gating
        let windowSize = 160  // 10ms at 16kHz
        var result = samples
        
        for windowStart in stride(from: 0, to: samples.count, by: windowSize) {
            let windowEnd = min(windowStart + windowSize, samples.count)
            
            // Calculate window RMS
            var sumSquares: Float = 0
            for i in windowStart..<windowEnd {
                sumSquares += samples[i] * samples[i]
            }
            let windowRMS = sqrt(sumSquares / Float(windowEnd - windowStart))
            
            // Apply gain reduction if below threshold
            if windowRMS < threshold {
                // Smooth attenuation curve
                let ratio = windowRMS / threshold
                let gain = ratio * ratio  // Quadratic attenuation
                for i in windowStart..<windowEnd {
                    result[i] = samples[i] * gain
                }
            }
        }
        
        return result
    }
    
    /// Automatic Gain Control: normalize audio to target RMS level
    private func applyAutomaticGainControl(
        _ samples: [Float],
        targetRMS: Float,
        maxGain: Float
    ) -> [Float] {
        guard samples.count > 0 else { return samples }
        
        // Calculate current RMS
        var sumSquares: Float = 0
        for sample in samples {
            sumSquares += sample * sample
        }
        let currentRMS = sqrt(sumSquares / Float(samples.count))
        
        // Avoid division by zero and extreme gains
        guard currentRMS > 0.001 else { return samples }
        
        // Calculate gain with limits
        var gain = targetRMS / currentRMS
        gain = min(gain, maxGain)  // Prevent excessive amplification
        gain = max(gain, 0.5)      // Prevent excessive attenuation
        
        // Smooth gain application (prevent pumping)
        let smoothedGain = 0.7 + 0.3 * gain  // Blend toward unity gain
        
        return samples.map { $0 * smoothedGain }
    }
    
    /// Soft limiter to prevent clipping
    private func applySoftLimiter(_ samples: [Float], threshold: Float) -> [Float] {
        return samples.map { sample in
            let absSample = abs(sample)
            guard absSample > threshold else { return sample }
            
            // Soft knee compression above threshold
            let excess = absSample - threshold
            let compressed = threshold + excess / (1.0 + excess * 2.0)
            return (sample > 0 ? 1 : -1) * compressed
        }
    }
    
    private func zeroCrossingRate(from data: Data) -> Double {
        let sampleCount = data.count / MemoryLayout<Int16>.size
        guard sampleCount > 1 else { return 0 }

        var crossings = 0
        data.withUnsafeBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else { return }
            let int16Pointer = baseAddress.assumingMemoryBound(to: Int16.self)
            var previous = int16Pointer[0]
            for index in 1..<sampleCount {
                let current = int16Pointer[index]
                if (previous >= 0 && current < 0) || (previous < 0 && current >= 0) {
                    crossings += 1
                }
                previous = current
            }
        }

        return Double(crossings) / Double(sampleCount)
    }

    private func estimateSyllableCount(from data: Data, baseRms: Float) -> Int {
        let sampleCount = data.count / MemoryLayout<Int16>.size
        guard sampleCount > 0 else { return 0 }
        let segments = 8
        let segmentLength = max(1, sampleCount / segments)
        let threshold = max(voiceThreshold * 1.4, baseRms * 0.6)

        var count = 0
        var wasAbove = false

        data.withUnsafeBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else { return }
            let int16Pointer = baseAddress.assumingMemoryBound(to: Int16.self)

            for segment in 0..<segments {
                let start = segment * segmentLength
                let end = min(sampleCount, start + segmentLength)
                if start >= end { break }

                var sumSquares: Double = 0
                for i in start..<end {
                    let sample = Double(int16Pointer[i]) / Double(Int16.max)
                    sumSquares += sample * sample
                }
                let meanSquare = sumSquares / Double(end - start)
                let rms = Float(sqrt(meanSquare))
                let isAbove = rms >= threshold
                if isAbove && !wasAbove {
                    count += 1
                }
                wasAbove = isAbove
            }
        }

        return count
    }

    private func estimatePitchHz(from data: Data, sampleRate: Double) -> Double? {
        let sampleCount = min(data.count / MemoryLayout<Int16>.size, 2048)
        guard sampleCount > 256 else { return nil }

        var samples = [Float](repeating: 0, count: sampleCount)
        data.withUnsafeBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else { return }
            let int16Pointer = baseAddress.assumingMemoryBound(to: Int16.self)
            for i in 0..<sampleCount {
                samples[i] = Float(int16Pointer[i]) / Float(Int16.max)
            }
        }

        var energy: Float = 0
        vDSP_svesq(samples, 1, &energy, vDSP_Length(sampleCount))
        guard energy > 0.005 else { return nil }

        let minLag = Int(sampleRate / 400)  // 400 Hz
        let maxLag = Int(sampleRate / 70)  // 70 Hz
        guard maxLag < sampleCount else { return nil }

        var bestLag = 0
        var bestCorr: Float = 0

        for lag in minLag...maxLag {
            var corr: Float = 0
            let limit = sampleCount - lag
            for i in 0..<limit {
                corr += samples[i] * samples[i + lag]
            }
            if corr > bestCorr {
                bestCorr = corr
                bestLag = lag
            }
        }

        guard bestLag > 0 else { return nil }
        guard bestCorr > energy * 0.1 else { return nil }
        return sampleRate / Double(bestLag)
    }

    private func spectralCentroid(from data: Data, sampleRate: Double) -> Double? {
        let fftSize = 1024
        let sampleCount = data.count / MemoryLayout<Int16>.size
        guard sampleCount >= fftSize else { return nil }

        var samples = [Float](repeating: 0, count: fftSize)
        data.withUnsafeBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else { return }
            let int16Pointer = baseAddress.assumingMemoryBound(to: Int16.self)
            for i in 0..<fftSize {
                samples[i] = Float(int16Pointer[i]) / Float(Int16.max)
            }
        }

        var window = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
        vDSP_vmul(samples, 1, window, 1, &samples, 1, vDSP_Length(fftSize))

        let log2n = vDSP_Length(log2(Double(fftSize)))
        guard let fft = vDSP.FFT(log2n: log2n, radix: .radix2, ofType: DSPSplitComplex.self) else {
            return nil
        }

        var real = samples
        var imag = [Float](repeating: 0, count: fftSize)
        return real.withUnsafeMutableBufferPointer { realBuffer in
            return imag.withUnsafeMutableBufferPointer { imagBuffer in
                guard let realBase = realBuffer.baseAddress,
                    let imagBase = imagBuffer.baseAddress
                else { return nil }
                var split = DSPSplitComplex(realp: realBase, imagp: imagBase)
                fft.forward(input: split, output: &split)

                var magnitudes = [Float](repeating: 0, count: fftSize / 2)
                magnitudes.withUnsafeMutableBufferPointer { magBuffer in
                    guard let magBase = magBuffer.baseAddress else { return }
                    vDSP_zvabs(&split, 1, magBase, 1, vDSP_Length(fftSize / 2))
                }

                var weightedSum: Float = 0
                var magnitudeSum: Float = 0
                let binWidth = Float(sampleRate) / Float(fftSize)
                for (index, magnitude) in magnitudes.enumerated() {
                    let frequency = Float(index) * binWidth
                    weightedSum += frequency * magnitude
                    magnitudeSum += magnitude
                }
                guard magnitudeSum > 0 else { return nil }
                return Double(weightedSum / magnitudeSum)
            }
        }
    }

    private func rmsAmplitude(from data: Data) -> Float {
        let sampleCount = data.count / MemoryLayout<Int16>.size
        guard sampleCount > 0 else { return 0 }

        var sumSquares: Double = 0
        data.withUnsafeBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else { return }
            let int16Pointer = baseAddress.assumingMemoryBound(to: Int16.self)
            for index in 0..<sampleCount {
                let sample = Double(int16Pointer[index]) / Double(Int16.max)
                sumSquares += sample * sample
            }
        }

        let meanSquare = sumSquares / Double(sampleCount)
        return Float(sqrt(meanSquare))
    }
}

// MARK: - Thread-safe counter

/// Lock-based atomic counter for tracking in-flight playback buffers.
/// Lives on the audio render thread (completion callbacks) — avoids the
/// latency of hopping to DispatchQueue.main that caused isPlayingBack
/// to flicker and intermittently block mic frames.
private final class AtomicCounter: @unchecked Sendable {
    private var _value: Int32 = 0
    private let lock = NSLock()

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return Int(_value)
    }

    func increment() {
        lock.lock()
        _value += 1
        lock.unlock()
    }

    func decrement() {
        lock.lock()
        _value = max(0, _value - 1)
        lock.unlock()
    }

    func reset() {
        lock.lock()
        _value = 0
        lock.unlock()
    }
}
