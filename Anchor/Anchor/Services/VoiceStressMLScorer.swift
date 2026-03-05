//
//  VoiceStressMLScorer.swift
//  Anchor
//
//  Optional CoreML scorer for voice stress features.
//  If no model is bundled, the scorer returns nil.
//

import CoreML
import Foundation

struct VoiceStressFeatureVector {
    let meanRms: Double
    let rmsStd: Double
    let activityRatio: Double
    let speechRate: Double
    let pitchMean: Double
    let pitchStd: Double
    let centroidMean: Double
    let jitter: Double
    let shimmer: Double
    let zcr: Double
}

final class VoiceStressMLScorer {
    static let shared = VoiceStressMLScorer()

    private let model: MLModel?

    private init() {
        if let url = Bundle.main.url(forResource: "VoiceStressClassifier", withExtension: "mlmodelc") {
            model = try? MLModel(contentsOf: url)
        } else {
            model = nil
        }
    }

    func score(features: VoiceStressFeatureVector) -> Double? {
        guard let model else { return nil }

        let dict: [String: MLFeatureValue] = [
            "mean_rms": MLFeatureValue(double: features.meanRms),
            "rms_std": MLFeatureValue(double: features.rmsStd),
            "activity_ratio": MLFeatureValue(double: features.activityRatio),
            "speech_rate": MLFeatureValue(double: features.speechRate),
            "pitch_mean": MLFeatureValue(double: features.pitchMean),
            "pitch_std": MLFeatureValue(double: features.pitchStd),
            "centroid_mean": MLFeatureValue(double: features.centroidMean),
            "jitter": MLFeatureValue(double: features.jitter),
            "shimmer": MLFeatureValue(double: features.shimmer),
            "zcr": MLFeatureValue(double: features.zcr)
        ]

        guard let provider = try? MLDictionaryFeatureProvider(dictionary: dict),
              let output = try? model.prediction(from: provider) else {
            return nil
        }

        let preferredKeys = ["stressScore", "stress", "output", "score"]
        let outputValue: Double? = preferredKeys.compactMap { key in
            output.featureValue(for: key)?.doubleValue
        }.first ?? output.featureNames.compactMap { name in
            output.featureValue(for: name)?.doubleValue
        }.first

        guard let raw = outputValue else { return nil }

        if raw > 1.5 {
            return max(0, min(1, raw / 100))
        }
        return max(0, min(1, raw))
    }
}
