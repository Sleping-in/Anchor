//
//  AIServiceProtocol.swift
//  Anchor
//
//  Abstraction layer for AI conversation providers.
//  Allows swapping Gemini for OpenAI, Anthropic, or a local fallback
//  without changing any UI code.
//

import Foundation

/// Events emitted by a live AI session.
enum AIServiceEvent {
    /// Audio data to play back.
    case audio(data: Data, mimeType: String)
    /// Transcription of user speech.
    case userTranscription(text: String, isFinal: Bool)
    /// Transcription of model speech.
    case modelTranscription(text: String, isFinal: Bool)
    /// The model finished its current turn.
    case turnComplete
    /// Connection state changed.
    case connectionStateChanged(AIConnectionState)
    /// An error occurred.
    case error(String)
}

enum AIConnectionState: Equatable {
    case idle
    case connecting
    case ready
    case failed
}

/// Protocol defining a live voice AI conversation provider.
protocol AIServiceProtocol: AnyObject {
    /// Current connection state.
    var connectionState: AIConnectionState { get }

    /// Callback for events.
    var onEvent: ((AIServiceEvent) -> Void)? { get set }

    /// Connect to the service.
    func connect(systemInstruction: String?) async throws

    /// Disconnect from the service.
    func disconnect()

    /// Reconnect (preserving session context if possible).
    func reconnect() async throws

    /// Send real-time audio from the microphone.
    func sendAudio(_ data: Data, mimeType: String) async

    /// Signal end of user's audio stream (end of turn).
    func sendAudioStreamEnd() async

    /// Send a text message.
    func sendText(_ text: String) async
}

/// Registry of available AI providers.
enum AIProviderRegistry {
    enum Provider: String, CaseIterable, Identifiable {
        case gemini = "Gemini"
        case openAI = "OpenAI"
        case local = "Local (Offline)"

        var id: String { rawValue }

        var description: String {
            switch self {
            case .gemini: return "Google Gemini Live — real-time voice"
            case .openAI: return "OpenAI Realtime — GPT-4o voice"
            case .local: return "Offline fallback — basic text responses"
            }
        }

        var isAvailable: Bool {
            switch self {
            case .gemini:
                return KeychainHelper.geminiAPIKey != nil
            case .openAI:
                let info = Bundle.main.infoDictionary ?? [:]
                let env = ProcessInfo.processInfo.environment
                let key = env["OPENAI_API_KEY"] ?? info["OPENAI_API_KEY"] as? String
                return key != nil && !(key?.isEmpty ?? true)
            case .local:
                return true // always available
            }
        }
    }

    /// Returns the best available provider.
    static var preferredProvider: Provider {
        if Provider.gemini.isAvailable { return .gemini }
        if Provider.openAI.isAvailable { return .openAI }
        return .local
    }
}
