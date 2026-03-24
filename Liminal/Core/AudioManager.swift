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
    private var timePitch: AVAudioUnitTimePitch?
    private var reverb: AVAudioUnitReverb?
    private var environmentNode: AVAudioEnvironmentNode?
    private var sourceNode: AVAudioSourceNode?

    // Pitch ramping state
    private var targetPitchCents: Float = 0
    private var currentPitchCents: Float = 0
    private let rampSpeed: Float = 1000  // cents/sec

    private init() {}

    // MARK: - Configuration

    func configure(audioConfig: AudioConfig) throws {
        stopEngine()

        let engine = AVAudioEngine()
        let timePitch = AVAudioUnitTimePitch()
        let reverb = AVAudioUnitReverb()
        let environmentNode = AVAudioEnvironmentNode()

        reverb.loadFactoryPreset(.cathedral)
        reverb.wetDryMix = Float(audioConfig.parameters["reverbMix"] ?? 0.6) * 100

        environmentNode.listenerPosition = AVAudio3DPoint(x: 0, y: 1.7, z: 0)
        environmentNode.renderingAlgorithm = .HRTFHQ

        engine.attach(timePitch)
        engine.attach(reverb)
        engine.attach(environmentNode)

        // Determine a mono format for connections where no audio file exists
        let sampleRate = engine.mainMixerNode.outputFormat(forBus: 0).sampleRate
        let fallbackFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)

        if let sources = audioConfig.sources, !sources.isEmpty {
            // Multi-source mode (Space 4: two audio sources at 3D positions)
            for sourceDef in sources {
                let playerNode = AVAudioPlayerNode()
                engine.attach(playerNode)

                playerNode.position = AVAudio3DPoint(
                    x: sourceDef.position.count > 0 ? sourceDef.position[0] : 0,
                    y: sourceDef.position.count > 1 ? sourceDef.position[1] : 1.7,
                    z: sourceDef.position.count > 2 ? sourceDef.position[2] : 0
                )

                if let url = Bundle.main.url(forResource: sourceDef.stem, withExtension: "caf",
                                             subdirectory: "Resources/Audio"),
                   let audioFile = try? AVAudioFile(forReading: url) {
                    engine.connect(playerNode, to: timePitch, format: audioFile.processingFormat)
                    let frameCount = AVAudioFrameCount(audioFile.length)
                    if let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat,
                                                      frameCapacity: frameCount) {
                        try audioFile.read(into: buffer)
                        playerNode.scheduleBuffer(buffer, at: nil, options: .loops)
                    }
                } else {
                    engine.connect(playerNode, to: timePitch, format: fallbackFormat)
                }

                playerNodes.append(playerNode)
            }
        } else {
            // Single-source mode
            let audioURL = Bundle.main.url(forResource: audioConfig.stem, withExtension: "caf",
                                           subdirectory: "Resources/Audio")

            if let url = audioURL, let audioFile = try? AVAudioFile(forReading: url) {
                let playerNode = AVAudioPlayerNode()
                engine.attach(playerNode)
                engine.connect(playerNode, to: timePitch, format: audioFile.processingFormat)

                let frameCount = AVAudioFrameCount(audioFile.length)
                if let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat,
                                                  frameCapacity: frameCount) {
                    try audioFile.read(into: buffer)
                    playerNode.scheduleBuffer(buffer, at: nil, options: .loops)
                }
                playerNodes.append(playerNode)
            } else {
                #if DEBUG
                // Procedural fallback: sine wave drone
                let sampleRate = engine.mainMixerNode.outputFormat(forBus: 0).sampleRate
                let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

                var phase: Double = 0
                let baseFreq: Double = 80.0

                let sourceNode = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList -> OSStatus in
                    let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
                    let phaseIncrement = baseFreq / sampleRate
                    for frame in 0..<Int(frameCount) {
                        let sample = Float(
                            sin(phase * 2 * .pi) * 0.2 +
                            sin(phase * 4 * .pi) * 0.08 +
                            sin(phase * 6 * .pi) * 0.04
                        )
                        for buf in ablPointer {
                            let channelData = buf.mData?.assumingMemoryBound(to: Float.self)
                            channelData?[frame] = sample
                        }
                        phase += phaseIncrement
                        if phase >= 1.0 { phase -= 1.0 }
                    }
                    return noErr
                }

                engine.attach(sourceNode)
                engine.connect(sourceNode, to: timePitch, format: format)
                self.sourceNode = sourceNode
                #else
                let playerNode = AVAudioPlayerNode()
                engine.attach(playerNode)
                engine.connect(playerNode, to: timePitch, format: fallbackFormat)
                playerNodes.append(playerNode)
                #endif
            }
        }

        // Graph: TimePitch → Reverb → EnvironmentNode → MainMixer
        // AVAudioEnvironmentNode requires explicit format for connections
        let outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        let monoFormat = AVAudioFormat(standardFormatWithSampleRate: outputFormat.sampleRate, channels: 1)
        engine.connect(timePitch, to: reverb, format: monoFormat)
        engine.connect(reverb, to: environmentNode, format: monoFormat)
        engine.connect(environmentNode, to: engine.mainMixerNode, format: nil)

        self.engine = engine
        self.timePitch = timePitch
        self.reverb = reverb
        self.environmentNode = environmentNode
        self.targetPitchCents = 0
        self.currentPitchCents = 0

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
        timePitch = nil
        reverb = nil
        environmentNode = nil
        sourceNode = nil
        NotificationCenter.default.removeObserver(self)
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
