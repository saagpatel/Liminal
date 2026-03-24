import XCTest
@testable import Liminal

final class ChromaticDecayRuleTests: XCTestCase {

    func testZeroIdleProducesNoDesaturation() {
        let rule = ChromaticDecayRule(shaderParams: ["maxDesaturationSeconds": 15.0])
        let state = makeState(speed: 0.5, idleSeconds: 0)
        let output = rule.evaluate(playerState: state)
        XCTAssertEqual(output.shaderUniforms["desaturation"] ?? -1, 0.0, accuracy: 0.01)
    }

    func testDesaturationRampsUpWhenIdle() {
        let rule = ChromaticDecayRule(shaderParams: ["maxDesaturationSeconds": 15.0])
        // Simulate 7.5 seconds of idle (half of 15s)
        for _ in 0..<450 {  // 450 frames at 60fps ≈ 7.5s
            _ = rule.evaluate(playerState: makeState(speed: 0, idleSeconds: 10, deltaTime: 1.0 / 60.0))
        }
        let output = rule.evaluate(playerState: makeState(speed: 0, idleSeconds: 10, deltaTime: 1.0 / 60.0))
        let desaturation = output.shaderUniforms["desaturation"] ?? -1
        XCTAssertEqual(desaturation, 0.5, accuracy: 0.05)
    }

    func testDesaturationClampsAtOne() {
        let rule = ChromaticDecayRule(shaderParams: ["maxDesaturationSeconds": 1.0])
        // Way more than needed to reach 1.0
        for _ in 0..<200 {
            _ = rule.evaluate(playerState: makeState(speed: 0, idleSeconds: 10, deltaTime: 0.016))
        }
        let output = rule.evaluate(playerState: makeState(speed: 0, idleSeconds: 10, deltaTime: 0.016))
        XCTAssertEqual(output.shaderUniforms["desaturation"] ?? -1, 1.0, accuracy: 0.01)
    }

    func testDesaturationDecreasesDuringMovement() {
        let rule = ChromaticDecayRule(shaderParams: [
            "maxDesaturationSeconds": 1.0, "resaturationRate": 1.0
        ])
        // Saturate
        for _ in 0..<100 {
            _ = rule.evaluate(playerState: makeState(speed: 0, idleSeconds: 10, deltaTime: 0.016))
        }
        // Now move
        for _ in 0..<30 {
            _ = rule.evaluate(playerState: makeState(speed: 0.5, idleSeconds: 0, deltaTime: 0.016))
        }
        let output = rule.evaluate(playerState: makeState(speed: 0.5, idleSeconds: 0, deltaTime: 0.016))
        let desaturation = output.shaderUniforms["desaturation"] ?? 999
        XCTAssertLessThan(desaturation, 0.7, "Desaturation should decrease during movement")
    }

    func testReverbScalesWithDesaturation() {
        let rule = ChromaticDecayRule(shaderParams: ["maxDesaturationSeconds": 1.0])
        let activeOutput = rule.evaluate(playerState: makeState(speed: 0.5, idleSeconds: 0))
        // Saturate fully
        for _ in 0..<100 {
            _ = rule.evaluate(playerState: makeState(speed: 0, idleSeconds: 10, deltaTime: 0.016))
        }
        let idleOutput = rule.evaluate(playerState: makeState(speed: 0, idleSeconds: 10, deltaTime: 0.016))

        let activeReverb = activeOutput.audioParameters["reverbMix"] ?? 0
        let idleReverb = idleOutput.audioParameters["reverbMix"] ?? 0
        XCTAssertGreaterThan(idleReverb, activeReverb)
    }

    private func makeState(speed: Float, idleSeconds: Float = 0,
                           deltaTime: Float = 0.016) -> PlayerState {
        PlayerState(position: .zero, velocity: .zero, speed: speed,
                    lookDirection: SIMD3(0, 0, -1), idleSeconds: idleSeconds, deltaTime: deltaTime)
    }
}
