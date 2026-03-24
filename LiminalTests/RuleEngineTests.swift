import XCTest
@testable import Liminal

final class RuleEngineTests: XCTestCase {

    func testDopplerRuleAtZeroSpeed() {
        let rule = DopplerRule()
        let state = makePlayerState(speed: 0.0)
        let output = rule.evaluate(playerState: state)

        assertUniform(output.shaderUniforms, key: "velocityNormalized", expected: 0.0)
        assertUniform(output.shaderUniforms, key: "colorShiftAmount", expected: 0.0)
        assertUniform(output.audioParameters, key: "pitchShiftSemitones", expected: 0.0)
    }

    func testDopplerRuleBelowThreshold() {
        let rule = DopplerRule()
        let state = makePlayerState(speed: 0.25)
        let output = rule.evaluate(playerState: state)

        // 0.25 < 0.3 threshold → no shift
        assertUniform(output.shaderUniforms, key: "colorShiftAmount", expected: 0.0)
        assertUniform(output.audioParameters, key: "pitchShiftSemitones", expected: 0.0)
    }

    func testDopplerRuleAtHalfSpeed() {
        let rule = DopplerRule()
        let state = makePlayerState(speed: 0.5)
        let output = rule.evaluate(playerState: state)

        // intensity = (0.5 - 0.3) / (1.0 - 0.3) ≈ 0.286
        // colorShift = 0.286 * 0.4 ≈ 0.114
        assertUniform(output.shaderUniforms, key: "velocityNormalized", expected: 0.5)
        let colorShift = output.shaderUniforms["colorShiftAmount"] ?? -1
        XCTAssertGreaterThan(colorShift, 0.0)
        XCTAssertLessThan(colorShift, 0.2)
    }

    func testDopplerRuleAtThreeQuarterSpeed() {
        let rule = DopplerRule()
        let state = makePlayerState(speed: 0.75)
        let output = rule.evaluate(playerState: state)

        // intensity = (0.75 - 0.3) / (1.0 - 0.3) ≈ 0.643
        // colorShift = 0.643 * 0.4 ≈ 0.257
        assertUniform(output.shaderUniforms, key: "velocityNormalized", expected: 0.75)
        let colorShift = output.shaderUniforms["colorShiftAmount"] ?? -1
        XCTAssertGreaterThan(colorShift, 0.2)
        XCTAssertLessThan(colorShift, 0.35)
    }

    func testDopplerRuleAtMaxSpeed() {
        let rule = DopplerRule()
        let state = makePlayerState(speed: 1.0)
        let output = rule.evaluate(playerState: state)

        // intensity = 1.0, colorShift = 0.4, pitchShift = 3.0
        assertUniform(output.shaderUniforms, key: "velocityNormalized", expected: 1.0)
        assertUniform(output.shaderUniforms, key: "colorShiftAmount", expected: 0.4)
        assertUniform(output.audioParameters, key: "pitchShiftSemitones", expected: 3.0)
    }

    func testVelocityThresholdHeldAccumulates() {
        var condition = VelocityThresholdHeld(targetVelocity: 0.85, durationSeconds: 3.0)
        let fastState = makePlayerState(speed: 0.9, deltaTime: 1.0)

        XCTAssertFalse(condition.evaluate(playerState: fastState, ruleOutput: .empty))
        XCTAssertFalse(condition.evaluate(playerState: fastState, ruleOutput: .empty))
        XCTAssertTrue(condition.evaluate(playerState: fastState, ruleOutput: .empty))
    }

    func testVelocityThresholdHeldResetsOnSlowdown() {
        var condition = VelocityThresholdHeld(targetVelocity: 0.85, durationSeconds: 3.0)
        let fastState = makePlayerState(speed: 0.9, deltaTime: 1.0)
        let slowState = makePlayerState(speed: 0.5, deltaTime: 1.0)

        _ = condition.evaluate(playerState: fastState, ruleOutput: .empty)
        _ = condition.evaluate(playerState: fastState, ruleOutput: .empty)
        // Drop speed — accumulator resets
        _ = condition.evaluate(playerState: slowState, ruleOutput: .empty)
        // Back to fast — needs 3 more seconds
        XCTAssertFalse(condition.evaluate(playerState: fastState, ruleOutput: .empty))
    }

    // MARK: - RuleEngine + Exit Condition Integration

    func testEvaluateReturnsExitTriggeredAfterThreshold() {
        let engine = RuleEngine()
        let rule = DopplerRule()
        let exitCondition = AnyExitCondition.velocityThresholdHeld(
            VelocityThresholdHeld(targetVelocity: 0.85, durationSeconds: 3.0)
        )
        engine.configure(rule: rule, exitCondition: exitCondition)

        let fastState = makePlayerState(speed: 0.9, deltaTime: 1.0)

        XCTAssertFalse(engine.evaluate(playerState: fastState).exitTriggered)
        XCTAssertFalse(engine.evaluate(playerState: fastState).exitTriggered)
        XCTAssertTrue(engine.evaluate(playerState: fastState).exitTriggered)
    }

    func testEvaluateResetsExitOnSpeedDrop() {
        let engine = RuleEngine()
        let rule = DopplerRule()
        let exitCondition = AnyExitCondition.velocityThresholdHeld(
            VelocityThresholdHeld(targetVelocity: 0.85, durationSeconds: 3.0)
        )
        engine.configure(rule: rule, exitCondition: exitCondition)

        let fastState = makePlayerState(speed: 0.9, deltaTime: 1.0)
        let slowState = makePlayerState(speed: 0.5, deltaTime: 1.0)

        _ = engine.evaluate(playerState: fastState)  // 1s accumulated
        _ = engine.evaluate(playerState: fastState)  // 2s accumulated
        _ = engine.evaluate(playerState: slowState)  // reset
        XCTAssertFalse(engine.evaluate(playerState: fastState).exitTriggered)  // only 1s
    }

    func testEvaluateWithoutExitConditionNeverTriggers() {
        let engine = RuleEngine()
        let rule = DopplerRule()
        engine.configure(rule: rule)  // no exit condition

        let fastState = makePlayerState(speed: 1.0, deltaTime: 10.0)
        XCTAssertFalse(engine.evaluate(playerState: fastState).exitTriggered)
    }

    // MARK: - Generic Exit Condition Integration

    func testGenericExitConditionWithEnterMassPoint() {
        let engine = RuleEngine()
        let rule = DopplerRule()
        let exitCondition = AnyExitCondition.enterMassPoint(
            EnterMassPoint(massPoint: SIMD3(5, 0, 0), triggerRadius: 1.5)
        )
        engine.configure(rule: rule, exitCondition: exitCondition)

        let farState = makePlayerState(speed: 0, position: SIMD3(0, 0, 0))
        XCTAssertFalse(engine.evaluate(playerState: farState).exitTriggered)

        let atPoint = makePlayerState(speed: 0, position: SIMD3(5, 0, 0))
        XCTAssertTrue(engine.evaluate(playerState: atPoint).exitTriggered)
    }

    func testExitProgressWorksForAllTypes() {
        let engine = RuleEngine()
        let rule = DopplerRule()
        let exitCondition = AnyExitCondition.velocityThresholdHeld(
            VelocityThresholdHeld(targetVelocity: 0.85, durationSeconds: 4.0)
        )
        engine.configure(rule: rule, exitCondition: exitCondition)

        let fast = makePlayerState(speed: 0.9, deltaTime: 1.0)
        _ = engine.evaluate(playerState: fast)
        XCTAssertEqual(engine.exitProgress, 0.25, accuracy: 0.01)
    }

    // MARK: - Nudge System

    func testNudgeActivatesAfterIdleThreshold() {
        let engine = RuleEngine()
        let rule = DopplerRule()
        let nudgeConfig = NudgeConfig(idleThresholdSeconds: 2.0, type: .amplitudeFlare)
        engine.configure(rule: rule, nudgeConfig: nudgeConfig)

        // Idle for 3 seconds (above 2s threshold)
        let idleState = makePlayerState(speed: 0, idleSeconds: 3.0)
        let output = engine.evaluate(playerState: idleState)
        XCTAssertTrue(output.nudgeActive)
        XCTAssertNotNil(output.shaderUniforms["nudgeIntensity"])
    }

    func testGenericExitWithStillnessHeld() {
        let engine = RuleEngine()
        let rule = DopplerRule()
        let exitCondition = AnyExitCondition.stillnessHeld(
            StillnessHeld(requiredDuration: 2.0, speedThreshold: 0.03)
        )
        engine.configure(rule: rule, exitCondition: exitCondition)

        let still = makePlayerState(speed: 0, deltaTime: 1.0)
        XCTAssertFalse(engine.evaluate(playerState: still).exitTriggered)
        XCTAssertTrue(engine.evaluate(playerState: still).exitTriggered)
    }

    func testGenericExitWithResonantSpeedHeld() {
        let engine = RuleEngine()
        let rule = DopplerRule()
        let exitCondition = AnyExitCondition.resonantSpeedHeld(
            ResonantSpeedHeld(resonantSpeed: 0.55, speedTolerance: 0.05, requiredDuration: 2.0)
        )
        engine.configure(rule: rule, exitCondition: exitCondition)

        let resonant = makePlayerState(speed: 0.55, deltaTime: 1.0)
        XCTAssertFalse(engine.evaluate(playerState: resonant).exitTriggered)
        XCTAssertTrue(engine.evaluate(playerState: resonant).exitTriggered)
    }

    func testNudgeDoesNotActivateBelowThreshold() {
        let engine = RuleEngine()
        let rule = DopplerRule()
        let nudgeConfig = NudgeConfig(idleThresholdSeconds: 90.0, type: .amplitudeFlare)
        engine.configure(rule: rule, nudgeConfig: nudgeConfig)

        let activeState = makePlayerState(speed: 0.5, idleSeconds: 0)
        let output = engine.evaluate(playerState: activeState)
        XCTAssertFalse(output.nudgeActive)
    }

    // MARK: - Helpers

    private func makePlayerState(speed: Float, deltaTime: Float = 0.016,
                                 position: SIMD3<Float> = .zero,
                                 idleSeconds: Float = 0) -> PlayerState {
        PlayerState(
            position: position,
            velocity: SIMD3<Float>(0, 0, speed),
            speed: speed,
            lookDirection: SIMD3<Float>(0, 0, -1),
            idleSeconds: idleSeconds,
            deltaTime: deltaTime
        )
    }

    private func assertUniform(
        _ dict: [String: Float],
        key: String,
        expected: Float,
        accuracy: Float = 0.02,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let value = dict[key] else {
            XCTFail("Missing key '\(key)' in uniforms", file: file, line: line)
            return
        }
        XCTAssertEqual(value, expected, accuracy: accuracy, file: file, line: line)
    }
}
