//
//  AmbientSoundPlayer.swift
//  Anchor
//
//  Lightweight ambient sound generator (soft noise loop).
//

import AVFoundation
import Foundation

final class AmbientSoundPlayer {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var buffer: AVAudioPCMBuffer?
    private var isConfigured = false
    private var previousCategory: AVAudioSession.Category?
    private var previousMode: AVAudioSession.Mode?
    private var previousOptions: AVAudioSession.CategoryOptions = []
    private var didOverrideSession = false

    func start() {
        configureIfNeeded()
        guard let buffer else { return }
        if !engine.isRunning {
            let session = AVAudioSession.sharedInstance()
            if !didOverrideSession {
                previousCategory = session.category
                previousMode = session.mode
                previousOptions = session.categoryOptions
                didOverrideSession = true
            }
            try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try? session.setActive(true, options: [])
            try? engine.start()
        }
        if !player.isPlaying {
            player.scheduleBuffer(buffer, at: nil, options: [.loops])
            player.play()
        }
    }

    func stop() {
        player.stop()
        engine.stop()
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
        if didOverrideSession, let previousCategory, let previousMode {
            try? session.setCategory(previousCategory, mode: previousMode, options: previousOptions)
            didOverrideSession = false
        }
    }

    private func configureIfNeeded() {
        guard !isConfigured else { return }
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)
        guard let format else { return }

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.15

        buffer = makeNoiseBuffer(format: format, duration: 2.5)
        isConfigured = true
    }

    private func makeNoiseBuffer(format: AVAudioFormat, duration: TimeInterval) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount

        guard let channel = buffer.floatChannelData?.pointee else { return buffer }
        var lastSample: Float = 0
        for i in 0..<Int(frameCount) {
            let white = Float.random(in: -1...1)
            // Simple low-pass to soften the noise.
            lastSample = (lastSample * 0.98) + (white * 0.02)
            channel[i] = lastSample * 0.25
        }
        return buffer
    }
}
