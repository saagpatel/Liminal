import XCTest
import simd
@testable import Liminal

final class ShadowRuleTests: XCTestCase {

    func testPlayerPositionPassedAsUniforms() {
        let rule = ShadowRule(shaderParams: ["shadowIntensity": 0.7])
        let state = PlayerState(
            position: SIMD3(3.5, 1.7, -2.0), velocity: .zero, speed: 0,
            lookDirection: SIMD3(0, 0, -1), idleSeconds: 0, deltaTime: 0.016
        )
        let output = rule.evaluate(playerState: state)
        XCTAssertEqual(output.shaderUniforms["playerPositionX"] ?? -999, 3.5, accuracy: 0.01)
        XCTAssertEqual(output.shaderUniforms["playerPositionY"] ?? -999, 1.7, accuracy: 0.01)
        XCTAssertEqual(output.shaderUniforms["playerPositionZ"] ?? -999, -2.0, accuracy: 0.01)
    }

    func testShadowIntensityFromParams() {
        let rule = ShadowRule(shaderParams: ["shadowIntensity": 0.5])
        let state = PlayerState(
            position: .zero, velocity: .zero, speed: 0,
            lookDirection: SIMD3(0, 0, -1), idleSeconds: 0, deltaTime: 0.016
        )
        let output = rule.evaluate(playerState: state)
        XCTAssertEqual(output.shaderUniforms["shadowIntensity"] ?? -1, 0.5, accuracy: 0.01)
    }

    func testOutputIncludesAllRequiredUniforms() {
        let rule = ShadowRule(shaderParams: ["shadowIntensity": 0.7])
        let state = PlayerState(
            position: SIMD3(1, 2, 3), velocity: .zero, speed: 0,
            lookDirection: SIMD3(0, 0, -1), idleSeconds: 0, deltaTime: 0.016
        )
        let output = rule.evaluate(playerState: state)
        XCTAssertNotNil(output.shaderUniforms["playerPositionX"])
        XCTAssertNotNil(output.shaderUniforms["playerPositionY"])
        XCTAssertNotNil(output.shaderUniforms["playerPositionZ"])
        XCTAssertNotNil(output.shaderUniforms["shadowIntensity"])
    }
}
