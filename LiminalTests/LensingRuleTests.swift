import XCTest
import simd
@testable import Liminal

final class LensingRuleTests: XCTestCase {

    private func makeRule() -> LensingRule {
        LensingRule(shaderParams: [
            "massPointX": 5.0, "massPointY": 3.0, "massPointZ": 0.0,
            "maxDistortion": 0.15, "falloffStart": 15.0, "falloffEnd": 5.0
        ])
    }

    func testProximityZeroWhenFar() {
        let rule = makeRule()
        let state = makeState(position: SIMD3(50, 3, 0))  // way beyond falloffStart
        let output = rule.evaluate(playerState: state)
        XCTAssertEqual(output.shaderUniforms["proximityNormalized"] ?? -1, 0.0, accuracy: 0.01)
    }

    func testProximityOneWhenAtMassPoint() {
        let rule = makeRule()
        let state = makeState(position: SIMD3(5, 3, 0))  // at mass point
        let output = rule.evaluate(playerState: state)
        XCTAssertEqual(output.shaderUniforms["proximityNormalized"] ?? -1, 1.0, accuracy: 0.01)
    }

    func testProximityInterpolatesBetweenFalloffs() {
        let rule = makeRule()
        // Midpoint between falloffEnd (5) and falloffStart (15) = distance 10 from mass point
        let state = makeState(position: SIMD3(15, 3, 0))  // 10 units from mass point at (5,3,0)
        let output = rule.evaluate(playerState: state)
        let proximity = output.shaderUniforms["proximityNormalized"] ?? -1
        XCTAssertGreaterThan(proximity, 0.0)
        XCTAssertLessThan(proximity, 1.0)
    }

    func testDistortionScalesWithProximity() {
        let rule = makeRule()
        let state = makeState(position: SIMD3(5, 3, 0))
        let output = rule.evaluate(playerState: state)
        // At proximity 1.0, distortion = 1.0 * 0.15 = 0.15
        XCTAssertEqual(output.shaderUniforms["distortionAmount"] ?? -1, 0.15, accuracy: 0.01)
    }

    func testReverbDeepensNearMassPoint() {
        let rule = makeRule()
        let farState = makeState(position: SIMD3(50, 3, 0))
        let nearState = makeState(position: SIMD3(5, 3, 0))
        let farReverb = rule.evaluate(playerState: farState).audioParameters["reverbMix"] ?? 0
        let nearReverb = rule.evaluate(playerState: nearState).audioParameters["reverbMix"] ?? 0
        XCTAssertGreaterThan(nearReverb, farReverb)
    }

    private func makeState(position: SIMD3<Float>) -> PlayerState {
        PlayerState(position: position, velocity: .zero, speed: 0,
                    lookDirection: SIMD3(0, 0, -1), idleSeconds: 0, deltaTime: 0.016)
    }
}
