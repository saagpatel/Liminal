import simd

// MARK: - Protocol

protocol ExitCondition: Sendable {
    mutating func evaluate(playerState: PlayerState, ruleOutput: RuleOutput) -> Bool
    /// Completion progress 0.0–1.0 for debug display.
    var progress: Float { get }
}

// MARK: - VelocityThresholdHeld (Space 1: hold speed ≥ target for duration)

struct VelocityThresholdHeld: ExitCondition {
    let targetVelocity: Float
    let durationSeconds: Float
    private(set) var accumulatedSeconds: Float = 0

    var progress: Float {
        Swift.min(accumulatedSeconds / durationSeconds, 1.0)
    }

    mutating func evaluate(playerState: PlayerState, ruleOutput: RuleOutput) -> Bool {
        if playerState.speed >= targetVelocity {
            accumulatedSeconds += playerState.deltaTime
        } else {
            accumulatedSeconds = 0
        }
        return accumulatedSeconds >= durationSeconds
    }
}

// MARK: - EnterMassPoint (Space 2: enter within triggerRadius of mass point)

struct EnterMassPoint: ExitCondition {
    let massPoint: SIMD3<Float>
    let triggerRadius: Float
    private(set) var currentProgress: Float = 0

    var progress: Float { currentProgress }

    mutating func evaluate(playerState: PlayerState, ruleOutput: RuleOutput) -> Bool {
        let distance = simd_distance(playerState.position, massPoint)
        // Progress ramps up as player approaches (5× radius = where progress starts)
        currentProgress = Swift.max(0, 1.0 - distance / (triggerRadius * 5.0))
        return distance <= triggerRadius
    }
}

// MARK: - ShadowAlignment (Space 3: align shadow with groove for duration)

struct ShadowAlignment: ExitCondition {
    let grooveAngle: Float
    let toleranceRadians: Float
    let requiredDuration: Float
    private(set) var accumulatedSeconds: Float = 0
    private(set) var currentProgress: Float = 0

    var progress: Float { currentProgress }

    mutating func evaluate(playerState: PlayerState, ruleOutput: RuleOutput) -> Bool {
        // Shadow direction = opposite of player's XZ look direction
        let shadowAngle = atan2(-playerState.lookDirection.x, playerState.lookDirection.z)
        let angleDiff = abs(shadowAngle - grooveAngle)
        let wrapped = Swift.min(angleDiff, Float.pi * 2 - angleDiff)

        if wrapped <= toleranceRadians {
            accumulatedSeconds += playerState.deltaTime
        } else {
            accumulatedSeconds = 0
        }
        currentProgress = Swift.min(accumulatedSeconds / requiredDuration, 1.0)
        return accumulatedSeconds >= requiredDuration
    }
}

// MARK: - SilencePoint (Space 4: reach cancellation midpoint between audio sources)

struct SilencePoint: ExitCondition {
    let sourceA: SIMD3<Float>
    let sourceB: SIMD3<Float>
    let toleranceRadius: Float
    private(set) var currentProgress: Float = 0

    var progress: Float { currentProgress }

    mutating func evaluate(playerState: PlayerState, ruleOutput: RuleOutput) -> Bool {
        let midpoint = (sourceA + sourceB) / 2.0
        let distance = simd_distance(playerState.position, midpoint)
        let maxApproachDist = simd_distance(sourceA, sourceB) / 2.0
        currentProgress = Swift.max(0, 1.0 - distance / maxApproachDist)
        return distance <= toleranceRadius
    }
}

// MARK: - StillnessHeld (Space 5: hold perfectly still for duration)

struct StillnessHeld: ExitCondition {
    let requiredDuration: Float
    let speedThreshold: Float
    private(set) var accumulatedSeconds: Float = 0

    var progress: Float { Swift.min(accumulatedSeconds / requiredDuration, 1.0) }

    mutating func evaluate(playerState: PlayerState, ruleOutput: RuleOutput) -> Bool {
        if playerState.speed < speedThreshold {
            accumulatedSeconds += playerState.deltaTime
        } else {
            accumulatedSeconds = 0
        }
        return accumulatedSeconds >= requiredDuration
    }
}

// MARK: - ResonantSpeedHeld (Space 6: hold resonant speed for duration)

struct ResonantSpeedHeld: ExitCondition {
    let resonantSpeed: Float
    let speedTolerance: Float
    let requiredDuration: Float
    private(set) var accumulatedSeconds: Float = 0

    var progress: Float { Swift.min(accumulatedSeconds / requiredDuration, 1.0) }

    mutating func evaluate(playerState: PlayerState, ruleOutput: RuleOutput) -> Bool {
        if abs(playerState.speed - resonantSpeed) <= speedTolerance {
            accumulatedSeconds += playerState.deltaTime
        } else {
            accumulatedSeconds = 0
        }
        return accumulatedSeconds >= requiredDuration
    }
}

// MARK: - ConvergenceCondition (Space 7: all 6 prior conditions simultaneously)

struct ConvergenceCondition: ExitCondition {
    // Sub-conditions with relaxed tolerances
    let targetSpeed: Float        // resonant speed
    let speedTolerance: Float     // wider than Space 6 (e.g. 0.08)
    let massPoint: SIMD3<Float>   // lensing mass point
    let massPointRadius: Float    // wider than Space 2 (e.g. 3.0)
    let interferenceSourceA: SIMD3<Float>
    let interferenceSourceB: SIMD3<Float>
    let interferenceRadius: Float // wider than Space 4 (e.g. 1.5)
    let grooveAngle: Float        // shadow groove angle
    let angleTolerance: Float     // wider than Space 3 (e.g. 0.25)
    let requiredDuration: Float   // how long ALL must be held (e.g. 2.0s)

    private(set) var accumulatedSeconds: Float = 0
    private(set) var currentProgress: Float = 0

    var progress: Float { currentProgress }

    mutating func evaluate(playerState: PlayerState, ruleOutput: RuleOutput) -> Bool {
        // Check all 6 conditions simultaneously
        let speedOK = abs(playerState.speed - targetSpeed) <= speedTolerance
        let proximityOK = simd_distance(playerState.position, massPoint) <= massPointRadius
        let midpoint = (interferenceSourceA + interferenceSourceB) / 2.0
        let interferenceOK = simd_distance(playerState.position, midpoint) <= interferenceRadius
        let shadowAngle = atan2(-playerState.lookDirection.x, playerState.lookDirection.z)
        let angleDiff = abs(shadowAngle - grooveAngle)
        let wrappedAngle = Swift.min(angleDiff, Float.pi * 2 - angleDiff)
        let shadowOK = wrappedAngle <= angleTolerance
        // Stillness: NOT required — convergence requires movement at resonant speed
        // Doppler: implicitly satisfied by the speed check (speed > 0)

        let allSatisfied = speedOK && proximityOK && interferenceOK && shadowOK

        if allSatisfied {
            accumulatedSeconds += playerState.deltaTime
        } else {
            accumulatedSeconds = Swift.max(0, accumulatedSeconds - playerState.deltaTime * 0.5)
        }
        currentProgress = Swift.min(accumulatedSeconds / requiredDuration, 1.0)
        return accumulatedSeconds >= requiredDuration
    }
}

// MARK: - AnyExitCondition (enum wrapper for type-safe storage)

/// Wraps concrete ExitCondition structs so they can be stored mutably
/// inside RuleEngine's lock. Enum is Sendable with no heap allocation.
enum AnyExitCondition: Sendable {
    case velocityThresholdHeld(VelocityThresholdHeld)
    case enterMassPoint(EnterMassPoint)
    case shadowAlignment(ShadowAlignment)
    case silencePoint(SilencePoint)
    case stillnessHeld(StillnessHeld)
    case resonantSpeedHeld(ResonantSpeedHeld)
    case convergence(ConvergenceCondition)

    mutating func evaluate(playerState: PlayerState, ruleOutput: RuleOutput) -> Bool {
        switch self {
        case .velocityThresholdHeld(var c):
            let result = c.evaluate(playerState: playerState, ruleOutput: ruleOutput)
            self = .velocityThresholdHeld(c)
            return result
        case .enterMassPoint(var c):
            let result = c.evaluate(playerState: playerState, ruleOutput: ruleOutput)
            self = .enterMassPoint(c)
            return result
        case .shadowAlignment(var c):
            let result = c.evaluate(playerState: playerState, ruleOutput: ruleOutput)
            self = .shadowAlignment(c)
            return result
        case .silencePoint(var c):
            let result = c.evaluate(playerState: playerState, ruleOutput: ruleOutput)
            self = .silencePoint(c)
            return result
        case .stillnessHeld(var c):
            let result = c.evaluate(playerState: playerState, ruleOutput: ruleOutput)
            self = .stillnessHeld(c)
            return result
        case .resonantSpeedHeld(var c):
            let result = c.evaluate(playerState: playerState, ruleOutput: ruleOutput)
            self = .resonantSpeedHeld(c)
            return result
        case .convergence(var c):
            let result = c.evaluate(playerState: playerState, ruleOutput: ruleOutput)
            self = .convergence(c)
            return result
        }
    }

    var progress: Float {
        switch self {
        case .velocityThresholdHeld(let c): c.progress
        case .enterMassPoint(let c): c.progress
        case .shadowAlignment(let c): c.progress
        case .silencePoint(let c): c.progress
        case .stillnessHeld(let c): c.progress
        case .resonantSpeedHeld(let c): c.progress
        case .convergence(let c): c.progress
        }
    }
}
