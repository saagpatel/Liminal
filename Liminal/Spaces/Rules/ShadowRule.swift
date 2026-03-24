/// Space 3: player-relative shadow direction.
/// Passes player position as individual float uniforms to the fragment shader,
/// which computes a faux shadow that tracks the player instead of the light source.
struct ShadowRule: SpaceRule {
    let shadowIntensity: Float

    init(shaderParams: [String: Double] = [:], audioParams: [String: Double] = [:]) {
        shadowIntensity = Float(shaderParams["shadowIntensity"] ?? 0.7)
    }

    func evaluate(playerState: PlayerState) -> RuleOutput {
        RuleOutput(
            shaderUniforms: [
                "playerPositionX": playerState.position.x,
                "playerPositionY": playerState.position.y,
                "playerPositionZ": playerState.position.z,
                "shadowIntensity": shadowIntensity
            ],
            audioParameters: [:],
            exitTriggered: false,
            nudgeActive: false
        )
    }
}
