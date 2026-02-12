//
//  SessionSummarizer.swift
//  Anchor
//
//  Post-session AI summarizer using Gemini Flash REST API.
//

import Foundation

/// Generates structured session summaries using a lightweight LLM call.
enum SessionSummarizer {

    enum SummaryResult {
        case success(SessionNotes)
        case failure(SummaryError)
    }

    enum SummaryError: LocalizedError {
        case missingAPIKey
        case emptyTranscript
        case invalidRequest(String)
        case httpStatus(Int, String?, TimeInterval?)
        case decodingFailed
        case networkError(String)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "Missing Gemini API key."
            case .emptyTranscript:
                return "No transcript to summarize."
            case .invalidRequest(let message):
                return "Invalid summary request: \(message)"
            case .httpStatus(let code, _, _):
                return "Summary request failed (HTTP \(code))."
            case .decodingFailed:
                return "Could not read the summary response."
            case .networkError(let message):
                return "Network error: \(message)"
            }
        }

        var userMessage: String {
            switch self {
            case .missingAPIKey:
                return "Summary unavailable (missing API key)."
            case .emptyTranscript:
                return "Summary unavailable (no transcript)."
            case .invalidRequest:
                return "Summary unavailable (invalid request)."
            case .httpStatus(let code, _, _):
                return "Summary unavailable (HTTP \(code))."
            case .decodingFailed:
                return "Summary unavailable (invalid response)."
            case .networkError:
                return "Summary unavailable (network error)."
            }
        }

        var isRetryable: Bool {
            switch self {
            case .networkError:
                return true
            case .httpStatus(let code, _, _):
                return code == 429 || code >= 500
            default:
                return false
            }
        }

        var retryAfterSeconds: TimeInterval? {
            switch self {
            case .httpStatus(_, _, let retryAfter):
                return retryAfter
            default:
                return nil
            }
        }
    }

    enum SummaryPromptVersion: String {
        case v1
        case v2
    }

    struct SummaryContext {
        let sessionDate: Date
        let durationMinutes: Int
        let sessionOrdinal: Int
        let previousTopics: [String]
        let therapyGoals: [String]
        let previousHomework: [String]
        let profileContext: String

        init(
            sessionDate: Date = Date(),
            durationMinutes: Int = 0,
            sessionOrdinal: Int = 0,
            previousTopics: [String] = [],
            therapyGoals: [String] = [],
            previousHomework: [String] = [],
            profileContext: String = ""
        ) {
            self.sessionDate = sessionDate
            self.durationMinutes = durationMinutes
            self.sessionOrdinal = sessionOrdinal
            self.previousTopics = previousTopics
            self.therapyGoals = therapyGoals
            self.previousHomework = previousHomework
            self.profileContext = profileContext
        }
    }

    /// Canonical notes shape consumed by the app. Populated from v1 or v2 model contracts.
    struct SessionNotes {
        // Legacy fields (kept for backward compat)
        let mainTopics: [String]
        let observedMood: String
        let copingStrategies: [String]
        let keyInsights: String
        let suggestedFollowUp: String

        // Expanded fields
        let narrativeSummary: String
        let moodStartDescription: String
        let moodEndDescription: String
        let moodShiftDescription: String
        let keyInsight: String
        let userQuotes: [String]
        let copingStrategiesExplored: [String]
        let actionItemsForTherapist: [String]
        let recurringPatternAlert: String
        let homework: String

        // v2 metadata / continuity
        let summarySchemaVersion: Int
        let summaryRawJSON: String?
        let sessionOrdinal: Int?
        let primaryFocus: String
        let relatedThemes: [String]

        // v2 mood detail
        let moodStartIntensity: Int?
        let moodEndIntensity: Int?
        let moodStartPhysicalSymptoms: [String]
        let moodEndPhysicalSymptoms: [String]

        // v2 patterning
        let patternRecognized: String
        let recurringTopicsSnapshot: [String]
        let recurringTopicsTrend: String

        // v2 coping detail
        let copingStrategiesAttempted: [String]
        let copingStrategiesWorked: [String]
        let copingStrategiesDidntWork: [String]

        // v2 progress / continuity
        let previousHomeworkAssigned: String
        let previousHomeworkCompletion: String
        let previousHomeworkReflection: String
        let therapyGoalProgress: [String]
        let actionItemsForUser: [String]
        let continuityPeopleMentioned: [String]
        let continuityUpcomingEvents: [String]
        let continuityEnvironmentalFactors: [String]

        // v2 safety / clinical observations
        let crisisRiskDetectedByModel: Bool?
        let crisisNotes: String
        let protectiveFactors: [String]
        let safetyRecommendation: String
        let dominantEmotions: [String]
        let primaryCopingStyle: String
        let sessionEffectivenessSelfRating: Int?

        init(
            mainTopics: [String],
            observedMood: String,
            copingStrategies: [String],
            keyInsights: String,
            suggestedFollowUp: String,
            narrativeSummary: String,
            moodStartDescription: String,
            moodEndDescription: String,
            moodShiftDescription: String,
            keyInsight: String,
            userQuotes: [String],
            copingStrategiesExplored: [String],
            actionItemsForTherapist: [String],
            recurringPatternAlert: String,
            homework: String,
            summarySchemaVersion: Int = 1,
            summaryRawJSON: String? = nil,
            sessionOrdinal: Int? = nil,
            primaryFocus: String = "",
            relatedThemes: [String] = [],
            moodStartIntensity: Int? = nil,
            moodEndIntensity: Int? = nil,
            moodStartPhysicalSymptoms: [String] = [],
            moodEndPhysicalSymptoms: [String] = [],
            patternRecognized: String = "",
            recurringTopicsSnapshot: [String] = [],
            recurringTopicsTrend: String = "",
            copingStrategiesAttempted: [String] = [],
            copingStrategiesWorked: [String] = [],
            copingStrategiesDidntWork: [String] = [],
            previousHomeworkAssigned: String = "",
            previousHomeworkCompletion: String = "",
            previousHomeworkReflection: String = "",
            therapyGoalProgress: [String] = [],
            actionItemsForUser: [String] = [],
            continuityPeopleMentioned: [String] = [],
            continuityUpcomingEvents: [String] = [],
            continuityEnvironmentalFactors: [String] = [],
            crisisRiskDetectedByModel: Bool? = nil,
            crisisNotes: String = "",
            protectiveFactors: [String] = [],
            safetyRecommendation: String = "",
            dominantEmotions: [String] = [],
            primaryCopingStyle: String = "",
            sessionEffectivenessSelfRating: Int? = nil
        ) {
            self.mainTopics = mainTopics
            self.observedMood = observedMood
            self.copingStrategies = copingStrategies
            self.keyInsights = keyInsights
            self.suggestedFollowUp = suggestedFollowUp
            self.narrativeSummary = narrativeSummary
            self.moodStartDescription = moodStartDescription
            self.moodEndDescription = moodEndDescription
            self.moodShiftDescription = moodShiftDescription
            self.keyInsight = keyInsight
            self.userQuotes = userQuotes
            self.copingStrategiesExplored = copingStrategiesExplored
            self.actionItemsForTherapist = actionItemsForTherapist
            self.recurringPatternAlert = recurringPatternAlert
            self.homework = homework
            self.summarySchemaVersion = summarySchemaVersion
            self.summaryRawJSON = summaryRawJSON
            self.sessionOrdinal = sessionOrdinal
            self.primaryFocus = primaryFocus
            self.relatedThemes = relatedThemes
            self.moodStartIntensity = moodStartIntensity
            self.moodEndIntensity = moodEndIntensity
            self.moodStartPhysicalSymptoms = moodStartPhysicalSymptoms
            self.moodEndPhysicalSymptoms = moodEndPhysicalSymptoms
            self.patternRecognized = patternRecognized
            self.recurringTopicsSnapshot = recurringTopicsSnapshot
            self.recurringTopicsTrend = recurringTopicsTrend
            self.copingStrategiesAttempted = copingStrategiesAttempted
            self.copingStrategiesWorked = copingStrategiesWorked
            self.copingStrategiesDidntWork = copingStrategiesDidntWork
            self.previousHomeworkAssigned = previousHomeworkAssigned
            self.previousHomeworkCompletion = previousHomeworkCompletion
            self.previousHomeworkReflection = previousHomeworkReflection
            self.therapyGoalProgress = therapyGoalProgress
            self.actionItemsForUser = actionItemsForUser
            self.continuityPeopleMentioned = continuityPeopleMentioned
            self.continuityUpcomingEvents = continuityUpcomingEvents
            self.continuityEnvironmentalFactors = continuityEnvironmentalFactors
            self.crisisRiskDetectedByModel = crisisRiskDetectedByModel
            self.crisisNotes = crisisNotes
            self.protectiveFactors = protectiveFactors
            self.safetyRecommendation = safetyRecommendation
            self.dominantEmotions = dominantEmotions
            self.primaryCopingStyle = primaryCopingStyle
            self.sessionEffectivenessSelfRating = sessionEffectivenessSelfRating
        }
    }

    // MARK: - V2 Codable schema

    private struct LossyInt: Decodable {
        let value: Int?

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if container.decodeNil() {
                value = nil
                return
            }
            if let intValue = try? container.decode(Int.self) {
                value = intValue
                return
            }
            if let doubleValue = try? container.decode(Double.self) {
                value = Int(doubleValue.rounded())
                return
            }
            if let stringValue = try? container.decode(String.self) {
                value = Self.parseInt(from: stringValue)
                return
            }
            value = nil
        }

        private static func parseInt(from string: String) -> Int? {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if let direct = Int(trimmed) {
                return direct
            }
            let pattern = #"-?\d+"#
            guard let regex = try? NSRegularExpression(pattern: pattern) else {
                return nil
            }
            let nsRange = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
            guard let match = regex.firstMatch(in: trimmed, range: nsRange),
                let range = Range(match.range, in: trimmed)
            else {
                return nil
            }
            return Int(trimmed[range])
        }
    }

    private struct V2Response: Decodable {
        let sessionMetadata: V2SessionMetadata?
        let summary: V2Summary?
        let moodJourney: V2MoodJourney?
        let insights: V2Insights?
        let copingStrategies: V2CopingStrategies?
        let patterns: V2Patterns?
        let progressTracking: V2ProgressTracking?
        let actionItems: V2ActionItems?
        let contextForContinuity: V2Continuity?
        let safetyAssessment: V2SafetyAssessment?
        let clinicalObservations: V2ClinicalObservations?
    }

    private struct V2SessionMetadata: Decodable {
        let date: String?
        let durationMinutes: Int?
        let sessionNumber: Int?
    }

    private struct V2Summary: Decodable {
        let narrativeSummary: String?
        let primaryFocus: String?
        let relatedThemes: [String]?
    }

    private struct V2MoodJourney: Decodable {
        let starting: V2MoodPoint?
        let ending: V2MoodPoint?
        let whatShifted: String?
    }

    private struct V2MoodPoint: Decodable {
        let description: String?
        let intensity: LossyInt?
        let physicalSymptoms: [String]?
    }

    private struct V2Insights: Decodable {
        let keyInsight: String?
        let userQuotes: [String]?
        let patternRecognized: String?
    }

    private struct V2CopingStrategies: Decodable {
        let attempted: [V2AttemptedStrategy]?
        let whatWorked: [String]?
        let whatDidntWork: [String]?
    }

    private struct V2AttemptedStrategy: Decodable {
        let strategy: String?
        let effectiveness: String?
        let userFeedback: String?
    }

    private struct V2Patterns: Decodable {
        let recurringTopics: [V2RecurringTopic]?
        let alertForTherapist: String?
    }

    private struct V2RecurringTopic: Decodable {
        let topic: String?
        let frequency: String?
        let firstMentioned: String?
        let trend: String?
    }

    private struct V2ProgressTracking: Decodable {
        let previousHomework: V2PreviousHomework?
        let therapyGoals: [V2TherapyGoal]?
    }

    private struct V2PreviousHomework: Decodable {
        let assigned: String?
        let completion: String?
        let userReflection: String?
    }

    private struct V2TherapyGoal: Decodable {
        let goal: String?
        let progress: String?
        let evidence: String?
    }

    private struct V2ActionItems: Decodable {
        let forUser: [String]?
        let forTherapist: [String]?
        let newHomework: String?
    }

    private struct V2Continuity: Decodable {
        let peoplesMentioned: [V2PersonMentioned]?
        let upcomingEvents: [V2UpcomingEvent]?
        let environmentalFactors: [String]?
    }

    private struct V2PersonMentioned: Decodable {
        let name: String?
        let relationship: String?
        let significance: String?
    }

    private struct V2UpcomingEvent: Decodable {
        let event: String?
        let date: String?
        let anxietyLevel: String?
    }

    private struct V2SafetyAssessment: Decodable {
        let crisisRiskDetected: Bool?
        let crisisNotes: String?
        let protectiveFactors: [String]?
        let recommendation: String?
    }

    private struct V2ClinicalObservations: Decodable {
        let dominantEmotions: [String]?
        let primaryCopingStyle: String?
        let sessionEffectiveness: LossyInt?
    }

    // MARK: - Public API

    /// Generate a structured summary from conversation messages.
    static func summarize(
        messages: [(role: String, text: String)],
        summaryContext: SummaryContext,
        retryCount: Int = 2
    ) async -> SummaryResult {
        var result = await summarizeOnce(messages: messages, summaryContext: summaryContext)
        var remainingRetries = retryCount
        var attempt = 0
        while remainingRetries > 0 {
            switch result {
            case .success:
                return result
            case .failure(let error):
                guard error.isRetryable else {
                    return result
                }
                attempt += 1
                remainingRetries -= 1
                let baseDelay = error.retryAfterSeconds ?? min(30, pow(2.0, Double(attempt)) * 2.0)
                let jitter = Double.random(in: 0...0.75)
                let delay = max(2.0, baseDelay + jitter)
                print(
                    "[SessionSummarizer] Retry due to: \(error.localizedDescription). Waiting \(String(format: "%.1f", delay))s"
                )
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                result = await summarizeOnce(messages: messages, summaryContext: summaryContext)
            }
        }
        return result
    }

    /// Backwards-compatible entrypoint while callsites migrate to SummaryContext.
    static func summarize(
        messages: [(role: String, text: String)],
        profileContext: String = "",
        retryCount: Int = 2
    ) async -> SummaryResult {
        await summarize(
            messages: messages,
            summaryContext: SummaryContext(profileContext: profileContext),
            retryCount: retryCount
        )
    }

    private static func summarizeOnce(
        messages: [(role: String, text: String)],
        summaryContext: SummaryContext
    ) async -> SummaryResult {
        let preferredVersion = await MainActor.run { loadSummaryPromptVersion() }
        let primaryResult = await summarizeOnce(
            messages: messages,
            summaryContext: summaryContext,
            promptVersion: preferredVersion
        )

        if preferredVersion == .v2,
            case .failure(let error) = primaryResult,
            case .decodingFailed = error
        {
            Task { await SummaryDiagnostics.shared.recordFallbackToV1() }
            print("[SessionSummarizer] v2 parse failed, retrying once with v1 prompt.")
            return await summarizeOnce(
                messages: messages,
                summaryContext: summaryContext,
                promptVersion: .v1
            )
        }

        return primaryResult
    }

    private static func summarizeOnce(
        messages: [(role: String, text: String)],
        summaryContext: SummaryContext,
        promptVersion: SummaryPromptVersion
    ) async -> SummaryResult {
        guard !messages.isEmpty else { return .failure(.emptyTranscript) }

        let prompt = generatePrompt(
            messages: messages,
            summaryContext: summaryContext,
            promptVersion: promptVersion
        )
        guard let prompt else { return .failure(.emptyTranscript) }

        // Create deduplication hash from messages
        let requestHash = messages.reduce(0) { hash, msg in
            hash ^ msg.text.hashValue ^ msg.role.hashValue
        } ^ messages.count

        return await SummaryRateLimiter.shared.execute(requestHash: requestHash) {
            // Try Gemini API (AI Studio) first
            let geminiResult = await tryGeminiAPI(
                prompt: prompt,
                promptVersion: promptVersion
            )
            
            // On rate limit (429) or auth failure, fall back to Vertex AI
            if case .failure(.httpStatus(429, _, _)) = geminiResult {
                print("[SessionSummarizer] Gemini API rate limited, trying Vertex AI fallback...")
                return await tryVertexAI(
                    prompt: prompt,
                    promptVersion: promptVersion
                )
            }
            if case .failure(.httpStatus(401...403, _, _)) = geminiResult {
                print("[SessionSummarizer] Gemini API auth failed, trying Vertex AI fallback...")
                return await tryVertexAI(
                    prompt: prompt,
                    promptVersion: promptVersion
                )
            }
            
            return geminiResult
        }
    }
    
    /// Try Gemini API (AI Studio) endpoint
    private static func tryGeminiAPI(
        prompt: String,
        promptVersion: SummaryPromptVersion
    ) async -> SummaryResult {
        guard let apiKey = KeychainHelper.geminiAPIKey, !apiKey.isEmpty else {
            print("[SessionSummarizer] Missing Gemini API key.")
            return .failure(.missingAPIKey)
        }
        
        let summaryModel = loadSummaryModel()
        let url = URL(
            string: "https://generativelanguage.googleapis.com/v1beta/\(summaryModel):generateContent?key=\(apiKey)"
        )!

        return await executeGeminiRequest(
            url: url,
            prompt: prompt,
            promptVersion: promptVersion
        )
    }
    
    /// Try Vertex AI endpoint as fallback
    private static func tryVertexAI(
        prompt: String,
        promptVersion: SummaryPromptVersion
    ) async -> SummaryResult {
        let config = loadVertexAIConfig()
        
        guard config.isConfigured, let apiKey = config.apiKey, !apiKey.isEmpty else {
            print("[SessionSummarizer] Vertex AI not configured.")
            return .failure(.httpStatus(429, "Rate limited and Vertex AI not configured", nil))
        }
        
        let modelName = config.modelName ?? "gemini-2.5-flash"
        let url = URL(
            string: "https://\(config.location)-aiplatform.googleapis.com/v1/projects/\(config.projectId)/locations/\(config.location)/publishers/google/models/\(modelName):generateContent?key=\(apiKey)"
        )!
        
        return await executeVertexRequest(
            url: url,
            prompt: prompt,
            promptVersion: promptVersion
        )
    }
    
    /// Execute Gemini API request (no role field needed)
    private static func executeGeminiRequest(
        url: URL,
        prompt: String,
        promptVersion: SummaryPromptVersion
    ) async -> SummaryResult {
        let body: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "temperature": 0.3,
                "maxOutputTokens": 3072,
            ],
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return .failure(.invalidRequest("Unable to serialize request body."))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.networkError("Missing HTTP response."))
            }
            guard httpResponse.statusCode == 200 else {
                let bodyText = String(data: data, encoding: .utf8)
                let retryAfter = retryAfterSeconds(from: httpResponse)
                if let retryAfter {
                    await SummaryRateLimiter.shared.imposeCooldown(seconds: retryAfter)
                }
                print(
                    "[SessionSummarizer] HTTP \(httpResponse.statusCode): \(bodyText ?? "no body")"
                )
                return .failure(.httpStatus(httpResponse.statusCode, bodyText, retryAfter))
            }

            let parsedNotes: SessionNotes? = parseResponse(data, preferredVersion: promptVersion)
            guard let notes = parsedNotes else {
                return .failure(.decodingFailed)
            }
            return .success(notes)
        } catch {
            print("[SessionSummarizer] Network error: \(error.localizedDescription)")
            return .failure(.networkError(error.localizedDescription))
        }
    }
    
    /// Execute Vertex AI API request (requires role field)
    private static func executeVertexRequest(
        url: URL,
        prompt: String,
        promptVersion: SummaryPromptVersion
    ) async -> SummaryResult {
        let body: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [["text": prompt]]
                ]
            ],
            "generationConfig": [
                "temperature": 0.3,
                "maxOutputTokens": 3072,
            ],
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return .failure(.invalidRequest("Unable to serialize request body."))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.networkError("Missing HTTP response."))
            }
            guard httpResponse.statusCode == 200 else {
                let bodyText = String(data: data, encoding: .utf8)
                let retryAfter = retryAfterSeconds(from: httpResponse)
                if let retryAfter {
                    await SummaryRateLimiter.shared.imposeCooldown(seconds: retryAfter)
                }
                print(
                    "[SessionSummarizer] HTTP \(httpResponse.statusCode): \(bodyText ?? "no body")"
                )
                return .failure(.httpStatus(httpResponse.statusCode, bodyText, retryAfter))
            }

            let parsedNotes: SessionNotes? = parseResponse(data, preferredVersion: promptVersion)
            guard let notes = parsedNotes else {
                return .failure(.decodingFailed)
            }
            return .success(notes)
        } catch {
            print("[SessionSummarizer] Network error: \(error.localizedDescription)")
            return .failure(.networkError(error.localizedDescription))
        }
    }

    static func generatePrompt(
        messages: [(role: String, text: String)],
        summaryContext: SummaryContext,
        promptVersion: SummaryPromptVersion? = nil
    ) -> String? {
        let transcript = messages.map { "[\($0.role.uppercased())]: \($0.text)" }.joined(
            separator: "\n")
        guard !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let resolvedVersion = promptVersion ?? loadSummaryPromptVersion()
        switch resolvedVersion {
        case .v1:
            return generateV1Prompt(transcript: transcript, context: summaryContext)
        case .v2:
            return generateV2Prompt(transcript: transcript, context: summaryContext)
        }
    }

    /// Backwards-compatible overload.
    static func generatePrompt(messages: [(role: String, text: String)], profileContext: String)
        -> String?
    {
        generatePrompt(
            messages: messages,
            summaryContext: SummaryContext(profileContext: profileContext),
            promptVersion: .v1
        )
    }

    private static func generateV1Prompt(transcript: String, context: SummaryContext) -> String {
        var profileBlock = ""
        if !context.profileContext.isEmpty {
            profileBlock = """

                USER PROFILE CONTEXT (from past sessions):
                \(context.profileContext)

                Use this context to identify recurring patterns. If a topic has appeared
                in 3+ past sessions, flag it in "recurringPatternAlert".
                """
        }

        return """
            You are a clinical note assistant for an emotional support app called Anchor.
            Analyze this session transcript and produce structured, therapist-grade notes.

            SESSION METADATA:
            Date: \(context.sessionDate.formatted(date: .abbreviated, time: .shortened))
            Duration: \(context.durationMinutes) minutes
            Session Number: \(context.sessionOrdinal)

            TRANSCRIPT:
            \(transcript)
            \(profileBlock)

            CRITICAL RULES:
            - Use "you" language (second person): "You realized…" not "The client realized…"
            - Quote the user directly when possible (use their exact words)
            - Be specific with examples, never vague ("anxious about presentation" not "general stress")
            - NEVER diagnose ("You have GAD" → "You experienced anxiety symptoms")
            - NEVER prescribe treatment ("Take medication" → "Discuss with your doctor")
            - NEVER fabricate — if something wasn't discussed, leave it empty
            - Keep the total note readable in under 2 minutes

            Respond ONLY with JSON in this exact format (no markdown, no code fences):
            {
              "mainTopics": ["topic1", "topic2", "topic3"],
              "observedMood": "brief mood description based on user's words",
              "copingStrategies": ["strategy1", "strategy2"],
              "keyInsights": "1-2 sentence summary of the session",
              "suggestedFollowUp": "1 sentence suggestion for next session or therapist discussion",
              "narrativeSummary": "2-3 sentence narrative of what was discussed, what was discovered, and how the user felt by the end. Use 'you' language.",
              "moodStartDescription": "User's emotional state at the start",
              "moodEndDescription": "User's emotional state at the end",
              "moodShiftDescription": "What changed during the conversation and why",
              "keyInsight": "The core realization the user had about themselves — this is the most valuable part for therapists.",
              "userQuotes": ["Direct quote from user in their own words", "Another quote if available"],
              "copingStrategiesExplored": ["✅ Box breathing → helped", "⚠️ Avoidance → made anxiety worse"],
              "actionItemsForTherapist": ["Question or action item for therapist discussion", "Pattern worth exploring deeper"],
              "recurringPatternAlert": "If this topic appeared in past sessions, describe the pattern. Otherwise empty string.",
              "homework": "A specific, small, concrete exercise for the user to try before the next session."
            }
            """
    }

    private static func generateV2Prompt(transcript: String, context: SummaryContext) -> String {
        let previousTopics =
            context.previousTopics.isEmpty
            ? "none"
            : context.previousTopics.prefix(8).joined(separator: ", ")
        let therapyGoals =
            context.therapyGoals.isEmpty
            ? "none"
            : context.therapyGoals.prefix(5).joined(separator: "; ")
        let previousHomework =
            context.previousHomework.isEmpty
            ? "none"
            : context.previousHomework.prefix(4).joined(separator: "; ")
        let profileBlock = context.profileContext.isEmpty ? "none" : context.profileContext
        let isoDate = ISO8601DateFormatter().string(from: context.sessionDate)

        return """
            You are a clinical note assistant for Anchor, an emotional support app that helps users between therapy sessions.

            Your role: Analyze session transcripts and produce therapist-grade clinical notes that are:
            1. Actionable for professional therapists
            2. Readable by users (warm, supportive tone)
            3. Specific and evidence-based (no vague statements)
            4. Pattern-aware (track recurring themes)

            TRANSCRIPT:
            \(transcript)

            SESSION METADATA:
            Date: \(isoDate)
            Duration: \(context.durationMinutes) minutes
            Session Number: \(context.sessionOrdinal)

            USER PROFILE CONTEXT:
            \(profileBlock)
            Previous session topics: \(previousTopics)
            Active therapy goals: \(therapyGoals)
            Previous homework: \(previousHomework)

            ANALYSIS GUIDELINES:
            - Use "you" language throughout ("You realized…" not "The client realized…")
            - Quote user directly when possible (use their exact words)
            - Be specific with examples, never vague ("anxious about presentation" not "general stress")
            - Distinguish observation from interpretation
            - If user did not mention something, use null or empty arrays
            - If topic appeared in 3+ previous sessions, include it in patterns.recurringTopics
            - Track coping strategy effectiveness when possible

            WHAT MAKES A VALUABLE "KEY INSIGHT":
            Good: "You realized your anxiety isn't about the presentation content (you're prepared) but about judgment from your manager, which connects to a pattern of seeking external validation"
            Bad: "You felt anxious about work"
            
            The insight should reveal:
            - Root cause (not just symptom)
            - Connection to patterns
            - Actionable understanding for therapy

            SAFETY CRITICAL:
            - If user mentions self-harm, suicidal ideation, or harm to others:
              * set safetyAssessment.crisisRiskDetected = true
              * fill safetyAssessment.crisisNotes
              * include a professional-help recommendation
            - If no safety concerns, set safetyAssessment.crisisRiskDetected = false.

            SCHEMA (return valid JSON, no markdown):
            {"sessionMetadata":{"date":"ISO8601","durationMinutes":n,"sessionNumber":n},"summary":{"narrativeSummary":"2-3 sentences: what was discussed, discovered, and felt by end","primaryFocus":"main issue 1-2 words","relatedThemes":["theme1","theme2"]},"moodJourney":{"starting":{"description":"emotional state","intensity":1-10 or null,"physicalSymptoms":["tight chest"]},"ending":{"description":"emotional state","intensity":1-10 or null,"physicalSymptoms":["relaxed shoulders"]},"whatShifted":"what changed and why (1-2 sentences)"},"insights":{"keyInsight":"core realization about themselves - most valuable for therapist","userQuotes":["Direct quote from user"],"patternRecognized":"pattern they noticed or null"},"copingStrategies":{"attempted":[{"strategy":"Box breathing","effectiveness":"✅ Helped or ⚠️ Partial or ❌ Didn't help","userFeedback":"their words"}],"whatWorked":["strategy"],"whatDidntWork":["strategy"]},"patterns":{"recurringTopics":[{"topic":"Fear of manager judgment","frequency":"5 of last 6 sessions","firstMentioned":"Session 2","trend":"Increasing|Stable|Decreasing"}],"alertForTherapist":"pattern worth deeper exploration"},"progressTracking":{"previousHomework":{"assigned":"what was assigned","completion":"✅ Completed or ⚠️ Partial or ❌ Not done","userReflection":"their thoughts"},"therapyGoals":[{"goal":"Reduce anxiety before presentations","progress":"Some progress|No change|Significant progress","evidence":"what shows this"}]},"actionItems":{"forUser":["specific action to try"],"forTherapist":["question to explore","theme to discuss"],"newHomework":"small concrete exercise, achievable within a week"},"contextForContinuity":{"peoplesMentioned":[{"name":"Sarah","relationship":"Manager","significance":"trigger for evaluation fear"}],"upcomingEvents":[{"event":"Leadership presentation","date":"Tomorrow 2pm","anxietyLevel":"High (8/10)"}],"environmentalFactors":["Slept 4 hours","Skipped exercise"]},"safetyAssessment":{"crisisRiskDetected":boolean,"crisisNotes":"details if risk detected","protectiveFactors":["Supportive partner"],"recommendation":"Contact therapist immediately|Share at next session"},"clinicalObservations":{"dominantEmotions":["anxiety","fear","relief"],"primaryCopingStyle":"Cognitive reframing|Avoidance|etc","sessionEffectiveness":1-10 or null}}
            """
    }

    static func parseResponse(_ data: Data, preferredVersion: SummaryPromptVersion? = nil)
        -> SessionNotes?
    {
        guard let text = extractResponseText(from: data),
            let rawJSONString = extractJSONObject(from: text),
            let noteData = rawJSONString.data(using: .utf8)
        else {
            return nil
        }

        let resolvedVersion = preferredVersion ?? loadSummaryPromptVersion()

        switch resolvedVersion {
        case .v2:
            if let v2Notes = parseV2Response(from: noteData, rawJSONString: rawJSONString) {
                Task { await SummaryDiagnostics.shared.recordV2ParseSuccess() }
                return v2Notes
            }
            Task { await SummaryDiagnostics.shared.recordV2ParseFailure() }
            if let noteJSON = try? JSONSerialization.jsonObject(with: noteData) as? [String: Any] {
                return parseLegacyResponse(noteJSON, rawJSONString: rawJSONString)
            }
            return nil

        case .v1:
            if let noteJSON = try? JSONSerialization.jsonObject(with: noteData) as? [String: Any] {
                return parseLegacyResponse(noteJSON, rawJSONString: rawJSONString)
            }
            if let v2Notes = parseV2Response(from: noteData, rawJSONString: rawJSONString) {
                Task { await SummaryDiagnostics.shared.recordV2ParseSuccess() }
                return v2Notes
            }
            return nil
        }
    }

    private static func parseLegacyResponse(_ noteJSON: [String: Any], rawJSONString: String)
        -> SessionNotes
    {
        let mainTopics = stringArray(noteJSON["mainTopics"])
        let observedMood = cleanedString(noteJSON["observedMood"])
        let copingStrategies = stringArray(noteJSON["copingStrategies"])
        let keyInsights = cleanedString(noteJSON["keyInsights"])
        let suggestedFollowUp = cleanedString(noteJSON["suggestedFollowUp"])

        let narrativeSummary = cleanedString(noteJSON["narrativeSummary"])
        let moodStartDescription = cleanedString(noteJSON["moodStartDescription"])
        let moodEndDescription = cleanedString(noteJSON["moodEndDescription"])
        let moodShiftDescription = cleanedString(noteJSON["moodShiftDescription"])
        let keyInsight = cleanedString(noteJSON["keyInsight"])
        let userQuotes = stringArray(noteJSON["userQuotes"])
        let copingStrategiesExplored = stringArray(noteJSON["copingStrategiesExplored"])
        let actionItemsForTherapist = stringArray(noteJSON["actionItemsForTherapist"])
        let recurringPatternAlert = cleanedString(noteJSON["recurringPatternAlert"])
        let homework = cleanedString(noteJSON["homework"])

        let primaryFocus = cleanedString(noteJSON["primaryFocus"])
        let relatedThemes = stringArray(noteJSON["relatedThemes"])
        let moodStartIntensity = intValue(noteJSON["moodStartIntensity"])
        let moodEndIntensity = intValue(noteJSON["moodEndIntensity"])
        let moodStartPhysicalSymptoms = stringArray(noteJSON["moodStartPhysicalSymptoms"])
        let moodEndPhysicalSymptoms = stringArray(noteJSON["moodEndPhysicalSymptoms"])
        let patternRecognized = cleanedString(noteJSON["patternRecognized"])
        let recurringTopicsSnapshot = stringArray(noteJSON["recurringTopicsSnapshot"])
        let recurringTopicsTrend = cleanedString(noteJSON["recurringTopicsTrend"])
        let copingStrategiesAttempted = stringArray(noteJSON["copingStrategiesAttempted"])
        let copingStrategiesWorked = stringArray(noteJSON["copingStrategiesWorked"])
        let copingStrategiesDidntWork = stringArray(noteJSON["copingStrategiesDidntWork"])
        let previousHomeworkAssigned = cleanedString(noteJSON["previousHomeworkAssigned"])
        let previousHomeworkCompletion = cleanedString(noteJSON["previousHomeworkCompletion"])
        let previousHomeworkReflection = cleanedString(noteJSON["previousHomeworkReflection"])
        let therapyGoalProgress = stringArray(noteJSON["therapyGoalProgress"])
        let actionItemsForUser = stringArray(noteJSON["actionItemsForUser"])
        let continuityPeopleMentioned = stringArray(noteJSON["continuityPeopleMentioned"])
        let continuityUpcomingEvents = stringArray(noteJSON["continuityUpcomingEvents"])
        let continuityEnvironmentalFactors = stringArray(noteJSON["continuityEnvironmentalFactors"])
        let crisisRiskDetectedByModel = boolValue(noteJSON["crisisRiskDetectedByModel"])
        let crisisNotes = cleanedString(noteJSON["crisisNotes"])
        let protectiveFactors = stringArray(noteJSON["protectiveFactors"])
        let safetyRecommendation = cleanedString(noteJSON["safetyRecommendation"])
        let dominantEmotions = stringArray(noteJSON["dominantEmotions"])
        let primaryCopingStyle = cleanedString(noteJSON["primaryCopingStyle"])
        let sessionEffectivenessSelfRating = intValue(noteJSON["sessionEffectivenessSelfRating"])
        let sessionOrdinal = intValue(noteJSON["sessionOrdinal"])
        let schemaVersion = intValue(noteJSON["summarySchemaVersion"]) ?? 1

        return SessionNotes(
            mainTopics: mainTopics,
            observedMood: observedMood,
            copingStrategies: copingStrategies,
            keyInsights: keyInsights,
            suggestedFollowUp: suggestedFollowUp,
            narrativeSummary: narrativeSummary,
            moodStartDescription: moodStartDescription,
            moodEndDescription: moodEndDescription,
            moodShiftDescription: moodShiftDescription,
            keyInsight: keyInsight,
            userQuotes: userQuotes,
            copingStrategiesExplored: copingStrategiesExplored,
            actionItemsForTherapist: actionItemsForTherapist,
            recurringPatternAlert: recurringPatternAlert,
            homework: homework,
            summarySchemaVersion: schemaVersion,
            summaryRawJSON: rawJSONString,
            sessionOrdinal: sessionOrdinal,
            primaryFocus: primaryFocus,
            relatedThemes: relatedThemes,
            moodStartIntensity: moodStartIntensity,
            moodEndIntensity: moodEndIntensity,
            moodStartPhysicalSymptoms: moodStartPhysicalSymptoms,
            moodEndPhysicalSymptoms: moodEndPhysicalSymptoms,
            patternRecognized: patternRecognized,
            recurringTopicsSnapshot: recurringTopicsSnapshot,
            recurringTopicsTrend: recurringTopicsTrend,
            copingStrategiesAttempted: copingStrategiesAttempted,
            copingStrategiesWorked: copingStrategiesWorked,
            copingStrategiesDidntWork: copingStrategiesDidntWork,
            previousHomeworkAssigned: previousHomeworkAssigned,
            previousHomeworkCompletion: previousHomeworkCompletion,
            previousHomeworkReflection: previousHomeworkReflection,
            therapyGoalProgress: therapyGoalProgress,
            actionItemsForUser: actionItemsForUser,
            continuityPeopleMentioned: continuityPeopleMentioned,
            continuityUpcomingEvents: continuityUpcomingEvents,
            continuityEnvironmentalFactors: continuityEnvironmentalFactors,
            crisisRiskDetectedByModel: crisisRiskDetectedByModel,
            crisisNotes: crisisNotes,
            protectiveFactors: protectiveFactors,
            safetyRecommendation: safetyRecommendation,
            dominantEmotions: dominantEmotions,
            primaryCopingStyle: primaryCopingStyle,
            sessionEffectivenessSelfRating: sessionEffectivenessSelfRating
        )
    }

    private static func parseV2Response(from noteData: Data, rawJSONString: String) -> SessionNotes?
    {
        guard let decoded = try? JSONDecoder().decode(V2Response.self, from: noteData) else {
            return nil
        }

        // Reject decode if no V2-specific nested blocks are present —
        // flat legacy JSON decodes successfully with all-optional fields set to nil.
        guard
            decoded.summary != nil
                || decoded.moodJourney != nil
                || decoded.insights != nil
                || decoded.actionItems != nil
        else {
            return nil
        }

        let summary = decoded.summary
        let insights = decoded.insights
        let moodJourney = decoded.moodJourney
        let startingMood = moodJourney?.starting
        let endingMood = moodJourney?.ending
        let coping = decoded.copingStrategies
        let patterns = decoded.patterns
        let progress = decoded.progressTracking
        let actionItems = decoded.actionItems
        let continuity = decoded.contextForContinuity
        let safety = decoded.safetyAssessment
        let clinical = decoded.clinicalObservations

        var relatedThemes = normalizedStrings(summary?.relatedThemes)
        if relatedThemes.isEmpty {
            relatedThemes = normalizedStrings(patterns?.recurringTopics?.compactMap { $0.topic })
        }

        let primaryFocus = cleanedString(summary?.primaryFocus)
        var mainTopics = normalizedStrings([primaryFocus] + relatedThemes)
        if mainTopics.isEmpty {
            mainTopics = normalizedStrings(patterns?.recurringTopics?.compactMap { $0.topic })
        }

        let startDescription = formatMoodPoint(startingMood)
        let endDescription = formatMoodPoint(endingMood)
        let observedMood =
            !startDescription.isEmpty
            ? startDescription
            : normalizedStrings(clinical?.dominantEmotions).joined(separator: ", ")

        let attemptedStrategies = normalizedStrings(coping?.attempted?.compactMap { $0.strategy })
        let workedStrategies = normalizedStrings(coping?.whatWorked)
        let didntWorkStrategies = normalizedStrings(coping?.whatDidntWork)
        let legacyStrategies = !workedStrategies.isEmpty ? workedStrategies : attemptedStrategies

        let exploredStrategies = normalizedStrings(
            coping?.attempted?.compactMap { attempt in
                let strategy = cleanedString(attempt.strategy)
                guard !strategy.isEmpty else { return nil }
                let effectiveness = cleanedString(attempt.effectiveness)
                let feedback = cleanedString(attempt.userFeedback)

                if !effectiveness.isEmpty && !feedback.isEmpty {
                    return "\(effectiveness) \(strategy) → \(feedback)"
                }
                if !effectiveness.isEmpty {
                    return "\(effectiveness) \(strategy)"
                }
                if !feedback.isEmpty {
                    return "\(strategy) → \(feedback)"
                }
                return strategy
            }
        )

        let keyInsight = cleanedString(insights?.keyInsight)
        let keyInsights =
            !keyInsight.isEmpty
            ? keyInsight
            : cleanedString(summary?.narrativeSummary)

        let therapistItems = normalizedStrings(actionItems?.forTherapist)
        let suggestedFollowUp: String = {
            if let first = therapistItems.first, !first.isEmpty {
                return first
            }
            let patternAlert = cleanedString(patterns?.alertForTherapist)
            if !patternAlert.isEmpty {
                return patternAlert
            }
            return cleanedString(actionItems?.newHomework)
        }()

        let recurringTopics = normalizedStrings(patterns?.recurringTopics?.compactMap { $0.topic })
        let recurringTrend = cleanedString(
            patterns?.recurringTopics?.compactMap { cleanedString($0.trend) }.first { !$0.isEmpty })

        let therapyGoalProgress = normalizedStrings(
            progress?.therapyGoals?.compactMap { goal in
                let name = cleanedString(goal.goal)
                let progressText = cleanedString(goal.progress)
                let evidence = cleanedString(goal.evidence)

                if !name.isEmpty && !progressText.isEmpty && !evidence.isEmpty {
                    return "\(name): \(progressText) — \(evidence)"
                }
                if !name.isEmpty && !progressText.isEmpty {
                    return "\(name): \(progressText)"
                }
                if !name.isEmpty && !evidence.isEmpty {
                    return "\(name): \(evidence)"
                }
                return name.isEmpty ? nil : name
            })

        let peopleMentioned = normalizedStrings(
            continuity?.peoplesMentioned?.compactMap { person in
                let name = cleanedString(person.name)
                let relation = cleanedString(person.relationship)
                let significance = cleanedString(person.significance)

                if !name.isEmpty && !relation.isEmpty && !significance.isEmpty {
                    return "\(name) (\(relation)) — \(significance)"
                }
                if !name.isEmpty && !relation.isEmpty {
                    return "\(name) (\(relation))"
                }
                if !name.isEmpty && !significance.isEmpty {
                    return "\(name) — \(significance)"
                }
                return name.isEmpty ? nil : name
            })

        let upcomingEvents = normalizedStrings(
            continuity?.upcomingEvents?.compactMap { event in
                let title = cleanedString(event.event)
                let date = cleanedString(event.date)
                let anxiety = cleanedString(event.anxietyLevel)

                if !title.isEmpty && !date.isEmpty && !anxiety.isEmpty {
                    return "\(title) (\(date)) — \(anxiety)"
                }
                if !title.isEmpty && !date.isEmpty {
                    return "\(title) (\(date))"
                }
                if !title.isEmpty && !anxiety.isEmpty {
                    return "\(title) — \(anxiety)"
                }
                return title.isEmpty ? nil : title
            })

        let previousHomework = progress?.previousHomework

        return SessionNotes(
            mainTopics: mainTopics,
            observedMood: observedMood,
            copingStrategies: legacyStrategies,
            keyInsights: keyInsights,
            suggestedFollowUp: suggestedFollowUp,
            narrativeSummary: cleanedString(summary?.narrativeSummary),
            moodStartDescription: startDescription,
            moodEndDescription: endDescription,
            moodShiftDescription: cleanedString(moodJourney?.whatShifted),
            keyInsight: keyInsight,
            userQuotes: normalizedStrings(insights?.userQuotes),
            copingStrategiesExplored: exploredStrategies,
            actionItemsForTherapist: therapistItems,
            recurringPatternAlert: cleanedString(patterns?.alertForTherapist),
            homework: cleanedString(actionItems?.newHomework),
            summarySchemaVersion: 2,
            summaryRawJSON: rawJSONString,
            sessionOrdinal: decoded.sessionMetadata?.sessionNumber,
            primaryFocus: primaryFocus,
            relatedThemes: relatedThemes,
            moodStartIntensity: startingMood?.intensity?.value,
            moodEndIntensity: endingMood?.intensity?.value,
            moodStartPhysicalSymptoms: normalizedStrings(startingMood?.physicalSymptoms),
            moodEndPhysicalSymptoms: normalizedStrings(endingMood?.physicalSymptoms),
            patternRecognized: cleanedString(insights?.patternRecognized),
            recurringTopicsSnapshot: recurringTopics,
            recurringTopicsTrend: recurringTrend,
            copingStrategiesAttempted: attemptedStrategies,
            copingStrategiesWorked: workedStrategies,
            copingStrategiesDidntWork: didntWorkStrategies,
            previousHomeworkAssigned: cleanedString(previousHomework?.assigned),
            previousHomeworkCompletion: cleanedString(previousHomework?.completion),
            previousHomeworkReflection: cleanedString(previousHomework?.userReflection),
            therapyGoalProgress: therapyGoalProgress,
            actionItemsForUser: normalizedStrings(actionItems?.forUser),
            continuityPeopleMentioned: peopleMentioned,
            continuityUpcomingEvents: upcomingEvents,
            continuityEnvironmentalFactors: normalizedStrings(continuity?.environmentalFactors),
            crisisRiskDetectedByModel: safety?.crisisRiskDetected,
            crisisNotes: cleanedString(safety?.crisisNotes),
            protectiveFactors: normalizedStrings(safety?.protectiveFactors),
            safetyRecommendation: cleanedString(safety?.recommendation),
            dominantEmotions: normalizedStrings(clinical?.dominantEmotions),
            primaryCopingStyle: cleanedString(clinical?.primaryCopingStyle),
            sessionEffectivenessSelfRating: clinical?.sessionEffectiveness?.value
        )
    }

    private static func formatMoodPoint(_ point: V2MoodPoint?) -> String {
        guard let point else { return "" }
        var parts: [String] = []

        let description = cleanedString(point.description)
        if !description.isEmpty {
            parts.append(description)
        }

        if let intensity = point.intensity?.value {
            parts.append("\(intensity)/10")
        }

        let symptoms = normalizedStrings(point.physicalSymptoms)
        if !symptoms.isEmpty {
            parts.append(symptoms.joined(separator: ", "))
        }

        return parts.joined(separator: ", ")
    }

    private static func extractResponseText(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let candidates = json["candidates"] as? [[String: Any]],
            let first = candidates.first,
            let content = first["content"] as? [String: Any],
            let parts = content["parts"] as? [[String: Any]],
            let textPart = parts.first,
            let text = textPart["text"] as? String
        else {
            return nil
        }
        return text
    }

    private static func extractJSONObject(from text: String) -> String? {
        let cleaned =
            text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        var startIndex: String.Index?
        var depth = 0
        var inString = false
        var escape = false

        for index in cleaned.indices {
            let character = cleaned[index]

            if inString {
                if escape {
                    escape = false
                } else if character == "\\" {
                    escape = true
                } else if character == "\"" {
                    inString = false
                }
                continue
            }

            if character == "\"" {
                inString = true
                continue
            }

            if character == "{" {
                if depth == 0 {
                    startIndex = index
                }
                depth += 1
            } else if character == "}" {
                guard depth > 0 else { continue }
                depth -= 1
                if depth == 0, let startIndex {
                    return String(cleaned[startIndex...index])
                }
            }
        }

        return nil
    }

    private static func normalizedStrings(_ values: [String]?) -> [String] {
        let source = values ?? []
        var seen = Set<String>()
        var output: [String] = []
        for value in source {
            let cleaned = cleanedString(value)
            guard !cleaned.isEmpty else { continue }
            let key = cleaned.lowercased()
            if seen.insert(key).inserted {
                output.append(cleaned)
            }
        }
        return output
    }

    private static func stringArray(_ value: Any?) -> [String] {
        if let strings = value as? [String] {
            return normalizedStrings(strings)
        }
        if let values = value as? [Any] {
            return normalizedStrings(values.compactMap { $0 as? String })
        }
        if let string = value as? String {
            let normalized = cleanedString(string)
            return normalized.isEmpty ? [] : [normalized]
        }
        return []
    }

    private static func cleanedString(_ value: Any?) -> String {
        if let string = value as? String {
            return string.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return ""
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let intValue = value as? Int {
            return intValue
        }
        if let doubleValue = value as? Double {
            return Int(doubleValue.rounded())
        }
        if let stringValue = value as? String {
            let cleaned = stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if let direct = Int(cleaned) {
                return direct
            }
            let pattern = #"-?\d+"#
            guard let regex = try? NSRegularExpression(pattern: pattern) else {
                return nil
            }
            let nsRange = NSRange(cleaned.startIndex..<cleaned.endIndex, in: cleaned)
            guard let match = regex.firstMatch(in: cleaned, range: nsRange),
                let range = Range(match.range, in: cleaned)
            else {
                return nil
            }
            return Int(cleaned[range])
        }
        return nil
    }

    private static func boolValue(_ value: Any?) -> Bool? {
        if let boolValue = value as? Bool {
            return boolValue
        }
        if let stringValue = value as? String {
            switch stringValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "true", "yes", "1":
                return true
            case "false", "no", "0":
                return false
            default:
                return nil
            }
        }
        return nil
    }

    static func loadSummaryPromptVersion() -> SummaryPromptVersion {
        let info = Bundle.main.infoDictionary ?? [:]
        let env = ProcessInfo.processInfo.environment
        let rawVersion =
            env["GEMINI_SUMMARY_PROMPT_VERSION"]
            ?? info["GEMINI_SUMMARY_PROMPT_VERSION"] as? String            ?? "v2"

        return SummaryPromptVersion(rawValue: rawVersion.lowercased()) ?? .v2
    }

    private static func loadSummaryModel() -> String {
        let info = Bundle.main.infoDictionary ?? [:]
        let env = ProcessInfo.processInfo.environment
        let configured =
            env["GEMINI_SUMMARY_MODEL"] ?? info["GEMINI_SUMMARY_MODEL"] as? String
            ?? "gemini-2.5-flash"
        if configured.hasPrefix("models/") {
            return configured
        }
        return "models/\(configured)"
    }

    private static func retryAfterSeconds(from response: HTTPURLResponse) -> TimeInterval? {
        let headers = response.allHeaderFields
        for (key, value) in headers {
            let keyString = String(describing: key).lowercased()
            guard keyString == "retry-after" else { continue }
            let valueString = String(describing: value).trimmingCharacters(
                in: .whitespacesAndNewlines)
            if let seconds = TimeInterval(valueString) {
                return max(0, seconds)
            }
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss z"
            if let date = formatter.date(from: valueString) {
                return max(0, date.timeIntervalSinceNow)
            }
        }
        return nil
    }
    
    // MARK: - Vertex AI Fallback Support
    
    struct VertexAIConfig {
        let projectId: String
        let location: String
        let modelName: String?
        let serviceAccountKeyPath: String?
        let apiKey: String?
        
        var isConfigured: Bool {
            !projectId.isEmpty && !location.isEmpty
        }
    }
    
    private static func loadVertexAIConfig() -> VertexAIConfig {
        let info = Bundle.main.infoDictionary ?? [:]
        let env = ProcessInfo.processInfo.environment
        
        return VertexAIConfig(
            projectId: env["VERTEX_AI_PROJECT_ID"] ?? info["VERTEX_AI_PROJECT_ID"] as? String ?? "gen-lang-client-0481856273",
            location: env["VERTEX_AI_LOCATION"] ?? info["VERTEX_AI_LOCATION"] as? String ?? "us-central1",
            modelName: env["VERTEX_AI_MODEL"] ?? info["VERTEX_AI_MODEL"] as? String,
            serviceAccountKeyPath: env["VERTEX_AI_KEY_PATH"] ?? info["VERTEX_AI_KEY_PATH"] as? String,
            apiKey: env["VERTEX_AI_API_KEY"] ?? info["VERTEX_AI_API_KEY"] as? String ?? "AQ.Ab8RN6ID9JKl0SDpm_Cxp0g0ucZy0bLNALpeLoytJbKrESxCtQ"
        )
    }
    
    /// Get access token for Vertex AI
    /// Uses service account key file if available, otherwise tries application default credentials
    private static func getVertexAIAccessToken(config: VertexAIConfig) async -> String? {
        // Try to load service account key from file
        if let keyPath = config.serviceAccountKeyPath,
           let keyData = try? Data(contentsOf: URL(fileURLWithPath: keyPath)),
           let keyJson = try? JSONSerialization.jsonObject(with: keyData) as? [String: Any],
           let clientEmail = keyJson["client_email"] as? String,
           let privateKey = keyJson["private_key"] as? String {
            return await generateJWTToken(clientEmail: clientEmail, privateKey: privateKey)
        }
        
        // Fallback: try to get token from metadata server (works on GCP/cloud environments)
        return await fetchMetadataToken()
    }
    
    /// Generate JWT token for service account authentication
    private static func generateJWTToken(clientEmail: String, privateKey: String) async -> String? {
        // Placeholder: JWT token generation requires crypto libraries
        // In production, use GoogleSignIn or GoogleAPIClientForREST SDK
        print("[SessionSummarizer] JWT token generation requires crypto libraries for \(clientEmail). Consider using Google Sign-In SDK.")
        _ = privateKey // Silence unused parameter warning
        return nil
    }
    
    /// Fetch token from GCP metadata server (works when running on GCP or with gcloud auth)
    private static func fetchMetadataToken() async -> String? {
        let url = URL(string: "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token")!
        var request = URLRequest(url: url)
        request.setValue("Google-Metadata-Request: True", forHTTPHeaderField: "Metadata-Flavor")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
               let token = json["access_token"] {
                return token
            }
        } catch {
            print("[SessionSummarizer] Metadata token fetch failed: \(error)")
        }
        return nil
    }
    
    // MARK: - Test Functions
    
    /// Test Vertex AI connectivity with a direct API call
    /// Run this on app launch or from debug menu to verify configuration
    static func runVertexAITest() {
        Task {
            let config = loadVertexAIConfig()
            
            print("[SessionSummarizer] ========== VERTEX AI TEST ==========")
            print("  Project ID: \(config.projectId)")
            print("  Location: \(config.location)")
            print("  Model: \(config.modelName ?? "gemini-2.5-flash")")
            print("  API Key: \(config.apiKey?.prefix(10) ?? "nil")...")
            
            guard config.isConfigured else {
                print("  ❌ FAILED: Vertex AI not configured")
                return
            }
            
            let modelName = config.modelName ?? "gemini-2.5-flash"
            let url = URL(
                string: "https://\(config.location)-aiplatform.googleapis.com/v1/projects/\(config.projectId)/locations/\(config.location)/publishers/google/models/\(modelName):generateContent?key=\(config.apiKey ?? "")"
            )!
            
            print("  URL: \(url.absoluteString)")
            
            let body: [String: Any] = [
                "contents": [
                    ["parts": [["text": "Hello, this is a test. Respond with: 'Vertex AI test successful!'"]]]
                ],
                "generationConfig": [
                    "temperature": 0.1,
                    "maxOutputTokens": 100,
                ],
            ]
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
                print("  ❌ FAILED: Could not serialize request")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("  ❌ FAILED: No HTTP response")
                    return
                }
                
                print("  Status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let candidates = json["candidates"] as? [[String: Any]],
                       let first = candidates.first,
                       let content = first["content"] as? [String: Any],
                       let parts = content["parts"] as? [[String: Any]],
                       let text = parts.first?["text"] as? String {
                        print("  ✅ SUCCESS: \(text.trimmingCharacters(in: .whitespacesAndNewlines))")
                    } else {
                        print("  ⚠️  Got 200 but could not parse response")
                        print("  Raw: \(String(data: data, encoding: .utf8) ?? "nil")")
                    }
                } else {
                    print("  ❌ FAILED: HTTP \(httpResponse.statusCode)")
                    print("  Response: \(String(data: data, encoding: .utf8) ?? "nil")")
                }
            } catch {
                print("  ❌ FAILED: \(error.localizedDescription)")
            }
            
            print("[SessionSummarizer] ========== END TEST ==========")
        }
    }
}

actor SummaryDiagnostics {
    static let shared = SummaryDiagnostics()

    private(set) var v2ParseSuccessCount = 0
    private(set) var v2ParseFailureCount = 0
    private(set) var fallbackToV1Count = 0

    func recordV2ParseSuccess() {
        v2ParseSuccessCount += 1
    }

    func recordV2ParseFailure() {
        v2ParseFailureCount += 1
    }

    func recordFallbackToV1() {
        fallbackToV1Count += 1
    }

    func snapshot() -> (v2ParseSuccess: Int, v2ParseFailure: Int, fallbackToV1: Int) {
        (v2ParseSuccessCount, v2ParseFailureCount, fallbackToV1Count)
    }
}

actor SummaryRateLimiter {
    static let shared = SummaryRateLimiter()
    private var nextAllowedDate: Date = .distantPast
    private let minInterval: TimeInterval = 12
    private var inFlightHashes: Set<Int> = []

    /// Execute with deduplication - same request won't run twice simultaneously
    func execute<T: Sendable>(
        requestHash: Int,
        operation: @Sendable () async -> T
    ) async -> T {
        // Wait if same request is already in-flight
        while inFlightHashes.contains(requestHash) {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms poll
        }
        
        // Rate limit check
        let now = Date()
        if now < nextAllowedDate {
            let wait = nextAllowedDate.timeIntervalSince(now)
            if wait > 0 {
                try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
            }
        }
        
        // Mark as in-flight
        inFlightHashes.insert(requestHash)
        
        let result = await operation()
        
        // Clear tracking
        inFlightHashes.remove(requestHash)
        
        // Set next allowed time
        let candidate = Date().addingTimeInterval(minInterval)
        if candidate > nextAllowedDate {
            nextAllowedDate = candidate
        }
        return result
    }

    func imposeCooldown(seconds: TimeInterval) {
        let target = Date().addingTimeInterval(max(0, seconds))
        if target > nextAllowedDate {
            nextAllowedDate = target
        }
    }
}
