import simd

/// Space 2: proximity to hidden mass point → UV warp + audio reverb deepening.
struct LensingRule: SpaceRule {
    let massPoint: SIMD3<Float>
    let maxDistortion: Float
    let falloffStart: Float  // distance where distortion begins
    let falloffEnd: Float    // distance where distortion peaks

    init(shaderParams: [String: Double] = [:], audioParams: [String: Double] = [:]) {
        massPoint = SIMD3<Float>(
            Float(shaderParams["massPointX"] ?? 5.0),
            Float(shaderParams["massPointY"] ?? 3.0),
            Float(shaderParams["massPointZ"] ?? 0.0)
        )
        maxDistortion = Float(shaderParams["maxDistortion"] ?? 0.15)
        falloffStart = Float(shaderParams["falloffStart"] ?? 15.0)
        falloffEnd = Float(shaderParams["falloffEnd"] ?? 5.0)
    }

    func evaluate(playerState: PlayerState) -> RuleOutput {
        let distance = simd_distance(playerState.position, massPoint)
        let proximityNormalized: Float
        if distance >= falloffStart {
            proximityNormalized = 0
        } else if distance <= falloffEnd {
            proximityNormalized = 1
        } else {
            proximityNormalized = 1.0 - (distance - falloffEnd) / (falloffStart - falloffEnd)
        }

        return RuleOutput(
            shaderUniforms: [
                "proximityNormalized": proximityNormalized,
                "distortionAmount": proximityNormalized * maxDistortion
            ],
            audioParameters: [
                "reverbMix": 0.3 + proximityNormalized * 0.5
            ],
            exitTriggered: false,
            nudgeActive: false
        )
    }
}
