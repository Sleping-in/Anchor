//
//  GeminiLiveClient.swift
//  Anchor
//
//  Minimal Gemini Live API client (audio + text) using WebSocket.
//

import Combine
import Foundation

enum LiveClientAction: Equatable {
    case crisisDetected
    case breathingSuggestion(mode: BreathingPatternKind?, reason: String?)
    case openCrisisResources
}

@MainActor
final class GeminiLiveClient: ObservableObject {
    enum ConnectionState: Equatable {
        case idle
        case connecting
        case ready
        case failed
    }

    @Published private(set) var liveConnectionState: ConnectionState = .idle {
        didSet {
            onEvent?(.connectionStateChanged(mapConnectionState(liveConnectionState)))
        }
    }
    @Published private(set) var messages: [ConversationMessage] = []
    @Published private(set) var isGenerating = false
    @Published var errorMessage: String? {
        didSet {
            if let errorMessage {
                onEvent?(.error(errorMessage))
            }
        }
    }

    var localFallbackEnabled = false

    var onEvent: ((AIServiceEvent) -> Void)?
    var onAudioChunk: ((Data, String) -> Void)?
    var onTurnComplete: (() -> Void)?
    var onAction: ((LiveClientAction) -> Void)?

    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var receiveTask: Task<Void, Never>?
    private var activeAssistantMessageId: UUID?
    private var activeUserMessageId: UUID?
    private var pendingAudioChunks: [RealtimeAudio] = []
    private let maxPendingAudioChunks = 500
    private var currentConfig: GeminiLiveConfig?

    // ── Transcript throttling ──────────────────────────────────────
    // Buffer partial transcription text and only flush to @Published
    // messages on a timer so the UI updates in smooth sections instead
    // of word-by-word.
    private var pendingUserText: String?
    private var pendingAssistantText: String?
    private var transcriptFlushTimer: Timer?
    private let transcriptFlushInterval: TimeInterval = 0.30
    
    // Delayed clear for user message ID to prevent long utterance splitting
    private var userMessageIdClearTimer: Timer?
    private let userMessageIdClearDelay: TimeInterval = 2.0

    func connectIfNeeded(systemInstruction: String? = nil) async {
        guard liveConnectionState == .idle else { return }

        do {
            if localFallbackEnabled {
                liveConnectionState = .ready
                return
            }
            var config = try GeminiLiveConfig.load()
            // Override system instruction with personalised prompt if provided
            if let systemInstruction {
                config = config.withSystemInstruction(systemInstruction)
            }
            currentConfig = config
            if config.localMode {
                liveConnectionState = .ready
            } else {
                try await connect(using: config)
            }
        } catch {
            liveConnectionState = .failed
            errorMessage = error.localizedDescription
        }
    }

    func disconnect() {
        receiveTask?.cancel()
        receiveTask = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        urlSession?.invalidateAndCancel()
        urlSession = nil
        liveConnectionState = .idle
        isGenerating = false
        activeAssistantMessageId = nil
        activeUserMessageId = nil
        pendingAudioChunks.removeAll()
        currentConfig = nil
        transcriptFlushTimer?.invalidate()
        transcriptFlushTimer = nil
        userMessageIdClearTimer?.invalidate()
        userMessageIdClearTimer = nil
        pendingUserText = nil
        pendingAssistantText = nil
    }

    /// Re-establish the connection after a drop. Keeps existing messages.
    func reconnectSession() async {
        // Tear down stale socket without clearing messages.
        receiveTask?.cancel()
        receiveTask = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        urlSession?.invalidateAndCancel()
        urlSession = nil
        liveConnectionState = .idle
        isGenerating = false
        pendingAudioChunks.removeAll()
        transcriptFlushTimer?.invalidate()
        transcriptFlushTimer = nil
        userMessageIdClearTimer?.invalidate()
        userMessageIdClearTimer = nil
        pendingUserText = nil
        pendingAssistantText = nil
        errorMessage = nil

        await connectIfNeeded()
    }

    func sendUserText(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let message = ConversationMessage(role: .user, text: trimmed)
        messages.append(message)

        if currentConfig?.localMode == true || localFallbackEnabled {
            emitLocalResponse()
            return
        }

        if liveConnectionState == .idle {
            await connectIfNeeded()
        }

        if liveConnectionState == .connecting {
            let ready = await waitUntilReady()
            if !ready {
                errorMessage = "Live session is not ready yet."
                return
            }
        }

        guard liveConnectionState == .ready else {
            errorMessage = "Live session is not ready yet."
            return
        }

        let content = ClientContent(
            turns: [
                ClientTurn(role: "user", parts: [ClientPart(text: trimmed)])
            ],
            turnComplete: true
        )

        await send(ClientMessage(clientContent: content))
    }

    func sendInternalRequest(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard currentConfig?.localMode != true, !localFallbackEnabled else { return }

        if liveConnectionState == .idle {
            await connectIfNeeded()
        }

        if liveConnectionState == .connecting {
            let ready = await waitUntilReady()
            if !ready {
                errorMessage = "Live session is not ready yet."
                return
            }
        }

        guard liveConnectionState == .ready else {
            errorMessage = "Live session is not ready yet."
            return
        }

        let content = ClientContent(
            turns: [
                ClientTurn(role: "user", parts: [ClientPart(text: trimmed)])
            ],
            turnComplete: true
        )

        await send(ClientMessage(clientContent: content))
    }

    func sendRealtimeAudio(_ data: Data, mimeType: String) async {
        if currentConfig?.localMode == true || localFallbackEnabled {
            return
        }
        guard mimeType.contains("audio/pcm") else {
            errorMessage = "Unsupported audio format: \(mimeType)"
            return
        }
        if let rate = parseSampleRate(from: mimeType), rate != 16_000 {
            errorMessage = "Audio must be 16 kHz PCM (got \(Int(rate)) Hz)."
            return
        }
        guard data.count % MemoryLayout<Int16>.size == 0 else {
            errorMessage = "Audio buffer is not 16-bit PCM aligned."
            return
        }
        let chunk = RealtimeAudio(data: data.base64EncodedString(), mimeType: mimeType)

        if liveConnectionState == .idle {
            await connectIfNeeded()
        }

        if liveConnectionState == .connecting {
            bufferAudio(chunk)
            _ = await waitUntilReady()
        }

        guard liveConnectionState == .ready else {
            bufferAudio(chunk)
            return
        }

        await send(ClientMessage(realtimeInput: RealtimeInput(audio: chunk, audioStreamEnd: nil)))
    }

    func sendContextSignal(_ text: String) async {
        guard !text.isEmpty else { return }
        if currentConfig?.localMode == true || localFallbackEnabled {
            return
        }
        guard liveConnectionState == .ready else { return }
        let content = ClientContent(
            turns: [
                ClientTurn(role: "user", parts: [ClientPart(text: text)])
            ],
            turnComplete: false
        )
        await send(ClientMessage(clientContent: content))
    }

    func sendAudioStreamEnd() async {
        if currentConfig?.localMode == true {
            emitLocalResponse()
            return
        }
        if localFallbackEnabled {
            return
        }
        guard liveConnectionState == .ready else { return }
        await send(ClientMessage(realtimeInput: RealtimeInput(audio: nil, audioStreamEnd: true)))
    }

    private func connect(using config: GeminiLiveConfig) async throws {
        liveConnectionState = .connecting

        let request = try config.makeWebSocketRequest()
        let session = URLSession(configuration: .default)
        urlSession = session
        let task = session.webSocketTask(with: request)
        webSocketTask = task
        task.resume()

        let setup = ClientMessage(
            setup: Setup(
                model: config.normalizedModel,
                generationConfig: GenerationConfig(
                    responseModalities: config.responseModalities,
                    temperature: config.temperature,
                    maxOutputTokens: config.maxOutputTokens
                ),
                systemInstruction: config.systemInstruction.map {
                    ClientTurn(role: nil, parts: [ClientPart(text: $0)])
                },
                inputAudioTranscription: config.inputAudioTranscription,
                outputAudioTranscription: config.outputAudioTranscription
            )
        )

        await send(setup)
        receiveTask = Task { [weak self] in
            await self?.receiveLoop()
        }
    }

    private func send(_ message: ClientMessage) async {
        guard let webSocketTask else { return }

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(message)
            let text = String(decoding: data, as: UTF8.self)
            try await webSocketTask.send(.string(text))
        } catch {
            errorMessage = "Failed to send message: \(error.localizedDescription)"
        }
    }

    private func receiveLoop() async {
        guard let webSocketTask else { return }

        while !Task.isCancelled {
            do {
                let message = try await webSocketTask.receive()
                switch message {
                case .string(let text):
                    handleIncoming(text: text)
                case .data(let data):
                    handleIncoming(data: data)
                @unknown default:
                    break
                }
            } catch {
                liveConnectionState = .failed
                errorMessage = Self.describeConnectionError(error)
                break
            }
        }
    }

    private func waitUntilReady(timeout: TimeInterval = 6.0) async -> Bool {
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            if liveConnectionState == .ready {
                return true
            }
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
        return liveConnectionState == .ready
    }

    private func bufferAudio(_ chunk: RealtimeAudio) {
        pendingAudioChunks.append(chunk)
        if pendingAudioChunks.count > maxPendingAudioChunks {
            pendingAudioChunks.removeFirst(pendingAudioChunks.count - maxPendingAudioChunks)
        }
    }

    private func flushPendingAudio() async {
        guard liveConnectionState == .ready else { return }
        guard !pendingAudioChunks.isEmpty else { return }
        let chunks = pendingAudioChunks
        pendingAudioChunks.removeAll()
        for chunk in chunks {
            await send(
                ClientMessage(realtimeInput: RealtimeInput(audio: chunk, audioStreamEnd: nil)))
        }
    }

    private func handleIncoming(text: String) {
        guard let data = text.data(using: .utf8) else { return }
        handleIncoming(data: data)
    }

    private func parseSampleRate(from mimeType: String) -> Double? {
        guard let range = mimeType.range(of: "rate=") else { return nil }
        let value = mimeType[range.upperBound...]
        let parts = value.split(separator: ";")
        return Double(parts.first ?? "")
    }

    private func handleIncoming(data: Data) {
        // ── Fast path: parse on the current (WebSocket) thread and
        // deliver audio chunks *immediately* to the playback queue,
        // bypassing the MainActor hop that caused scheduling jitter.
        guard let parsed = Self.parseServerMessage(from: data) else { return }

        // Deliver audio directly — no thread hop.
        for chunk in parsed.audioChunks {
            onAudioChunk?(chunk.data, chunk.mimeType)
            onEvent?(.audio(data: chunk.data, mimeType: chunk.mimeType))
        }

        // Everything else (transcripts, UI flags) goes to MainActor.
        Task { @MainActor [weak self] in
            self?.applyParsedUI(parsed)
        }
    }

    /// Apply only the UI-relevant parts of a parsed message (transcripts,
    /// turn-complete, setup-complete, isGenerating).  Audio is delivered
    /// separately on the WebSocket thread for lowest latency.
    private func applyParsedUI(_ parsed: ParsedServerMessage) {
        if parsed.isSetupComplete {
            liveConnectionState = .ready
            Task { [weak self] in
                await self?.flushPendingAudio()
            }
            return
        }

        if let inputTranscription = parsed.inputTranscription {
            applyTranscription(
                text: inputTranscription.text, role: .user, isFinal: inputTranscription.isFinal)
        }

        if let outputTranscription = parsed.outputTranscription {
            applyTranscription(
                text: outputTranscription.text, role: .assistant,
                isFinal: outputTranscription.isFinal)
        }

        // NOTE: textParts from the native-audio model are the model's
        // internal thinking / reasoning chain — they are never spoken
        // aloud and should not appear in the conversation transcript.
        // We intentionally skip them here.  If a future non-audio model
        // is used (responseModalities: ["TEXT"]), this guard should be
        // revisited so text responses are still displayed.

        // Audio chunks are already delivered in handleIncoming() on the
        // WebSocket thread. Here we only track the isGenerating flag.
        if !parsed.audioChunks.isEmpty {
            isGenerating = true
        }

        if parsed.isTurnComplete {
            isGenerating = false

            // Flush any remaining buffered transcription text.
            flushTranscripts()

            // Notify the audio layer so it can flush any accumulated
            // playback data (avoids silence at the tail of a response).
            onTurnComplete?()
            onEvent?(.turnComplete)

            // Mark active messages as done streaming.
            if let id = activeAssistantMessageId,
                let i = messages.firstIndex(where: { $0.id == id })
            {
                messages[i].isStreaming = false
            }
            if let id = activeUserMessageId,
                let i = messages.firstIndex(where: { $0.id == id })
            {
                messages[i].isStreaming = false
            }

            // Clear assistant message ID immediately (assistant turn is done)
            activeAssistantMessageId = nil
            
            // NOTE: Don't clear activeUserMessageId immediately here.
            // When using local STT, the server turnComplete may arrive
            // before the local STT has finished sending final results.
            // Clearing prematurely causes long utterances to split into
            // multiple messages. Instead, we delay the clear.
            scheduleUserMessageIdClear()
        }
    }

    private func emitLocalResponse() {
        isGenerating = true
        let responseText = "I’m here with you. Want to share what’s on your mind right now?"
        let newMessage = ConversationMessage(
            role: .assistant, text: responseText, isStreaming: false)
        messages.append(newMessage)
        isGenerating = false
    }

    private func applyModelText(_ text: String, isFinal: Bool) {
        isGenerating = true

        if let messageId = activeAssistantMessageId,
            let index = messages.firstIndex(where: { $0.id == messageId })
        {
            if text.hasPrefix(messages[index].text) {
                messages[index].text = text
            } else {
                messages[index].text += text
            }
            messages[index].isStreaming = !isFinal
        } else {
            let newMessage = ConversationMessage(
                role: .assistant, text: text, isStreaming: !isFinal)
            messages.append(newMessage)
            activeAssistantMessageId = newMessage.id
        }
        // activeAssistantMessageId is cleared on turnComplete, not here.
    }

    private var hasLocalTranscript = false
    
    /// Toggle to use server-side (Gemini Live) transcripts instead of local STT
    /// Set to `true` to use Gemini's transcripts, `false` for local STT
    static var useServerTranscripts = true

    func overrideUserTranscript(_ text: String, isFinal: Bool) {
        // Skip local transcripts if we're using server-side transcripts
        guard !Self.useServerTranscripts else { return }
        
        hasLocalTranscript = true
        // Clear any queued server-side user partials so they cannot flush
        // into the UI after local STT has taken ownership.
        pendingUserText = nil
        transcriptFlushTimer?.invalidate()
        transcriptFlushTimer = nil
        // Directly commit to UI
        commitLocalUserTranscription(text: text, isFinal: isFinal)
        // Also fire event for any other listeners
        onEvent?(.userTranscription(text: text, isFinal: isFinal))
        
        // Record diagnostics
        Task {
            await STTDiagnostics.shared.recordLocalTranscription(text, isFinal: isFinal)
        }

        if isFinal {
            // If it's final locally, we treat it as the source of truth
            if let id = activeUserMessageId,
                let index = messages.firstIndex(where: { $0.id == id })
            {
                messages[index].isStreaming = false
            }
        }
    }

    /// Tracks last processed transcript to deduplicate identical results
    private var lastProcessedTranscript: String = ""
    private var lastProcessedIsFinal: Bool = false
    
    private func commitLocalUserTranscription(text: String, isFinal: Bool) {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        
        // Deduplicate: skip if identical to last processed transcript with same finality
        if cleaned == lastProcessedTranscript && isFinal == lastProcessedIsFinal {
            return
        }
        lastProcessedTranscript = cleaned
        lastProcessedIsFinal = isFinal
        
        // Track that we received a transcript
        lastTranscriptTimestamp = Date()
        
        // Cancel any pending clear timer - user is still speaking
        userMessageIdClearTimer?.invalidate()
        userMessageIdClearTimer = nil

        if let messageId = activeUserMessageId,
            let index = messages.firstIndex(where: { $0.id == messageId })
        {
            let existing = messages[index].text
            
            // Check if this looks like a STT restart (new short utterance after final)
            // If previous was final and this is new content, append as continuation
            if !messages[index].isStreaming && !isFinal && cleaned.count < 20 {
                // Likely STT restarted - append to existing message
                messages[index].text = existing + " " + cleaned
                messages[index].isStreaming = true
                print("[GeminiLiveClient] Continuation after STT restart: '\(cleaned.prefix(30))...'")
            } else {
                let merged = mergeLocalUserHypothesis(
                    existing: existing,
                    incoming: cleaned,
                    isFinal: isFinal
                )
                // Only update if text actually changed or state needs update
                let textChanged = messages[index].text != merged
                let stateNeedsUpdate = messages[index].isStreaming == isFinal
                
                if textChanged || stateNeedsUpdate {
                    messages[index].text = merged
                    messages[index].isStreaming = !isFinal
                    
                    // Debug logging only when text actually changes
                    if (existing.count > 50 || cleaned.count > 50) && textChanged {
                        print("[GeminiLiveClient] Long utterance merged: \(existing.count) chars → \(merged.count) chars (final: \(isFinal))")
                    }
                }
            }
        } else {
            let newMessage = ConversationMessage(role: .user, text: cleaned, isStreaming: !isFinal)
            messages.append(newMessage)
            activeUserMessageId = newMessage.id
            print("[GeminiLiveClient] New user message created: \(cleaned.prefix(50))...")
        }
    }

    private func mergeLocalUserHypothesis(existing: String, incoming: String, isFinal: Bool) -> String {
        let current = existing.trimmingCharacters(in: .whitespacesAndNewlines)
        let next = incoming.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !next.isEmpty else { return current }
        guard !current.isEmpty else { return next }

        // CRITICAL FIX: Don't just replace on final - intelligently merge
        // to preserve long utterances and handle ums/ahs properly
        
        // Case 1: Natural progressive growth (most common)
        if next.hasPrefix(current) {
            return next
        }
        
        // Case 2: New content extends current (appending)
        // Check if the last 10 chars of current match anywhere in next
        let overlapWindow = min(20, current.count)
        if overlapWindow > 0 {
            let currentSuffix = String(current.suffix(overlapWindow)).lowercased()
            let nextLower = next.lowercased()
            if let range = nextLower.range(of: currentSuffix) {
                let matchedIndex = nextLower.distance(from: nextLower.startIndex, to: range.lowerBound)
                if matchedIndex < next.count / 2 {
                    // Current is at the start of next, return full next
                    return next
                }
            }
        }
        
        // Case 3: Next is substantially longer - likely more complete (include ums/ahs)
        if next.count > current.count + 5 {
            return next
        }
        
        // Case 4: Current is substantially longer - keep it (STT may have cleaned up ums)
        if current.count > next.count + 10 {
            return current
        }
        
        // Case 5: Append new content if they seem different but related
        let similarity = calculateSimilarity(current.lowercased(), next.lowercased())
        if similarity < 0.5 && next.count > 5 {
            // Likely new sentence or clause - append
            return current + " " + next
        }
        
        // Case 6: Minor differences - keep the one with filler words if final
        // (filler words indicate more natural speech)
        if isFinal {
            let currentFillers = countFillerWords(current)
            let nextFillers = countFillerWords(next)
            if abs(currentFillers - nextFillers) <= 1 {
                // Similar filler count, keep longer (more complete)
                return next.count >= current.count ? next : current
            }
            // Prefer the one with appropriate filler words
            return nextFillers >= currentFillers ? next : current
        }

        // Fallback: keep the longer hypothesis
        return next.count >= current.count ? next : current
    }
    
    /// Calculate simple word overlap similarity (0.0 to 1.0)
    private func calculateSimilarity(_ a: String, _ b: String) -> Double {
        let wordsA = Set(a.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty })
        let wordsB = Set(b.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty })
        guard !wordsA.isEmpty && !wordsB.isEmpty else { return 0 }
        let intersection = wordsA.intersection(wordsB).count
        let union = wordsA.union(wordsB).count
        return Double(intersection) / Double(union)
    }
    
    /// Count filler words (ums, ahs, etc.) to detect natural speech
    private func countFillerWords(_ text: String) -> Int {
        let fillers = ["um", "uh", "ah", "er", "hm", "mm"]
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        return words.filter { word in
            fillers.contains { filler in
                word == filler || word.hasPrefix(filler + "-") || word.hasSuffix("-" + filler)
            }
        }.count
    }

    private func applyTranscription(text: String, role: ConversationMessage.Role, isFinal: Bool) {
        guard !text.isEmpty else { return }
        isGenerating = role == .assistant

        var cleanedText = text
        var actions: [LiveClientAction] = []
        if role == .assistant {
            // Assistant logic remains same
            let result = extractActions(from: text)
            cleanedText = result.cleaned
            if isFinal {
                actions = result.actions
            }
        }

        if role == .assistant && cleanedText.isEmpty {
            if isFinal, !actions.isEmpty {
                actions.forEach { onAction?($0) }
            }
            return
        }

        switch role {
        case .user:
            // Record server transcription for diagnostics comparison
            Task {
                await STTDiagnostics.shared.recordServerTranscription(cleanedText, isFinal: isFinal)
            }
            
            // Ignore server transcripts if we have a local one for this turn
            if hasLocalTranscript { return }

            if cleanedText.hasPrefix("[Internal]") || cleanedText.hasPrefix("[Signal]") {
                return
            }
            onEvent?(.userTranscription(text: cleanedText, isFinal: isFinal))
        case .assistant:
            onEvent?(.modelTranscription(text: cleanedText, isFinal: isFinal))
        }

        // Buffer the latest text for this role.
        if role == .assistant {
            pendingAssistantText = cleanedText
        } else {
            pendingUserText = cleanedText
        }

        if isFinal {
            // This fragment is finalized — flush it to the UI now.
            // Do NOT clear activeAssistantMessageId/activeUserMessageId
            // here because more fragments may follow in the same turn.
            // The IDs are cleared only when turnComplete arrives.
            flushTranscripts()
            if role == .assistant, !actions.isEmpty {
                actions.forEach { onAction?($0) }
            }
        } else {
            scheduleTranscriptFlush()
        }
    }

    /// Publish buffered transcription text to @Published messages.
    private func flushTranscripts() {
        transcriptFlushTimer?.invalidate()
        transcriptFlushTimer = nil

        if let text = pendingUserText {
            pendingUserText = nil
            commitTranscription(text: text, role: .user)
        }
        if let text = pendingAssistantText {
            pendingAssistantText = nil
            commitTranscription(text: text, role: .assistant)
        }
    }

    /// Write text into the messages array (creates or updates the active message).
    private func commitTranscription(text: String, role: ConversationMessage.Role) {
        let activeId = role == .assistant ? activeAssistantMessageId : activeUserMessageId

        if let messageId = activeId,
            let index = messages.firstIndex(where: { $0.id == messageId })
        {
            let existing = messages[index].text
            if text.hasPrefix(existing) {
                // Cumulative update — server sent the full text so far.
                messages[index].text = text
            } else if existing.isEmpty {
                messages[index].text = text
            } else {
                // Incremental fragment — append with a space.
                messages[index].text = existing + " " + text
            }
            messages[index].isStreaming = true
        } else {
            let newMessage = ConversationMessage(role: role, text: text, isStreaming: true)
            messages.append(newMessage)
            if role == .assistant {
                activeAssistantMessageId = newMessage.id
            } else {
                activeUserMessageId = newMessage.id
            }
        }
    }

    private func extractActions(from text: String) -> (cleaned: String, actions: [LiveClientAction])
    {
        var cleaned = text
        var actions: [LiveClientAction] = []

        while let tagRange = cleaned.range(of: "[Action]") {
            let after = cleaned[tagRange.upperBound...]
            guard let jsonRange = firstJSONRange(in: after) else {
                cleaned.removeSubrange(tagRange)
                break
            }

            let jsonText = String(after[jsonRange])
            if let action = parseActionJSON(jsonText) {
                actions.append(action)
            }

            let removalRange = tagRange.lowerBound..<jsonRange.upperBound
            cleaned.removeSubrange(removalRange)
        }

        let normalized =
            cleaned
            .replacingOccurrences(of: "\n\n\n", with: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return (normalized, actions)
    }

    private func firstJSONRange(in text: Substring) -> ClosedRange<Substring.Index>? {
        guard let start = text.firstIndex(of: "{") else { return nil }

        var depth = 0
        var inString = false
        var escaped = false
        var startIndex: Substring.Index?

        var idx = start
        while idx < text.endIndex {
            let char = text[idx]

            if inString {
                if escaped {
                    escaped = false
                } else if char == "\\" {
                    escaped = true
                } else if char == "\"" {
                    inString = false
                }
            } else {
                if char == "\"" {
                    inString = true
                } else if char == "{" {
                    if depth == 0 {
                        startIndex = idx
                    }
                    depth += 1
                } else if char == "}" {
                    depth -= 1
                    if depth == 0, let startIndex {
                        return startIndex...idx
                    }
                }
            }
            idx = text.index(after: idx)
        }
        return nil
    }

    private func parseActionJSON(_ jsonText: String) -> LiveClientAction? {
        guard let data = jsonText.data(using: .utf8),
            let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }

        let typeRaw = (obj["type"] as? String ?? obj["action"] as? String ?? "").lowercased()
        if typeRaw.contains("crisis") {
            return .crisisDetected
        }

        if typeRaw.contains("breathing") || typeRaw.contains("breath") {
            let modeRaw = obj["mode"] as? String ?? obj["pattern"] as? String ?? ""
            let mode = BreathingPatternKind.from(actionValue: modeRaw)
            let reason = obj["reason"] as? String ?? obj["note"] as? String
            return .breathingSuggestion(mode: mode, reason: reason)
        }

        if typeRaw.contains("resource") {
            return .openCrisisResources
        }

        return nil
    }

    private func scheduleTranscriptFlush() {
        guard transcriptFlushTimer == nil else { return }
        transcriptFlushTimer = Timer.scheduledTimer(
            withTimeInterval: transcriptFlushInterval, repeats: false
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.flushTranscripts()
            }
        }
    }
    
    /// Tracks when we last received a transcript to prevent premature clearing
    private var lastTranscriptTimestamp: Date = .distantPast
    
    /// Tracks last scheduled clear time to prevent duplicate timers
    private var lastClearScheduleTime: Date = .distantPast
    
    /// Delay clearing the user message ID to prevent long utterances from
    /// being split when server turnComplete arrives before local STT finishes.
    private func scheduleUserMessageIdClear() {
        let now = Date()
        // Prevent scheduling multiple timers within 100ms of each other
        guard now.timeIntervalSince(lastClearScheduleTime) > 0.1 else { return }
        guard userMessageIdClearTimer == nil else { return }
        
        lastClearScheduleTime = now
        hasLocalTranscript = false
        let scheduledAt = now
        
        userMessageIdClearTimer = Timer.scheduledTimer(
            withTimeInterval: userMessageIdClearDelay, repeats: false
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                // Only clear if:
                // 1. No new local transcript started
                // 2. No transcript received since we scheduled this timer
                if !self.hasLocalTranscript && self.lastTranscriptTimestamp < scheduledAt {
                    self.activeUserMessageId = nil
                    self.userMessageIdClearTimer = nil
                    print("[GeminiLiveClient] Cleared activeUserMessageId after delay")
                }
            }
        }
    }

    nonisolated private static func parseTranscription(_ value: Any) -> ParsedTranscription? {
        if let text = value as? String {
            return ParsedTranscription(text: text, isFinal: true)
        }

        if let dict = value as? [String: Any] {
            let text = dict["text"] as? String ?? dict["transcript"] as? String ?? ""
            let isFinal =
                dict["isFinal"] as? Bool ?? dict["final"] as? Bool ?? dict["done"] as? Bool ?? true
            guard !text.isEmpty else { return nil }
            return ParsedTranscription(text: text, isFinal: isFinal)
        }

        return nil
    }

    private struct ParsedTranscription {
        let text: String
        let isFinal: Bool
    }

    private struct ParsedAudioChunk {
        let data: Data
        let mimeType: String
    }

    private struct ParsedServerMessage {
        let isSetupComplete: Bool
        let isTurnComplete: Bool
        let inputTranscription: ParsedTranscription?
        let outputTranscription: ParsedTranscription?
        let hasOutputTranscription: Bool
        let textParts: [String]
        let audioChunks: [ParsedAudioChunk]
    }

    private func mapConnectionState(_ state: ConnectionState) -> AIConnectionState {
        switch state {
        case .idle: return .idle
        case .connecting: return .connecting
        case .ready: return .ready
        case .failed: return .failed
        }
    }

    nonisolated private static func parseServerMessage(from data: Data) -> ParsedServerMessage? {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }

        if json["setupComplete"] != nil {
            return ParsedServerMessage(
                isSetupComplete: true,
                isTurnComplete: false,
                inputTranscription: nil,
                outputTranscription: nil,
                hasOutputTranscription: false,
                textParts: [],
                audioChunks: []
            )
        }

        guard let serverContent = json["serverContent"] as? [String: Any] else { return nil }

        let isTurnComplete =
            (serverContent["turnComplete"] as? Bool) == true
            || (serverContent["generationComplete"] as? Bool) == true

        let inputTranscription = serverContent["inputTranscription"].flatMap {
            parseTranscription($0)
        }
        let outputTranscription = serverContent["outputTranscription"].flatMap {
            parseTranscription($0)
        }
        let hasOutputTranscription = serverContent["outputTranscription"] != nil

        var textParts: [String] = []
        var audioChunks: [ParsedAudioChunk] = []

        if let modelTurn = serverContent["modelTurn"] as? [String: Any],
            let parts = modelTurn["parts"] as? [[String: Any]]
        {
            for part in parts {
                if let text = part["text"] as? String, !text.isEmpty {
                    textParts.append(text)
                }

                if let inlineData = part["inlineData"] as? [String: Any],
                    let mimeType = inlineData["mimeType"] as? String,
                    let dataString = inlineData["data"] as? String,
                    let data = Data(base64Encoded: dataString)
                {
                    audioChunks.append(ParsedAudioChunk(data: data, mimeType: mimeType))
                }

                if let mimeType = part["mimeType"] as? String,
                    let dataString = part["data"] as? String,
                    let data = Data(base64Encoded: dataString)
                {
                    audioChunks.append(ParsedAudioChunk(data: data, mimeType: mimeType))
                }
            }
        }

        return ParsedServerMessage(
            isSetupComplete: false,
            isTurnComplete: isTurnComplete,
            inputTranscription: inputTranscription,
            outputTranscription: outputTranscription,
            hasOutputTranscription: hasOutputTranscription,
            textParts: textParts,
            audioChunks: audioChunks
        )
    }

    nonisolated private static func describeConnectionError(_ error: Error) -> String {
        if let urlError = error as? URLError, urlError.code == .badServerResponse {
            return
                "Bad response from server. Check your Gemini API key, restrictions, billing, and model access."
        }
        return "Live session disconnected."
    }
}

struct GeminiLiveConfig {
    let model: String
    let apiKey: String?
    let ephemeralToken: String?
    let baseWebSocketURL: URL?
    let localMode: Bool
    let systemInstruction: String?
    let responseModalities: [String]
    let maxOutputTokens: Int?
    let temperature: Double?
    let inputAudioTranscription: AudioTranscriptionConfig?
    let outputAudioTranscription: AudioTranscriptionConfig?

    var normalizedModel: String {
        if model.hasPrefix("models/") {
            return model
        }
        return "models/\(model)"
    }

    /// Return a copy with a different system instruction.
    func withSystemInstruction(_ instruction: String) -> GeminiLiveConfig {
        GeminiLiveConfig(
            model: model,
            apiKey: apiKey,
            ephemeralToken: ephemeralToken,
            baseWebSocketURL: baseWebSocketURL,
            localMode: localMode,
            systemInstruction: instruction,
            responseModalities: responseModalities,
            maxOutputTokens: maxOutputTokens,
            temperature: temperature,
            inputAudioTranscription: inputAudioTranscription,
            outputAudioTranscription: outputAudioTranscription
        )
    }

    func makeWebSocketRequest() throws -> URLRequest {
        if let baseWebSocketURL {
            return URLRequest(url: baseWebSocketURL)
        }

        let method =
            ephemeralToken == nil ? "BidiGenerateContent" : "BidiGenerateContentConstrained"
        var baseURL = URL(
            string:
                "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.\(method)"
        )!

        if let token = ephemeralToken {
            var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
            components?.queryItems = [URLQueryItem(name: "access_token", value: token)]
            if let url = components?.url {
                baseURL = url
            }
        }

        if let apiKey = apiKey, ephemeralToken == nil {
            var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
            var items = components?.queryItems ?? []
            items.append(URLQueryItem(name: "key", value: apiKey))
            components?.queryItems = items
            if let url = components?.url {
                baseURL = url
            }
        }

        var request = URLRequest(url: baseURL)
        if let apiKey = apiKey, ephemeralToken == nil {
            request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        }

        return request
    }

    static func load() throws -> GeminiLiveConfig {
        let info = Bundle.main.infoDictionary ?? [:]
        let env = ProcessInfo.processInfo.environment

        let model =
            env["GEMINI_LIVE_MODEL"]
            ?? info["GEMINI_LIVE_MODEL"] as? String
            ?? "gemini-2.5-flash-native-audio-preview-12-2025"
        let apiKey = KeychainHelper.geminiAPIKey
        let ephemeralToken =
            env["GEMINI_EPHEMERAL_TOKEN"] ?? info["GEMINI_EPHEMERAL_TOKEN"] as? String
        let webSocketURLString = env["GEMINI_LIVE_WS_URL"] ?? info["GEMINI_LIVE_WS_URL"] as? String
        let localMode =
            (env["GEMINI_LIVE_LOCAL"] ?? info["GEMINI_LIVE_LOCAL"] as? String)?.lowercased()
            == "true"
            || (env["GEMINI_LIVE_LOCAL"] ?? info["GEMINI_LIVE_LOCAL"] as? String) == "1"
        let systemInstruction =
            env["GEMINI_SYSTEM_INSTRUCTION"] ?? info["GEMINI_SYSTEM_INSTRUCTION"] as? String
            ?? AnchorSystemPrompt.text

        let baseWebSocketURL = webSocketURLString.flatMap { URL(string: $0) }

        if model.isEmpty {
            throw GeminiLiveConfigError.missingModel
        }

        if webSocketURLString != nil && baseWebSocketURL == nil {
            throw GeminiLiveConfigError.invalidWebSocketURL
        }

        if !localMode && baseWebSocketURL == nil {
            if (apiKey == nil || apiKey?.isEmpty == true)
                && (ephemeralToken == nil || ephemeralToken?.isEmpty == true)
            {
                throw GeminiLiveConfigError.missingAuth
            }
        }

        return GeminiLiveConfig(
            model: model,
            apiKey: apiKey,
            ephemeralToken: ephemeralToken,
            baseWebSocketURL: baseWebSocketURL,
            localMode: localMode,
            systemInstruction: systemInstruction,
            responseModalities: ["AUDIO"],
            maxOutputTokens: 512,
            temperature: 0.7,
            inputAudioTranscription: AudioTranscriptionConfig(),
            outputAudioTranscription: AudioTranscriptionConfig()
        )
    }
}

enum GeminiLiveConfigError: LocalizedError {
    case missingModel
    case missingAuth
    case invalidWebSocketURL

    var errorDescription: String? {
        switch self {
        case .missingModel:
            return "Missing GEMINI_LIVE_MODEL configuration."
        case .missingAuth:
            return "Missing GEMINI_API_KEY or GEMINI_EPHEMERAL_TOKEN configuration."
        case .invalidWebSocketURL:
            return "Invalid GEMINI_LIVE_WS_URL value."
        }
    }
}

struct ClientMessage: Encodable {
    var setup: Setup?
    var clientContent: ClientContent?
    var realtimeInput: RealtimeInput?

    init(setup: Setup) {
        self.setup = setup
        self.clientContent = nil
        self.realtimeInput = nil
    }

    init(clientContent: ClientContent) {
        self.setup = nil
        self.clientContent = clientContent
        self.realtimeInput = nil
    }

    init(realtimeInput: RealtimeInput) {
        self.setup = nil
        self.clientContent = nil
        self.realtimeInput = realtimeInput
    }
}

struct Setup: Encodable {
    let model: String
    let generationConfig: GenerationConfig
    let systemInstruction: ClientTurn?
    let inputAudioTranscription: AudioTranscriptionConfig?
    let outputAudioTranscription: AudioTranscriptionConfig?
}

struct GenerationConfig: Encodable {
    let responseModalities: [String]
    let temperature: Double?
    let maxOutputTokens: Int?
}

struct ClientContent: Encodable {
    let turns: [ClientTurn]
    let turnComplete: Bool
}

struct ClientTurn: Encodable {
    let role: String?
    let parts: [ClientPart]

    enum CodingKeys: String, CodingKey {
        case role
        case parts
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(parts, forKey: .parts)
        if let role {
            try container.encode(role, forKey: .role)
        }
    }
}

struct ClientPart: Encodable {
    let text: String
}

struct RealtimeInput: Encodable {
    let audio: RealtimeAudio?
    let audioStreamEnd: Bool?
}

struct RealtimeAudio: Encodable {
    let data: String
    let mimeType: String
}

struct AudioTranscriptionConfig: Encodable {
    var languageCode: String?
    var model: String?

    init(languageCode: String? = nil, model: String? = nil) {
        self.languageCode = languageCode
        self.model = model
    }
}

// MARK: - AIServiceProtocol Conformance

extension GeminiLiveClient: AIServiceProtocol {
    var connectionState: AIConnectionState {
        mapConnectionState(liveConnectionState)
    }

    func connect(systemInstruction: String?) async throws {
        await connectIfNeeded(systemInstruction: systemInstruction)
        if liveConnectionState == .failed {
            throw NSError(
                domain: "GeminiLiveClient", code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: errorMessage ?? "Failed to connect."
                ])
        }
    }

    func reconnect() async throws {
        await reconnectSession()
        if liveConnectionState == .failed {
            throw NSError(
                domain: "GeminiLiveClient", code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey: errorMessage ?? "Failed to reconnect."
                ])
        }
    }

    func sendAudio(_ data: Data, mimeType: String) async {
        await sendRealtimeAudio(data, mimeType: mimeType)
    }

    func sendText(_ text: String) async {
        await sendUserText(text)
    }
}
