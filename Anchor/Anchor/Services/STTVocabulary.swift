//
//  STTVocabulary.swift
//  Anchor
//
//  Domain-specific vocabulary for improved speech recognition accuracy.
//

import Foundation

/// Shared vocabulary for local STT systems to improve recognition of/// therapy and mental health terminology.
struct STTVocabulary {
    static let shared = STTVocabulary()
    
    /// Contextual strings to help STT recognize domain-specific terms
    let contextualStrings: [String] = {
        var words: [String] = []
        
        // Mental health & therapy terms
        words += [
            "anxiety", "depression", "panic", "trauma", "PTSD",
            "bipolar", "ADHD", "OCD", "therapist", "therapy",
            "counseling", "counselor", "psychiatrist", "psychologist",
            "medication", "prescription", "diagnosis", "treatment",
            "cognitive behavioral", "CBT", "DBT", "mindfulness",
            "meditation", "grounding", "breathing exercise",
            "panic attack", "anxiety attack", "flashback",
            "dissociation", "depersonalization", "derealization",
            "intrusive thoughts", "rumination", "overthinking"
        ]
        
        // Emotional states
        words += [
            "overwhelmed", "stressed", "anxious", "worried",
            "frustrated", "irritated", "angry", "furious",
            "sad", "depressed", "hopeless", "empty",
            "lonely", "isolated", "disconnected",
            "exhausted", "tired", "fatigued", "drained",
            "guilty", "ashamed", "embarrassed",
            "scared", "fearful", "terrified", "paranoid",
            "numb", "detached", "disassociated"
        ]
        
        // Coping strategies
        words += [
            "coping", "strategy", "technique", "tool",
            "breathing", "box breathing", "4-7-8 breathing",
            "grounding", "5-4-3-2-1", "sensory grounding",
            "journaling", "journaling prompt", "gratitude",
            "self-care", "self-compassion", "self-soothing",
            "distraction", "reframing", "challenging thoughts",
            "exposure", "progressive muscle relaxation",
            "PMR", "visualization", "guided imagery"
        ]
        
        // Relationships & social
        words += [
            "partner", "spouse", "boyfriend", "girlfriend",
            "parent", "mother", "father", "mom", "dad",
            "child", "children", "kid", "kids",
            "family", "sibling", "brother", "sister",
            "friend", "friendship", "colleague", "coworker",
            "boss", "manager", "supervisor",
            "boundary", "boundaries", "communication",
            "conflict", "argument", "disagreement",
            "support system", "support network"
        ]
        
        // Work & life stressors
        words += [
            "work", "job", "career", "workplace",
            "burnout", "overworked", "deadline", "pressure",
            "school", "student", "exam", "test", "grade",
            "financial", "money", "debt", "bills", "expenses",
            "housing", "rent", "mortgage", "landlord",
            "health", "medical", "doctor", "appointment",
            "sleep", "insomnia", "tired", "fatigue"
        ]
        
        // Crisis & safety terms
        words += [
            "crisis", "emergency", "urgent",
            "suicide", "suicidal", "self-harm", "cutting",
            "988", "hotline", "helpline",
            "hospital", "ER", "emergency room",
            "safety plan", "crisis plan", "coping plan"
        ]
        
        // Therapy session terms
        words += [
            "session", "appointment", "check-in",
            "homework", "between sessions", "practice",
            "breakthrough", "insight", "realization",
            "pattern", "trigger", "warning sign",
            "progress", "setback", "relapse",
            "goal", "intention", "focus"
        ]
        
        return words
    }()
    
    /// Common phrases that might be misrecognized
    let commonPhrases: [String: String] = [
        "i'm anxious": "I'm anxious",
        "panic attack": "panic attack",
        "can't breathe": "can't breathe",
        "heart racing": "heart racing",
        "over thinking": "overthinking",
        "self care": "self-care",
        "burn out": "burnout",
        "break down": "breakdown",
        "mental health": "mental health",
        "therapy session": "therapy session"
    ]
    
    /// Post-process transcription to fix common misrecognitions
    func postProcessTranscription(_ text: String) -> String {
        var result = text
        
        // Fix WhisperKit-style spaced words (e.g., "ab solu tely" -> "absolutely")
        // This happens when Whisper tokenizes incorrectly
        result = fixSpacedWords(result)
        
        // Apply common phrase corrections
        for (misrecognized, corrected) in commonPhrases {
            result = result.replacingOccurrences(
                of: misrecognized,
                with: corrected,
                options: .caseInsensitive
            )
        }
        
        // Capitalize first letter of sentences
        if !result.isEmpty {
            result = result.prefix(1).uppercased() + result.dropFirst()
        }
        
        return result
    }
    
    /// Fixes words that have been incorrectly spaced by WhisperKit
    /// e.g., "ab solu tely" -> "absolutely", "tran scrip tion" -> "transcription"
    private func fixSpacedWords(_ text: String) -> String {
        // Pattern: match sequences of 2-4 short letter groups (2-4 chars each) separated by single spaces
        // that together form what looks like a single word
        let pattern = #"\b([a-zA-Z]{2,4})\s+([a-zA-Z]{2,4})\s+([a-zA-Z]{2,4})(?:\s+([a-zA-Z]{2,4}))?\b"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return text
        }
        
        let nsRange = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: nsRange)
        
        var result = text
        // Process matches in reverse to preserve ranges
        for match in matches.reversed() {
            guard let range = Range(match.range, in: result) else { continue }
            
            let matchedText = String(result[range])
            let combined = matchedText.replacingOccurrences(of: " ", with: "")
            
            // Check if combined form is a valid English word (basic heuristic)
            // Only join if the combined word looks reasonable
            if combined.count >= 6 && isLikelyWord(combined) {
                result.replaceSubrange(range, with: combined)
            }
        }
        
        // Also handle 2-part splits (e.g., "che cking" -> "checking")
        let twoPartPattern = #"\b([a-zA-Z]{2,5})\s+([a-zA-Z]{3,6})\b"#
        guard let twoPartRegex = try? NSRegularExpression(pattern: twoPartPattern, options: []) else {
            return result
        }
        
        let twoPartMatches = twoPartRegex.matches(in: result, options: [], range: NSRange(result.startIndex..., in: result))
        for match in twoPartMatches.reversed() {
            guard let range = Range(match.range, in: result) else { continue }
            
            let matchedText = String(result[range])
            let combined = matchedText.replacingOccurrences(of: " ", with: "")
            
            // Check against common word list or heuristic
            if combined.count >= 5 && (commonWords.contains(combined.lowercased()) || isLikelyWord(combined)) {
                result.replaceSubrange(range, with: combined)
            }
        }
        
        return result
    }
    
    /// Simple heuristic to check if a string looks like a valid English word
    private func isLikelyWord(_ word: String) -> Bool {
        let lowercased = word.lowercased()
        
        // Check against common English patterns
        // Vowel check - most English words have vowels
        let vowels = CharacterSet(charactersIn: "aeiou")
        let hasVowel = lowercased.unicodeScalars.contains { vowels.contains($0) }
        guard hasVowel else { return false }
        
        // Check for unreasonable consonant clusters
        let unreasonableClusters = ["bcdf", "fghj", "jklm", "npqr", "stvw", "xyz"]
        for cluster in unreasonableClusters {
            if lowercased.contains(cluster) {
                return false
            }
        }
        
        return true
    }
    
    /// Common English words to check against for 2-part corrections
    private let commonWords: Set<String> = {
        var words: Set<String> = [
            // Common words that get split
            "checking", "absolutely", "hate", "transcription", "taking",
            "working", "thinking", "feeling", "talking", "walking",
            "looking", "making", "taking", "giving", "having",
            "going", "coming", "doing", "saying", "getting",
            "knowing", "seeing", "finding", "trying", "using",
            "nothing", "everything", "something", "anything",
            "someone", "anyone", "everyone", "nobody",
            "however", "although", "because", "before", "after",
            "another", "through", "between", "without", "within",
            "problem", "question", "answer", "reason", "person",
            "people", "place", "thing", "time", "year", "week",
            "month", "today", "tomorrow", "yesterday",
            "morning", "evening", "night", "minute", "second",
            "maybe", "perhaps", "probably", "definitely",
            "really", "actually", "basically", "literally",
            "especially", "usually", "always", "never",
            "understand", "remember", "forget", "believe",
            "realize", "recognize", "experience", "situation"
        ]
        return words
    }()
}
