/// Space 5: stillness → desaturation over time; movement → resaturation.
///
/// Class (not struct) because it holds mutable `currentDesaturation` state
/// that ramps smoothly — unlike structs which would snap on player state changes.
/// SpaceRule protocol is non-mutating, so a class is the cleanest solution.
final class ChromaticDecayRule: SpaceRule {
    let maxDesaturationSeconds: Float
    let resaturationRate: Float
    private var currentDesaturation: Float = 0

    init(shaderParams: [String: Double] = [:], audioParams: [String: Double] = [:]) {
        maxDesaturationSeconds = Float(shaderParams["maxDesaturationSeconds"] ?? 15.0)
        resaturationRate = Float(shaderParams["resaturationRate"] ?? 15.0)
    }

    func evaluate(playerState: PlayerState) -> RuleOutput {
        let isIdle = playerState.speed < 0.05
        if isIdle {
            currentDesaturation += playerState.deltaTime / maxDesaturationSeconds
        } else {
            currentDesaturation -= playerState.deltaTime / resaturationRate
        }
        currentDesaturation = Swift.min(Swift.max(currentDesaturation, 0), 1.0)

        return RuleOutput(
            shaderUniforms: [
                "desaturation": currentDesaturation,
            ],
            audioParameters: [
                "reverbMix": 0.3 + currentDesaturation * 0.6,
            ],
            exitTriggered: false,
            nudgeActive: false
        )
    }
}
