import SceneKit
import os
import simd

// MARK: - Containment

/// Defines how the player is bounded within a space's geometry.
enum Containment: Sendable {
    case rectangular(min: SIMD3<Float>, max: SIMD3<Float>)
    case spherical(center: SIMD3<Float>, radius: Float)

    func clamp(_ position: SIMD3<Float>, eyeHeight: Float) -> SIMD3<Float> {
        switch self {
        case .rectangular(let min, let max):
            return SIMD3<Float>(
                Swift.min(Swift.max(position.x, min.x), max.x),
                eyeHeight,
                Swift.min(Swift.max(position.z, min.z), max.z)
            )
        case .spherical(let center, let radius):
            var pos = position
            pos.y = eyeHeight
            let offset = SIMD3<Float>(pos.x - center.x, 0, pos.z - center.z)
            if offset.magnitude > radius {
                let clamped = center + offset.normalized * radius
                pos.x = clamped.x
                pos.z = clamped.z
            }
            return pos
        }
    }
}

/// First-person camera controller with thread-safe gesture input and velocity tracking.
///
/// Gesture handlers are called on the main thread. `consumeInputAndUpdate` is called
/// from SceneKit's render thread. `OSAllocatedUnfairLock` synchronizes between them.
final class PlayerController: @unchecked Sendable {
    let cameraNode: SCNNode

    // MARK: - Configuration

    let baseMovementSpeed: Float
    let maxPitch: Float = 70.0 * .pi / 180.0
    let containment: Containment
    let eyeHeight: Float = 1.7

    private let lookSensitivity: Float = 0.005
    private let moveSensitivity: Float = 0.012
    private let velocityBufferSize = 10

    // MARK: - Thread-safe state

    struct MutableState: Sendable {
        var yaw: Float = 0
        var pitch: Float = 0
        var speedMultiplier: Float = 1.0

        // Accumulated gesture deltas (zeroed each frame)
        var lookDeltaX: Float = 0
        var lookDeltaY: Float = 0
        var moveDeltaX: Float = 0
        var moveDeltaY: Float = 0
        var isMoving: Bool = false

        // Position + velocity tracking
        var currentPosition: SIMD3<Float>
        var positionHistory: [SIMD3<Float>]
        var historyIndex: Int = 0
        var idleSeconds: Float = 0
    }

    private let state: OSAllocatedUnfairLock<MutableState>

    // MARK: - Init

    init(startPosition: SIMD3<Float>, baseSpeed: Float, containment: Containment,
         startYaw: Float = 0) {
        self.containment = containment
        baseMovementSpeed = baseSpeed

        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 200
        cameraNode.camera?.fieldOfView = 75
        cameraNode.simdPosition = startPosition
        cameraNode.simdEulerAngles = SIMD3<Float>(0, startYaw, 0)

        let history = [SIMD3<Float>](repeating: startPosition, count: velocityBufferSize)
        state = OSAllocatedUnfairLock(initialState: MutableState(
            yaw: startYaw,
            currentPosition: startPosition,
            positionHistory: history
        ))
    }

    /// Convenience init for backward compatibility (corridorScale → rectangular containment).
    convenience init(startPosition: SIMD3<Float>, baseSpeed: Float,
                     corridorScale: SIMD3<Float>, startYaw: Float = 0) {
        let halfX = corridorScale.x / 2.0
        let halfZ = corridorScale.z / 2.0
        let wallMargin: Float = 0.3
        let containment = Containment.rectangular(
            min: SIMD3<Float>(-halfX + wallMargin, 1.7, -halfZ + wallMargin),
            max: SIMD3<Float>(halfX - wallMargin, 1.7, halfZ - wallMargin)
        )
        self.init(startPosition: startPosition, baseSpeed: baseSpeed,
                  containment: containment, startYaw: startYaw)
    }

    // MARK: - Gesture handlers (main thread)

    func handleLookPan(translation: CGPoint) {
        state.withLock { s in
            s.lookDeltaX += Float(translation.x)
            s.lookDeltaY += Float(translation.y)
        }
    }

    func handleMovePan(translation: CGPoint, isActive: Bool) {
        state.withLock { s in
            s.moveDeltaX += Float(translation.x)
            s.moveDeltaY += Float(translation.y)
            s.isMoving = isActive
        }
    }

    func handlePinch(scale: CGFloat) {
        state.withLock { s in
            s.speedMultiplier = Swift.min(Swift.max(Float(scale), 0.5), 3.0)
        }
    }

    // MARK: - Per-frame update (render thread)

    func consumeInputAndUpdate(deltaTime: Float) -> PlayerState {
        // 1. Read and zero deltas atomically
        let snapshot = state.withLock { s -> MutableState in
            let copy = s
            s.lookDeltaX = 0
            s.lookDeltaY = 0
            s.moveDeltaX = 0
            s.moveDeltaY = 0
            return copy
        }

        // 2. Apply look rotation
        var yaw = snapshot.yaw + snapshot.lookDeltaX * lookSensitivity
        var pitch = snapshot.pitch - snapshot.lookDeltaY * lookSensitivity
        pitch = Swift.min(Swift.max(pitch, -maxPitch), maxPitch)

        // Normalize yaw to -π..π
        if yaw > .pi { yaw -= 2 * .pi }
        if yaw < -.pi { yaw += 2 * .pi }

        cameraNode.simdEulerAngles = SIMD3<Float>(pitch, yaw, 0)

        // 3. Compute movement vectors (XZ plane only)
        let forward = SIMD3<Float>(sin(yaw), 0, -cos(yaw))
        let right = SIMD3<Float>(cos(yaw), 0, sin(yaw))

        // 4. Apply translation
        var newPos = snapshot.currentPosition
        if snapshot.isMoving {
            let moveForward = -snapshot.moveDeltaY * moveSensitivity
            let moveRight = snapshot.moveDeltaX * moveSensitivity
            let displacement = (forward * moveForward + right * moveRight)
                * baseMovementSpeed * snapshot.speedMultiplier * deltaTime
            newPos += displacement
        }

        // 5. Clamp within containment bounds
        newPos = containment.clamp(newPos, eyeHeight: eyeHeight)

        cameraNode.simdPosition = newPos

        // 6. Update velocity ring buffer
        var history = snapshot.positionHistory
        var idx = snapshot.historyIndex
        let oldestPos = history[idx]
        history[idx] = newPos
        idx = (idx + 1) % velocityBufferSize

        // Velocity = displacement across buffer / buffer span
        let displacement = newPos - oldestPos
        let velocity = displacement / (Float(velocityBufferSize) * Swift.max(deltaTime, 0.001))

        // 7. Normalize speed: 0 at rest, 1.0 at max pinch speed
        let maxSpeed = baseMovementSpeed * 3.0
        let rawSpeed = velocity.magnitude
        let normalizedSpeed = Swift.min(rawSpeed / maxSpeed, 1.0)

        // 8. Idle tracking
        let idleThreshold: Float = 0.05
        let updatedIdleSeconds: Float = normalizedSpeed < idleThreshold
            ? snapshot.idleSeconds + deltaTime
            : 0

        // 9. Write back mutable state (capture as let for @Sendable)
        let finalYaw = yaw
        let finalPitch = pitch
        let finalPos = newPos
        let finalHistory = history
        let finalIdx = idx
        let finalIdle = updatedIdleSeconds
        state.withLock { s in
            s.yaw = finalYaw
            s.pitch = finalPitch
            s.currentPosition = finalPos
            s.positionHistory = finalHistory
            s.historyIndex = finalIdx
            s.idleSeconds = finalIdle
        }

        // 10. Return immutable snapshot
        return PlayerState(
            position: finalPos,
            velocity: velocity,
            speed: normalizedSpeed,
            lookDirection: cameraNode.simdWorldFront,
            idleSeconds: finalIdle,
            deltaTime: deltaTime
        )
    }
}
