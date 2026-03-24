import XCTest
import simd
@testable import Liminal

final class InterferenceRuleTests: XCTestCase {

    private func makeRule() -> InterferenceRule {
        InterferenceRule(shaderParams: [
            "sourceAX": -6.0, "sourceAY": 1.7, "sourceAZ": 0.0,
            "sourceBX": 6.0, "sourceBY": 1.7, "sourceBZ": 0.0,
            "waveFrequency": 8.0
        ])
    }

    func testCancellationHighAtMidpoint() {
        let rule = makeRule()
        let state = makeState(position: SIMD3(0, 1.7, 0))  // exact midpoint
        let output = rule.evaluate(playerState: state)
        let cancellation = output.shaderUniforms["cancellationFactor"] ?? -1
        XCTAssertGreaterThan(cancellation, 0.8, "Cancellation should be high at midpoint")
    }

    func testCancellationLowNearSource() {
        let rule = makeRule()
        let state = makeState(position: SIMD3(-5.5, 1.7, 0))  // near source A
        let output = rule.evaluate(playerState: state)
        let cancellation = output.shaderUniforms["cancellationFactor"] ?? 999
        XCTAssertLessThan(cancellation, 0.3, "Cancellation should be low near a source")
    }

    func testAmplitudeInverseOfCancellation() {
        let rule = makeRule()
        let state = makeState(position: SIMD3(0, 1.7, 0))
        let output = rule.evaluate(playerState: state)
        let cancellation = output.shaderUniforms["cancellationFactor"] ?? 0
        let amplitude = output.audioParameters["amplitude"] ?? 0
        XCTAssertEqual(amplitude + cancellation, 1.0, accuracy: 0.01)
    }

    func testSourcePositionsPassedAsUniforms() {
        let rule = makeRule()
        let state = makeState(position: .zero)
        let output = rule.evaluate(playerState: state)
        XCTAssertEqual(output.shaderUniforms["sourceAX"] ?? 0, -6.0, accuracy: 0.01)
        XCTAssertEqual(output.shaderUniforms["sourceBX"] ?? 0, 6.0, accuracy: 0.01)
    }

    func testWaveFrequencyPassedThrough() {
        let rule = makeRule()
        let state = makeState(position: .zero)
        let output = rule.evaluate(playerState: state)
        XCTAssertEqual(output.shaderUniforms["waveFrequency"] ?? 0, 8.0, accuracy: 0.01)
    }

    private func makeState(position: SIMD3<Float>) -> PlayerState {
        PlayerState(position: position, velocity: .zero, speed: 0,
                    lookDirection: SIMD3(0, 0, -1), idleSeconds: 0, deltaTime: 0.016)
    }
}
