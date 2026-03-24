import simd

// MARK: - Protocol

protocol SpaceRule {
    func evaluate(playerState: PlayerState) -> RuleOutput
}

// MARK: - PlayerState

struct PlayerState: Sendable {
    let position: SIMD3<Float>
    let velocity: SIMD3<Float>
    /// Magnitude of velocity, normalized 0.0–1.0.
    let speed: Float
    let lookDirection: SIMD3<Float>
    /// Seconds since last movement > 0.05 units/frame.
    let idleSeconds: Float
    /// Seconds since last frame.
    let deltaTime: Float
}

// MARK: - RuleOutput

struct RuleOutput: Sendable {
    /// Pushed to ShaderUniformBus each frame.
    let shaderUniforms: [String: Float]
    /// Pushed to AudioManager each frame.
    let audioParameters: [String: Float]
    let exitTriggered: Bool
    let nudgeActive: Bool

    static let empty = RuleOutput(
        shaderUniforms: [:],
        audioParameters: [:],
        exitTriggered: false,
        nudgeActive: false
    )
}
