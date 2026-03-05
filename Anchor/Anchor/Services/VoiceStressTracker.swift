//
//  VoiceStressTracker.swift
//  Anchor
//
//  Heuristic voice stress estimator using amplitude variance and speech activity.
//

import Foundation

final class VoiceStressTracker {
    private let lock = NSLock()
    private var voicedDuration: TimeInterval = 0
    private var totalDuration: TimeInterval = 0
    private var rmsSum: Double = 0
    private var rmsSquaredSum: Double = 0
    private var voicedSamples: Int = 0
    private var zcrSum: Double = 0
    private var zcrCount: Int = 0
    private var pitchSum: Double = 0
    private var pitchSquaredSum: Double = 0
    private var pitchCount: Int = 0
    private var centroidSum: Double = 0
    private var centroidSquaredSum: Double = 0
    private var centroidCount: Int = 0
    private var syllableCount: Int = 0
    private var lastPitchPeriod: Double?
    private var jitterSum: Double = 0
    private var jitterCount: Int = 0
    private var lastRms: Double?
    private var shimmerSum: Double = 0
    private var shimmerCount: Int = 0
    private let mlScorer = VoiceStressMLScorer.shared

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        voicedDuration = 0
        totalDuration = 0
        rmsSum = 0
        rmsSquaredSum = 0
        voicedSamples = 0
        zcrSum = 0
        zcrCount = 0
        pitchSum = 0
        pitchSquaredSum = 0
        pitchCount = 0
        centroidSum = 0
        centroidSquaredSum = 0
        centroidCount = 0
        syllableCount = 0
        lastPitchPeriod = nil
        jitterSum = 0
        jitterCount = 0
        lastRms = nil
        shimmerSum = 0
        shimmerCount = 0
    }

    func addSample(
        rms: Float,
        duration: TimeInterval,
        isVoice: Bool,
        zcr: Double?,
        pitchHz: Double?,
        centroidHz: Double?,
        syllableCount: Int
    ) {
        lock.lock()
        defer { lock.unlock() }
        totalDuration += duration
        guard isVoice else { return }
        voicedDuration += duration
        let value = Double(rms)
        rmsSum += value
        rmsSquaredSum += value * value
        voicedSamples += 1
        self.syllableCount += syllableCount

        if let zcr {
            zcrSum += zcr
            zcrCount += 1
        }

        if let pitchHz, pitchHz > 0 {
            pitchSum += pitchHz
            pitchSquaredSum += pitchHz * pitchHz
            pitchCount += 1

            let period = 1.0 / pitchHz
            if let lastPitchPeriod, lastPitchPeriod > 0 {
                let jitter = abs(period - lastPitchPeriod) / lastPitchPeriod
                jitterSum += jitter
                jitterCount += 1
            }
            lastPitchPeriod = period
        }

        if let centroidHz {
            centroidSum += centroidHz
            centroidSquaredSum += centroidHz * centroidHz
            centroidCount += 1
        }

        if let lastRms, lastRms > 0 {
            let shimmer = abs(value - lastRms) / lastRms
            shimmerSum += shimmer
            shimmerCount += 1
        }
        lastRms = value
    }

    func score(baseline: Double? = nil) -> Double? {
        let snapshot: (
            voicedSamples: Int,
            totalDuration: TimeInterval,
            rmsSum: Double,
            rmsSquaredSum: Double,
            voicedDuration: TimeInterval,
            zcrSum: Double,
            zcrCount: Int,
            pitchSum: Double,
            pitchSquaredSum: Double,
            pitchCount: Int,
            centroidSum: Double,
            centroidSquaredSum: Double,
            centroidCount: Int,
            syllableCount: Int,
            jitterSum: Double,
            jitterCount: Int,
            shimmerSum: Double,
            shimmerCount: Int
        )
        lock.lock()
        snapshot = (
            voicedSamples,
            totalDuration,
            rmsSum,
            rmsSquaredSum,
            voicedDuration,
            zcrSum,
            zcrCount,
            pitchSum,
            pitchSquaredSum,
            pitchCount,
            centroidSum,
            centroidSquaredSum,
            centroidCount,
            syllableCount,
            jitterSum,
            jitterCount,
            shimmerSum,
            shimmerCount
        )
        lock.unlock()

        guard snapshot.voicedSamples > 4, snapshot.totalDuration > 0 else { return nil }
        let mean = snapshot.rmsSum / Double(snapshot.voicedSamples)
        let variance = max(0, (snapshot.rmsSquaredSum / Double(snapshot.voicedSamples)) - (mean * mean))
        let stdDev = sqrt(variance)
        let activityRatio = min(1.0, snapshot.voicedDuration / snapshot.totalDuration)
        let speechRate = snapshot.voicedDuration > 0 ? Double(snapshot.syllableCount) / snapshot.voicedDuration : 0

        let pitchMean = snapshot.pitchCount > 0 ? snapshot.pitchSum / Double(snapshot.pitchCount) : 0
        let pitchVariance = snapshot.pitchCount > 0
            ? max(0, (snapshot.pitchSquaredSum / Double(snapshot.pitchCount)) - (pitchMean * pitchMean))
            : 0
        let pitchStd = sqrt(pitchVariance)

        let centroidMean = snapshot.centroidCount > 0 ? snapshot.centroidSum / Double(snapshot.centroidCount) : 0

        let jitterMean = snapshot.jitterCount > 0 ? snapshot.jitterSum / Double(snapshot.jitterCount) : 0
        let shimmerMean = snapshot.shimmerCount > 0 ? snapshot.shimmerSum / Double(snapshot.shimmerCount) : 0
        let zcrMean = snapshot.zcrCount > 0 ? snapshot.zcrSum / Double(snapshot.zcrCount) : 0

        // Normalize using empirically reasonable ranges for speech RMS.
        let meanScore = min(1.0, mean / 0.06)
        let varianceScore = min(1.0, stdDev / 0.03)
        let activityScore = min(1.0, activityRatio / 0.7)
        let speechRateScore = max(0, min(1.0, (speechRate - 2.5) / 3.5))
        let pitchMeanScore = max(0, min(1.0, (pitchMean - 120) / 160))
        let pitchStdScore = min(1.0, pitchStd / 60)
        let centroidScore = max(0, min(1.0, (centroidMean - 1200) / 2000))
        let jitterScore = min(1.0, jitterMean / 0.02)
        let shimmerScore = min(1.0, shimmerMean / 0.06)
        let zcrScore = max(0, min(1.0, (zcrMean - 0.05) / 0.2))

        let scores: [(Double, Double)] = [
            (meanScore, 0.17),
            (varianceScore, 0.11),
            (activityScore, 0.09),
            (speechRateScore, 0.12),
            (pitchMeanScore, 0.08),
            (pitchStdScore, 0.10),
            (centroidScore, 0.10),
            (jitterScore, 0.09),
            (shimmerScore, 0.09),
            (zcrScore, 0.05)
        ]

        let available = scores.filter { !$0.0.isNaN }
        let weightSum = available.reduce(0) { $0 + $1.1 }
        let weighted = available.reduce(0) { $0 + ($1.0 * $1.1) } / max(0.001, weightSum)
        var score = max(0, min(100, weighted * 100))

        if let baseline {
            let delta = score - baseline
            score = max(0, min(100, 50 + delta * 0.7))
        }

        if let mlScore = mlScorer.score(features: VoiceStressFeatureVector(
            meanRms: mean,
            rmsStd: stdDev,
            activityRatio: activityRatio,
            speechRate: speechRate,
            pitchMean: pitchMean,
            pitchStd: pitchStd,
            centroidMean: centroidMean,
            jitter: jitterMean,
            shimmer: shimmerMean,
            zcr: zcrMean
        )) {
            let blended = (score * 0.7) + (mlScore * 100 * 0.3)
            score = max(0, min(100, blended))
        }

        return score
    }
}
