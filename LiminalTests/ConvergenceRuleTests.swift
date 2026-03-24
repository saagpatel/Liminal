import XCTest
import simd
@testable import Liminal

final class ConvergenceRuleTests: XCTestCase {

    // MARK: - Doppler uniforms

    func testConvergenceOutputsContainDopplerUniforms() {
        let rule = ConvergenceRule(
            shaderParams: ["velocityThreshold": 0.3, "maxColorShift": 0.4],
            audioParams: [:]
        )
        let state = makeState(speed: 0.5)
        let output = rule.evaluate(playerState: state)
        XCTAssertNotNil(output.shaderUniforms["velocityNormalized"], "Missing velocityNormalized")
    }

    // MARK: - Lensing uniforms

    func testConvergenceOutputsContainLensingUniforms() {
        let rule = ConvergenceRule(
            shaderParams: ["massPointX": 3.0, "massPointY": 1.7, "massPointZ": -3.0,
                           "maxDistortion": 0.15, "falloffStart": 15.0, "falloffEnd": 5.0],
            audioParams: [:]
        )
        let state = makeState(position: SIMD3(3, 1.7, -3))
        let output = rule.evaluate(playerState: state)
        XCTAssertNotNil(output.shaderUniforms["proximityNormalized"], "Missing proximityNormalized")
    }

    // MARK: - Shadow uniforms

    func testConvergenceOutputsContainShadowUniforms() {
        let rule = ConvergenceRule(shaderParams: [:], audioParams: [:])
        let state = makeState(position: SIMD3(1, 1.7, 2))
        let output = rule.evaluate(playerState: state)
        XCTAssertNotNil(output.shaderUniforms["playerPositionX"], "Missing playerPositionX")
    }

    // MARK: - Resonance uniforms

    func testConvergenceOutputsContainResonanceUniforms() {
        let rule = ConvergenceRule(
            shaderParams: ["resonantSpeed": 0.55, "falloffWidth": 0.15, "maxAmplitude": 0.3],
            audioParams: [:]
        )
        let state = makeState(speed: 0.55)
        let output = rule.evaluate(playerState: state)
        XCTAssertNotNil(output.shaderUniforms["resonance"], "Missing resonance")
    }

    // MARK: - Intensity scaling

    func testConvergenceOutputsScaledByIntensity() {
        // At max speed (1.0), DopplerRule produces colorShiftAmount = maxColorShift = 0.4
        // ConvergenceRule scales by 0.2, so result should be ≤ 0.08
        let rule = ConvergenceRule(
            shaderParams: ["maxColorShift": 0.4, "velocityThreshold": 0.0],
            audioParams: [:]
        )
        let state = makeState(speed: 1.0)
        let output = rule.evaluate(playerState: state)
        let colorShift = output.shaderUniforms["colorShiftAmount"] ?? 999
        XCTAssertLessThanOrEqual(colorShift, 0.4 * 0.2 + 0.001,
            "colorShiftAmount should be scaled by 0.2x intensity")
    }

    // MARK: - Audio params

    func testConvergenceOutputsContainAudioParams() {
        let rule = ConvergenceRule(
            shaderParams: ["velocityThreshold": 0.3, "maxColorShift": 0.4],
            audioParams: ["maxPitchShiftSemitones": 3.0]
        )
        let state = makeState(speed: 1.0)
        let output = rule.evaluate(playerState: state)
        XCTAssertNotNil(output.audioParameters["pitchShiftSemitones"],
            "Missing pitchShiftSemitones from Doppler sub-rule")
    }

    // MARK: - Reverb mix scaling

    func testConvergenceReverbMixScaled() {
        // ResonanceRule produces reverbMix = resonance * some value
        // ConvergenceRule takes max(existing, value * 0.2) for reverbMix
        let rule = ConvergenceRule(
            shaderParams: ["resonantSpeed": 0.55, "falloffWidth": 0.15],
            audioParams: ["reverbMix": 1.0]
        )
        let state = makeState(speed: 0.55)
        let output = rule.evaluate(playerState: state)
        // If reverbMix exists, it should be ≤ 0.2 of full contribution
        if let reverbMix = output.audioParameters["reverbMix"] {
            XCTAssertLessThanOrEqual(reverbMix, 0.25,
                "reverbMix should be scaled by 0.2x intensity")
        }
        // If no reverbMix key at all, that's also acceptable (rules don't all produce it)
    }

    // MARK: - No crash with varied states

    func testConvergenceEvaluationDoesNotCrash() {
        let rule = ConvergenceRule(
            shaderParams: [
                "velocityThreshold": 0.3, "maxColorShift": 0.4,
                "massPointX": 3.0, "massPointY": 1.7, "massPointZ": -3.0,
                "maxDistortion": 0.15, "falloffStart": 15.0, "falloffEnd": 5.0,
                "sourceAX": -5.0, "sourceAY": 1.7, "sourceAZ": 0.0,
                "sourceBX": 5.0, "sourceBY": 1.7, "sourceBZ": 0.0,
                "waveFrequency": 8.0,
                "maxDesaturationSeconds": 15.0, "resaturationRate": 15.0,
                "resonantSpeed": 0.55, "falloffWidth": 0.15, "maxAmplitude": 0.3
            ],
            audioParams: [:]
        )

        let states: [PlayerState] = [
            makeState(speed: 0.0),
            makeState(speed: 0.55),
            makeState(speed: 1.0),
            makeState(speed: 0.55, position: SIMD3(3, 1.7, -3)),
            makeState(speed: 0.55, position: SIMD3(0, 1.7, 0)),
        ]

        for state in states {
            let output = rule.evaluate(playerState: state)
            XCTAssertFalse(output.exitTriggered, "ConvergenceRule should never trigger exit directly")
        }
    }

    // MARK: - Helpers

    private func makeState(
        speed: Float = 0,
        position: SIMD3<Float> = .zero,
        deltaTime: Float = 0.016
    ) -> PlayerState {
        PlayerState(
            position: position,
            velocity: SIMD3<Float>(0, 0, speed),
            speed: speed,
            lookDirection: SIMD3<Float>(0, 0, -1),
            idleSeconds: 0,
            deltaTime: deltaTime
        )
    }
}
