import AVFoundation

/// AVAudioEngine manager with 3D spatial audio via AVAudioEnvironmentNode.
/// Supports single-source (Spaces 1-3, 5-6) and multi-source (Space 4) configurations.
///
/// Graph: Source(s) → TimePitch → Reverb → EnvironmentNode → MainMixer → Output
@MainActor
final class AudioManager {
    static let shared = AudioManager()

    private var engine: AVAudioEngine?
    private var playerNodes: [AVAudioPlayerNode] = []
    private var preEffectsMixer: AVAudioMixerNode?
    private var timePitch: AVAudioUnitTimePitch?
    private var reverb: AVAudioUnitReverb?
    private var environmentNode: AVAudioEnvironmentNode?

    private(set) var usesProceduralAudio = false
    var masterVolume: Float { engine?.mainMixerNode.outputVolume ?? 0 }
    var isEngineRunning: Bool { engine?.isRunning ?? false }

    // Pitch ramping state
    private var targetPitchCents: Float = 0
    private var currentPitchCents: Float = 0
    private let rampSpeed: Float = 1000  // cents/sec

    private init() {}

    // MARK: - Configuration

    func configure(audioConfig: AudioConfig) throws {
        stopEngine()

        let engine = AVAudioEngine()
        let preEffectsMixer = AVAudioMixerNode()
        let timePitch = AVAudioUnitTimePitch()
        let reverb = AVAudioUnitReverb()
        let environmentNode = AVAudioEnvironmentNode()

        reverb.loadFactoryPreset(.cathedral)
        reverb.wetDryMix = Float(audioConfig.parameters["reverbMix"] ?? 0.6) * 100

        environmentNode.listenerPosition = AVAudio3DPoint(x: 0, y: 1.7, z: 0)
        environmentNode.renderingAlgorithm = .HRTFHQ

        engine.attach(preEffectsMixer)
        engine.attach(timePitch)
        engine.attach(reverb)
        engine.attach(environmentNode)

        // Determine a mono format for procedural release-safe audio.
        let sampleRate = engine.mainMixerNode.outputFormat(forBus: 0).sampleRate
        guard let fallbackFormat = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate, channels: 1
        ) else {
            throw AudioManagerError.unsupportedOutputFormat
        }

        if let sources = audioConfig.sources, !sources.isEmpty {
            // Multi-source mode (Space 4: two audio sources at 3D positions)
            for (index, sourceDef) in sources.enumerated() {
                let playerNode = AVAudioPlayerNode()
                engine.attach(playerNode)

                playerNode.position = AVAudio3DPoint(
                    x: sourceDef.position.count > 0 ? sourceDef.position[0] : 0,
                    y: sourceDef.position.count > 1 ? sourceDef.position[1] : 1.7,
                    z: sourceDef.position.count > 2 ? sourceDef.position[2] : 0
                )

                if let url = Bundle.main.url(forResource: sourceDef.stem, withExtension: "caf",
                                             subdirectory: "Audio"),
                   let audioFile = try? AVAudioFile(forReading: url) {
                    engine.connect(playerNode, to: preEffectsMixer, format: audioFile.processingFormat)
                    let frameCount = AVAudioFrameCount(audioFile.length)
                    if let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat,
                                                      frameCapacity: frameCount) {
                        try audioFile.read(into: buffer)
                        playerNode.scheduleBuffer(buffer, at: nil, options: .loops)
                    }
                } else {
                    engine.connect(playerNode, to: preEffectsMixer, format: fallbackFormat)
                    let frequency = 72.0 + Double(index) * 11.0
                    if let buffer = Self.makeProceduralDrone(
                        format: fallbackFormat, frequency: frequency
                    ) {
                        playerNode.scheduleBuffer(buffer, at: nil, options: .loops)
                        usesProceduralAudio = true
                    }
                }

                playerNodes.append(playerNode)
            }
        } else {
            // Single-source mode
            let audioURL = Bundle.main.url(forResource: audioConfig.stem, withExtension: "caf",
                                           subdirectory: "Audio")

            if let url = audioURL, let audioFile = try? AVAudioFile(forReading: url) {
                let playerNode = AVAudioPlayerNode()
                engine.attach(playerNode)
                engine.connect(playerNode, to: preEffectsMixer, format: audioFile.processingFormat)

                let frameCount = AVAudioFrameCount(audioFile.length)
                if let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat,
                                                  frameCapacity: frameCount) {
                    try audioFile.read(into: buffer)
                    playerNode.scheduleBuffer(buffer, at: nil, options: .loops)
                }
                playerNodes.append(playerNode)
            } else {
                let playerNode = AVAudioPlayerNode()
                engine.attach(playerNode)
                engine.connect(playerNode, to: preEffectsMixer, format: fallbackFormat)
                if let buffer = Self.makeProceduralDrone(format: fallbackFormat, frequency: 80) {
                    playerNode.scheduleBuffer(buffer, at: nil, options: .loops)
                    usesProceduralAudio = true
                }
                playerNodes.append(playerNode)
            }
        }

        // Graph: TimePitch → Reverb → EnvironmentNode → MainMixer
        // AVAudioEnvironmentNode requires explicit format for connections
        let outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        let monoFormat = AVAudioFormat(standardFormatWithSampleRate: outputFormat.sampleRate, channels: 1)
        engine.connect(preEffectsMixer, to: timePitch, format: monoFormat)
        engine.connect(timePitch, to: reverb, format: monoFormat)
        engine.connect(reverb, to: environmentNode, format: monoFormat)
        engine.connect(environmentNode, to: engine.mainMixerNode, format: nil)

        self.engine = engine
        self.preEffectsMixer = preEffectsMixer
        self.timePitch = timePitch
        self.reverb = reverb
        self.environmentNode = environmentNode
        self.targetPitchCents = 0
        self.currentPitchCents = 0

        let savedVolume = UserDefaults.standard.object(forKey: "liminal.volume") == nil
            ? 1
            : UserDefaults.standard.float(forKey: "liminal.volume")
        engine.mainMixerNode.outputVolume = min(max(savedVolume, 0), 1)

        try engine.start()

        NotificationCenter.default.addObserver(
            self, selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification, object: nil
        )
    }

    func startPlayback() {
        for node in playerNodes {
            node.play()
        }
    }

    func setMasterVolume(_ volume: Float) {
        engine?.mainMixerNode.outputVolume = min(max(volume, 0), 1)
    }

    func suspendForBackground() {
        engine?.pause()
    }

    func resumeAfterBackground() {
        guard let engine, !engine.isRunning else { return }
        do {
            try engine.start()
            for node in playerNodes where !node.isPlaying {
                node.play()
            }
        } catch {
            #if DEBUG
            print("[AudioManager] Resume failed: \(error)")
            #endif
        }
    }

    // MARK: - Per-frame updates

    func updateParameters(_ parameters: [String: Float]) {
        // Pitch ramping
        if let semitones = parameters["pitchShiftSemitones"] {
            targetPitchCents = semitones * 100
        }
        let dt: Float = 1.0 / 60.0
        let diff = targetPitchCents - currentPitchCents
        if abs(diff) > 0.1 {
            let step = Swift.min(abs(diff), rampSpeed * dt) * (diff > 0 ? 1 : -1)
            currentPitchCents += step
        } else {
            currentPitchCents = targetPitchCents
        }
        timePitch?.pitch = currentPitchCents

        // Amplitude control (for interference space)
        if let amplitude = parameters["amplitude"] {
            for node in playerNodes {
                node.volume = amplitude
            }
        }
    }

    func updateListenerPosition(_ position: SIMD3<Float>) {
        environmentNode?.listenerPosition = AVAudio3DPoint(x: position.x, y: position.y, z: position.z)
    }

    // MARK: - Lifecycle

    func stopEngine() {
        for node in playerNodes {
            node.stop()
        }
        playerNodes.removeAll()
        engine?.stop()
        engine = nil
        preEffectsMixer = nil
        timePitch = nil
        reverb = nil
        environmentNode = nil
        usesProceduralAudio = false
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Procedural fallback

    private static func makeProceduralDrone(
        format: AVAudioFormat,
        frequency: Double,
        duration: Double = 4
    ) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channels = buffer.floatChannelData else { return nil }
        buffer.frameLength = frameCount

        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / format.sampleRate
            let edge = min(1, min(time / 0.08, (duration - time) / 0.08))
            let sample = Float((
                sin(time * 2 * .pi * frequency) * 0.16 +
                sin(time * 2 * .pi * frequency * 1.5) * 0.06 +
                sin(time * 2 * .pi * frequency * 2) * 0.03
            ) * edge)
            for channel in 0..<Int(format.channelCount) {
                channels[channel][frame] = sample
            }
        }
        return buffer
    }

    // MARK: - Interruption handling

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        if type == .ended {
            let options = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            if AVAudioSession.InterruptionOptions(rawValue: options).contains(.shouldResume) {
                try? engine?.start()
                for node in playerNodes { node.play() }
            }
        }
    }
}

enum AudioManagerError: Error {
    case unsupportedOutputFormat
}
