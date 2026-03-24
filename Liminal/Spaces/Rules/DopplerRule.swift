import Foundation

/// Space 1: speed → color blueshift + pitch rise.
///
/// Phase 0 mock — returns hardcoded output proportional to speed.
/// Real parameter-driven implementation comes in Phase 1.
struct DopplerRule: SpaceRule {
    let maxColorShift: Float
    let velocityThreshold: Float
    let transitionSpeed: Float
    let maxPitchShiftSemitones: Float

    init(shaderParams: [String: Double] = [:], audioParams: [String: Double] = [:]) {
        maxColorShift = Float(shaderParams["maxColorShift"] ?? 0.4)
        velocityThreshold = Float(shaderParams["velocityThreshold"] ?? 0.3)
        transitionSpeed = Float(shaderParams["transitionSpeed"] ?? 2.0)
        maxPitchShiftSemitones = Float(audioParams["maxPitchShiftSemitones"] ?? 3.0)
    }

    func evaluate(playerState: PlayerState) -> RuleOutput {
        // Normalized intensity: 0 below threshold, linear ramp above
        let intensity: Float
        if playerState.speed < velocityThreshold {
            intensity = 0
        } else {
            intensity = min((playerState.speed - velocityThreshold) / (1.0 - velocityThreshold), 1.0)
        }

        let colorShift = intensity * maxColorShift
        let pitchShift = intensity * maxPitchShiftSemitones

        return RuleOutput(
            shaderUniforms: [
                "velocityNormalized": playerState.speed,
                "colorShiftAmount": colorShift
            ],
            audioParameters: [
                "pitchShiftSemitones": pitchShift
            ],
            exitTriggered: false,
            nudgeActive: false
        )
    }
}
