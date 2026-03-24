import XCTest
@testable import Liminal

final class ResonanceRuleTests: XCTestCase {

    private func makeRule() -> ResonanceRule {
        ResonanceRule(shaderParams: [
            "resonantSpeed": 0.55, "falloffWidth": 0.15,
            "maxAmplitude": 0.3, "vibrationFrequency": 12.0
        ])
    }

    func testResonanceOneAtExactSpeed() {
        let rule = makeRule()
        let state = makeState(speed: 0.55)
        let output = rule.evaluate(playerState: state)
        XCTAssertEqual(output.shaderUniforms["resonance"] ?? -1, 1.0, accuracy: 0.01)
    }

    func testResonanceZeroBeyondFalloff() {
        let rule = makeRule()
        let state = makeState(speed: 0.0)  // 0.55 away, well beyond 0.15 falloff
        let output = rule.evaluate(playerState: state)
        XCTAssertEqual(output.shaderUniforms["resonance"] ?? -1, 0.0, accuracy: 0.01)
    }

    func testResonanceZeroAtFalloffEdge() {
        let rule = makeRule()
        let state = makeState(speed: 0.55 + 0.15)  // exactly at edge
        let output = rule.evaluate(playerState: state)
        XCTAssertEqual(output.shaderUniforms["resonance"] ?? -1, 0.0, accuracy: 0.01)
    }

    func testVibrationAmplitudeScalesWithResonance() {
        let rule = makeRule()
        let state = makeState(speed: 0.55)  // resonance = 1.0
        let output = rule.evaluate(playerState: state)
        XCTAssertEqual(output.shaderUniforms["vibrationAmplitude"] ?? -1, 0.3, accuracy: 0.01)
    }

    func testPitchShiftScalesWithResonance() {
        let rule = makeRule()
        let atResonance = rule.evaluate(playerState: makeState(speed: 0.55))
        let offResonance = rule.evaluate(playerState: makeState(speed: 0.0))
        let resPitch = atResonance.audioParameters["pitchShiftSemitones"] ?? 0
        let offPitch = offResonance.audioParameters["pitchShiftSemitones"] ?? 0
        XCTAssertGreaterThan(resPitch, offPitch)
    }

    private func makeState(speed: Float) -> PlayerState {
        PlayerState(position: .zero, velocity: .zero, speed: speed,
                    lookDirection: SIMD3(0, 0, -1), idleSeconds: 0, deltaTime: 0.016)
    }
}
