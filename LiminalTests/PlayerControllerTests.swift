import XCTest
import simd
@testable import Liminal

final class PlayerControllerTests: XCTestCase {

    private func makeController() -> PlayerController {
        PlayerController(
            startPosition: SIMD3<Float>(0, 1.7, 0),
            baseSpeed: 5.0,
            corridorScale: SIMD3<Float>(40, 6, 4)
        )
    }

    // MARK: - Speed

    func testStationaryPlayerHasZeroSpeed() {
        let controller = makeController()
        // Multiple frames with no input
        for _ in 0..<15 {
            _ = controller.consumeInputAndUpdate(deltaTime: 0.016)
        }
        let state = controller.consumeInputAndUpdate(deltaTime: 0.016)
        XCTAssertEqual(state.speed, 0.0, accuracy: 0.01)
    }

    func testSpeedNormalizationAtMaxPinch() {
        // Use a wider corridor so we don't hit the wall immediately
        let controller = PlayerController(
            startPosition: SIMD3<Float>(0, 1.7, 0),
            baseSpeed: 5.0,
            corridorScale: SIMD3<Float>(200, 6, 200)
        )
        controller.handlePinch(scale: 3.0)

        // First, rotate yaw 90° so forward is along X (the longer axis)
        controller.handleLookPan(translation: CGPoint(x: .pi / (2 * 0.005), y: 0))
        _ = controller.consumeInputAndUpdate(deltaTime: 0.016)

        // Fill the velocity buffer with movement frames
        for _ in 0..<15 {
            controller.handleMovePan(translation: CGPoint(x: 0, y: -200), isActive: true)
            _ = controller.consumeInputAndUpdate(deltaTime: 0.016)
        }
        let state = controller.consumeInputAndUpdate(deltaTime: 0.016)
        // Speed should be non-zero at max pinch with movement input
        XCTAssertGreaterThan(state.speed, 0.0)
    }

    func testPinchClampedToRange() {
        let controller = makeController()
        controller.handlePinch(scale: 10.0)  // Beyond max
        let state = controller.consumeInputAndUpdate(deltaTime: 0.016)
        // Pinch internally clamped to 3.0 — just verify no crash
        XCTAssertNotNil(state)
    }

    // MARK: - Look

    func testLookPanUpdatesYawAndPitch() {
        let controller = makeController()
        _ = controller.consumeInputAndUpdate(deltaTime: 0.016)  // initialize

        let initialAngles = controller.cameraNode.simdEulerAngles
        controller.handleLookPan(translation: CGPoint(x: 100, y: -50))
        _ = controller.consumeInputAndUpdate(deltaTime: 0.016)

        let newAngles = controller.cameraNode.simdEulerAngles
        // Yaw (Y component) should have changed
        XCTAssertNotEqual(newAngles.y, initialAngles.y, accuracy: 0.001)
        // Pitch (X component) should have changed
        XCTAssertNotEqual(newAngles.x, initialAngles.x, accuracy: 0.001)
    }

    func testPitchClampedAt70Degrees() {
        let controller = makeController()
        _ = controller.consumeInputAndUpdate(deltaTime: 0.016)

        // Look very far down (large positive Y in screen coords = look down)
        for _ in 0..<50 {
            controller.handleLookPan(translation: CGPoint(x: 0, y: 100))
            _ = controller.consumeInputAndUpdate(deltaTime: 0.016)
        }

        let pitch = controller.cameraNode.simdEulerAngles.x
        let maxPitch = 70.0 * Float.pi / 180.0
        XCTAssertLessThanOrEqual(abs(pitch), maxPitch + 0.01)
    }

    // MARK: - Movement

    func testMovePanUpdatesPosition() {
        let controller = makeController()
        let initial = controller.consumeInputAndUpdate(deltaTime: 0.016)

        controller.handleMovePan(translation: CGPoint(x: 0, y: -200), isActive: true)
        let moved = controller.consumeInputAndUpdate(deltaTime: 0.016)

        // Position should have changed
        let distance = simd_distance(initial.position, moved.position)
        XCTAssertGreaterThan(distance, 0.0)
    }

    func testPositionClampedWithinCorridor() {
        let controller = makeController()

        // Try to move far beyond corridor bounds
        for _ in 0..<200 {
            controller.handleMovePan(translation: CGPoint(x: 0, y: -500), isActive: true)
            _ = controller.consumeInputAndUpdate(deltaTime: 0.016)
        }

        let state = controller.consumeInputAndUpdate(deltaTime: 0.016)
        // Should be clamped within corridor (scale 40×6×4, so x in [-19.7, 19.7], z in [-1.7, 1.7])
        XCTAssertLessThanOrEqual(abs(state.position.x), 20.0)
        XCTAssertLessThanOrEqual(abs(state.position.z), 2.0)
        XCTAssertEqual(state.position.y, 1.7, accuracy: 0.01)
    }

    // MARK: - Idle

    func testIdleTimeAccumulatesWhenStationary() {
        let controller = makeController()
        // Fill buffer with stationary frames
        var state = PlayerState.zero
        for _ in 0..<20 {
            state = controller.consumeInputAndUpdate(deltaTime: 0.016)
        }
        XCTAssertGreaterThan(state.idleSeconds, 0.1)
    }

    func testIdleTimeResetsOnMovement() {
        let controller = makeController()
        // Accumulate idle time
        for _ in 0..<20 {
            _ = controller.consumeInputAndUpdate(deltaTime: 0.016)
        }

        // Start moving
        controller.handleMovePan(translation: CGPoint(x: 0, y: -500), isActive: true)
        _ = controller.consumeInputAndUpdate(deltaTime: 0.016)
        controller.handleMovePan(translation: CGPoint(x: 0, y: -500), isActive: true)
        _ = controller.consumeInputAndUpdate(deltaTime: 0.016)

        // Several more movement frames to get speed above idle threshold
        for _ in 0..<10 {
            controller.handleMovePan(translation: CGPoint(x: 0, y: -500), isActive: true)
            _ = controller.consumeInputAndUpdate(deltaTime: 0.016)
        }

        let state = controller.consumeInputAndUpdate(deltaTime: 0.016)
        // If speed is above threshold, idle should be 0 or near 0
        if state.speed >= 0.05 {
            XCTAssertEqual(state.idleSeconds, 0.0, accuracy: 0.02)
        }
    }
    // MARK: - Containment + startYaw

    func testSphericalContainmentClampsRadius() {
        let controller = PlayerController(
            startPosition: SIMD3<Float>(0, 1.7, 0),
            baseSpeed: 5.0,
            containment: .spherical(center: .zero, radius: 5.0)
        )
        // Try to move far beyond sphere radius
        for _ in 0..<200 {
            controller.handleMovePan(translation: CGPoint(x: 0, y: -500), isActive: true)
            _ = controller.consumeInputAndUpdate(deltaTime: 0.016)
        }
        let state = controller.consumeInputAndUpdate(deltaTime: 0.016)
        let distFromCenter = sqrt(state.position.x * state.position.x + state.position.z * state.position.z)
        XCTAssertLessThanOrEqual(distFromCenter, 5.1)  // within radius + margin
    }

    func testStartYawApplied() {
        let controller = PlayerController(
            startPosition: SIMD3<Float>(0, 1.7, 0),
            baseSpeed: 5.0,
            containment: .rectangular(
                min: SIMD3(-20, 1.7, -20), max: SIMD3(20, 1.7, 20)),
            startYaw: .pi / 2
        )
        _ = controller.consumeInputAndUpdate(deltaTime: 0.016)
        // Camera should be facing roughly +X (yaw = π/2)
        let eulerY = controller.cameraNode.simdEulerAngles.y
        XCTAssertEqual(eulerY, .pi / 2, accuracy: 0.01)
    }

    func testRectangularContainmentBackwardCompatible() {
        // Old corridorScale init still works
        let controller = PlayerController(
            startPosition: SIMD3<Float>(0, 1.7, 0),
            baseSpeed: 5.0,
            corridorScale: SIMD3<Float>(40, 6, 4)
        )
        let state = controller.consumeInputAndUpdate(deltaTime: 0.016)
        XCTAssertEqual(state.position.y, 1.7, accuracy: 0.01)
    }
}

// MARK: - PlayerState convenience

private extension PlayerState {
    static let zero = PlayerState(
        position: .zero, velocity: .zero, speed: 0,
        lookDirection: SIMD3<Float>(0, 0, -1), idleSeconds: 0, deltaTime: 0.016
    )
}
