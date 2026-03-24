/// Space 6: specific speed → geometry vibration frequency match.
/// Computes proximity of player speed to a resonant target value.
/// At the resonant speed, geometry vibrates and color tints warm.
struct ResonanceRule: SpaceRule {
    let resonantSpeed: Float
    let falloffWidth: Float
    let maxAmplitude: Float
    let vibrationFrequency: Float

    init(shaderParams: [String: Double] = [:], audioParams: [String: Double] = [:]) {
        resonantSpeed = Float(shaderParams["resonantSpeed"] ?? 0.55)
        falloffWidth = Float(shaderParams["falloffWidth"] ?? 0.15)
        maxAmplitude = Float(shaderParams["maxAmplitude"] ?? 0.3)
        vibrationFrequency = Float(shaderParams["vibrationFrequency"] ?? 12.0)
    }

    func evaluate(playerState: PlayerState) -> RuleOutput {
        let deviation = abs(playerState.speed - resonantSpeed)
        let resonance: Float = deviation < falloffWidth
            ? 1.0 - (deviation / falloffWidth)
            : 0

        return RuleOutput(
            shaderUniforms: [
                "vibrationAmplitude": resonance * maxAmplitude,
                "vibrationFrequency": vibrationFrequency,
                "resonance": resonance,
            ],
            audioParameters: [
                "pitchShiftSemitones": resonance * 2.0,
                "resonance": resonance,
            ],
            exitTriggered: false,
            nudgeActive: false
        )
    }
}
