import XCTest
import simd
@testable import Liminal

final class ExitConditionTests: XCTestCase {

    // MARK: - EnterMassPoint

    func testEnterMassPointTriggersAtRadius() {
        var condition = EnterMassPoint(massPoint: SIMD3(5, 3, 0), triggerRadius: 1.5)
        let state = makeState(position: SIMD3(5, 3, 0))  // exactly at mass point
        XCTAssertTrue(condition.evaluate(playerState: state, ruleOutput: .empty))
    }

    func testEnterMassPointDoesNotTriggerOutsideRadius() {
        var condition = EnterMassPoint(massPoint: SIMD3(5, 3, 0), triggerRadius: 1.5)
        let state = makeState(position: SIMD3(0, 3, 0))  // 5 units away
        XCTAssertFalse(condition.evaluate(playerState: state, ruleOutput: .empty))
    }

    func testEnterMassPointProgressIncreasesOnApproach() {
        var condition = EnterMassPoint(massPoint: SIMD3(5, 3, 0), triggerRadius: 1.5)

        let farState = makeState(position: SIMD3(0, 3, 0))
        _ = condition.evaluate(playerState: farState, ruleOutput: .empty)
        let farProgress = condition.progress

        let nearState = makeState(position: SIMD3(4, 3, 0))
        _ = condition.evaluate(playerState: nearState, ruleOutput: .empty)
        let nearProgress = condition.progress

        XCTAssertGreaterThan(nearProgress, farProgress)
    }

    // MARK: - ShadowAlignment

    func testShadowAlignmentTriggersWhenAligned() {
        var condition = ShadowAlignment(
            grooveAngle: 0.785, toleranceRadians: 0.15, requiredDuration: 2.0
        )
        // Look direction that produces shadow angle ≈ 0.785 (45°)
        // Shadow = opposite of look → look at angle π + 0.785
        let lookDir = SIMD3<Float>(sin(Float.pi + 0.785), 0, -cos(Float.pi + 0.785))
        let state = makeState(lookDirection: lookDir, deltaTime: 1.0)

        XCTAssertFalse(condition.evaluate(playerState: state, ruleOutput: .empty))
        XCTAssertTrue(condition.evaluate(playerState: state, ruleOutput: .empty))
    }

    func testShadowAlignmentResetsOnMisalignment() {
        var condition = ShadowAlignment(
            grooveAngle: 0.785, toleranceRadians: 0.15, requiredDuration: 2.0
        )
        let alignedLook = SIMD3<Float>(sin(Float.pi + 0.785), 0, -cos(Float.pi + 0.785))
        let misalignedLook = SIMD3<Float>(0, 0, -1)

        let aligned = makeState(lookDirection: alignedLook, deltaTime: 1.0)
        let misaligned = makeState(lookDirection: misalignedLook, deltaTime: 1.0)

        _ = condition.evaluate(playerState: aligned, ruleOutput: .empty)   // 1s
        _ = condition.evaluate(playerState: misaligned, ruleOutput: .empty) // reset
        XCTAssertFalse(condition.evaluate(playerState: aligned, ruleOutput: .empty)) // only 1s
    }

    func testShadowAlignmentProgressTracksAccumulation() {
        var condition = ShadowAlignment(
            grooveAngle: 0, toleranceRadians: 0.3, requiredDuration: 4.0
        )
        let lookDir = SIMD3<Float>(0, 0, 1)  // shadow angle = atan2(0, 1) = 0
        let state = makeState(lookDirection: lookDir, deltaTime: 1.0)

        _ = condition.evaluate(playerState: state, ruleOutput: .empty)
        XCTAssertEqual(condition.progress, 0.25, accuracy: 0.01)

        _ = condition.evaluate(playerState: state, ruleOutput: .empty)
        XCTAssertEqual(condition.progress, 0.5, accuracy: 0.01)
    }

    // MARK: - AnyExitCondition wrapper

    func testAnyExitConditionDelegatesVelocityThresholdHeld() {
        var any = AnyExitCondition.velocityThresholdHeld(
            VelocityThresholdHeld(targetVelocity: 0.85, durationSeconds: 2.0)
        )
        let fast = makeState(speed: 0.9, deltaTime: 1.0)
        XCTAssertFalse(any.evaluate(playerState: fast, ruleOutput: .empty))
        XCTAssertTrue(any.evaluate(playerState: fast, ruleOutput: .empty))
    }

    func testAnyExitConditionDelegatesEnterMassPoint() {
        var any = AnyExitCondition.enterMassPoint(
            EnterMassPoint(massPoint: SIMD3(0, 0, 0), triggerRadius: 1.0)
        )
        let atPoint = makeState(position: SIMD3(0, 0, 0))
        XCTAssertTrue(any.evaluate(playerState: atPoint, ruleOutput: .empty))
    }

    func testAnyExitConditionProgress() {
        var any = AnyExitCondition.velocityThresholdHeld(
            VelocityThresholdHeld(targetVelocity: 0.85, durationSeconds: 4.0)
        )
        let fast = makeState(speed: 0.9, deltaTime: 1.0)
        _ = any.evaluate(playerState: fast, ruleOutput: .empty)
        XCTAssertEqual(any.progress, 0.25, accuracy: 0.01)
    }

    // MARK: - SilencePoint

    func testSilencePointTriggersAtMidpoint() {
        var condition = SilencePoint(
            sourceA: SIMD3(-6, 1.7, 0), sourceB: SIMD3(6, 1.7, 0), toleranceRadius: 0.5
        )
        let state = makeState(position: SIMD3(0, 1.7, 0))  // exact midpoint
        XCTAssertTrue(condition.evaluate(playerState: state, ruleOutput: .empty))
    }

    func testSilencePointDoesNotTriggerFarAway() {
        var condition = SilencePoint(
            sourceA: SIMD3(-6, 1.7, 0), sourceB: SIMD3(6, 1.7, 0), toleranceRadius: 0.5
        )
        let state = makeState(position: SIMD3(-5, 1.7, 0))  // near source A
        XCTAssertFalse(condition.evaluate(playerState: state, ruleOutput: .empty))
    }

    func testSilencePointProgressIncreasesOnApproach() {
        var condition = SilencePoint(
            sourceA: SIMD3(-6, 1.7, 0), sourceB: SIMD3(6, 1.7, 0), toleranceRadius: 0.5
        )
        _ = condition.evaluate(playerState: makeState(position: SIMD3(-5, 1.7, 0)), ruleOutput: .empty)
        let farProgress = condition.progress

        _ = condition.evaluate(playerState: makeState(position: SIMD3(-1, 1.7, 0)), ruleOutput: .empty)
        let nearProgress = condition.progress

        XCTAssertGreaterThan(nearProgress, farProgress)
    }

    // MARK: - StillnessHeld

    func testStillnessHeldTriggersWhenStill() {
        var condition = StillnessHeld(requiredDuration: 2.0, speedThreshold: 0.03)
        let still = makeState(speed: 0.0, deltaTime: 1.0)
        XCTAssertFalse(condition.evaluate(playerState: still, ruleOutput: .empty))
        XCTAssertTrue(condition.evaluate(playerState: still, ruleOutput: .empty))
    }

    func testStillnessHeldResetsOnMovement() {
        var condition = StillnessHeld(requiredDuration: 3.0, speedThreshold: 0.03)
        let still = makeState(speed: 0.0, deltaTime: 1.0)
        let moving = makeState(speed: 0.5, deltaTime: 1.0)

        _ = condition.evaluate(playerState: still, ruleOutput: .empty)  // 1s
        _ = condition.evaluate(playerState: still, ruleOutput: .empty)  // 2s
        _ = condition.evaluate(playerState: moving, ruleOutput: .empty) // reset
        XCTAssertFalse(condition.evaluate(playerState: still, ruleOutput: .empty)) // only 1s
    }

    func testStillnessHeldProgressTracks() {
        var condition = StillnessHeld(requiredDuration: 4.0, speedThreshold: 0.03)
        let still = makeState(speed: 0.0, deltaTime: 1.0)
        _ = condition.evaluate(playerState: still, ruleOutput: .empty)
        XCTAssertEqual(condition.progress, 0.25, accuracy: 0.01)
    }

    // MARK: - ResonantSpeedHeld

    func testResonantSpeedHeldTriggersAtTarget() {
        var condition = ResonantSpeedHeld(
            resonantSpeed: 0.55, speedTolerance: 0.05, requiredDuration: 2.0
        )
        let resonant = makeState(speed: 0.55, deltaTime: 1.0)
        XCTAssertFalse(condition.evaluate(playerState: resonant, ruleOutput: .empty))
        XCTAssertTrue(condition.evaluate(playerState: resonant, ruleOutput: .empty))
    }

    func testResonantSpeedHeldResetsOnDeviation() {
        var condition = ResonantSpeedHeld(
            resonantSpeed: 0.55, speedTolerance: 0.05, requiredDuration: 3.0
        )
        let resonant = makeState(speed: 0.55, deltaTime: 1.0)
        let offSpeed = makeState(speed: 0.8, deltaTime: 1.0)

        _ = condition.evaluate(playerState: resonant, ruleOutput: .empty) // 1s
        _ = condition.evaluate(playerState: resonant, ruleOutput: .empty) // 2s
        _ = condition.evaluate(playerState: offSpeed, ruleOutput: .empty) // reset
        XCTAssertFalse(condition.evaluate(playerState: resonant, ruleOutput: .empty)) // only 1s
    }

    func testResonantSpeedHeldDoesNotAccumulateOutsideTolerance() {
        var condition = ResonantSpeedHeld(
            resonantSpeed: 0.55, speedTolerance: 0.05, requiredDuration: 2.0
        )
        let tooFast = makeState(speed: 0.8, deltaTime: 1.0)
        _ = condition.evaluate(playerState: tooFast, ruleOutput: .empty)
        _ = condition.evaluate(playerState: tooFast, ruleOutput: .empty)
        _ = condition.evaluate(playerState: tooFast, ruleOutput: .empty)
        XCTAssertEqual(condition.progress, 0.0, accuracy: 0.01)
    }

    // MARK: - Helpers

    private func makeState(
        position: SIMD3<Float> = .zero,
        speed: Float = 0,
        lookDirection: SIMD3<Float> = SIMD3(0, 0, -1),
        deltaTime: Float = 0.016
    ) -> PlayerState {
        PlayerState(
            position: position,
            velocity: .zero,
            speed: speed,
            lookDirection: lookDirection,
            idleSeconds: 0,
            deltaTime: deltaTime
        )
    }
}
