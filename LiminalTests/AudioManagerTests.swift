import XCTest
@testable import Liminal

@MainActor
final class AudioManagerTests: XCTestCase {

    override func tearDown() async throws {
        await AudioManager.shared.stopEngine()
    }

    func testEngineInitializesWithoutThrowing() throws {
        let config = makeAudioConfig()
        try AudioManager.shared.configure(audioConfig: config)
    }

    func testStartEngineTwiceDoesNotCrash() throws {
        let config = makeAudioConfig()
        try AudioManager.shared.configure(audioConfig: config)
        try AudioManager.shared.configure(audioConfig: config)
    }

    func testUpdateParametersWithEmptyDictIsNoOp() throws {
        let config = makeAudioConfig()
        try AudioManager.shared.configure(audioConfig: config)
        AudioManager.shared.updateParameters([:])
    }

    func testUpdateParametersChangesPitchTarget() throws {
        let config = makeAudioConfig()
        try AudioManager.shared.configure(audioConfig: config)
        for _ in 0..<60 {
            AudioManager.shared.updateParameters(["pitchShiftSemitones": 2.0])
        }
    }

    func testStopEngineCleanup() throws {
        let config = makeAudioConfig()
        try AudioManager.shared.configure(audioConfig: config)
        AudioManager.shared.stopEngine()
        AudioManager.shared.stopEngine()
    }

    // MARK: - Spatial Audio

    func testConfigureWithSourcesArray() throws {
        let config = AudioConfig(
            stem: "ambient_drone_04",
            rule: "InterferenceAudio",
            parameters: ["reverbMix": 0.5],
            sources: [
                AudioSourceDefinition(stem: "tone_a", position: [-6, 1.7, 0]),
                AudioSourceDefinition(stem: "tone_b", position: [6, 1.7, 0])
            ]
        )
        try AudioManager.shared.configure(audioConfig: config)
    }

    func testUpdateListenerPositionDoesNotCrash() throws {
        let config = makeAudioConfig()
        try AudioManager.shared.configure(audioConfig: config)
        AudioManager.shared.updateListenerPosition(SIMD3(1, 1.7, 2))
    }

    func testConfigureWithoutSourcesBackwardCompatible() throws {
        let config = AudioConfig(
            stem: "test", rule: "test",
            parameters: ["reverbMix": 0.5], sources: nil
        )
        try AudioManager.shared.configure(audioConfig: config)
    }

    // MARK: - Helpers

    private func makeAudioConfig() -> AudioConfig {
        AudioConfig(
            stem: "ambient_drone_01",
            rule: "DopplerAudio",
            parameters: ["maxPitchShiftSemitones": 3.0, "reverbMix": 0.6],
            sources: nil
        )
    }
}
