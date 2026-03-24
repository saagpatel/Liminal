import simd

/// Space 7: all prior rules active simultaneously at 0.2× intensity.
/// Evaluates all 6 rules each frame, scales their outputs, and merges into one RuleOutput.
final class ConvergenceRule: SpaceRule {
    private let intensity: Float = 0.2

    private let doppler: DopplerRule
    private let lensing: LensingRule
    private let shadow: ShadowRule
    private let interference: InterferenceRule
    private let chromatic: ChromaticDecayRule
    private let resonance: ResonanceRule

    init(shaderParams: [String: Double] = [:], audioParams: [String: Double] = [:]) {
        // Each sub-rule gets its own parameters from the convergence JSON's shader.parameters
        // The JSON contains all parameters for all 6 rules, prefixed or shared
        doppler = DopplerRule(shaderParams: shaderParams, audioParams: audioParams)
        lensing = LensingRule(shaderParams: shaderParams, audioParams: audioParams)
        shadow = ShadowRule(shaderParams: shaderParams, audioParams: audioParams)
        interference = InterferenceRule(shaderParams: shaderParams, audioParams: audioParams)
        chromatic = ChromaticDecayRule(shaderParams: shaderParams, audioParams: audioParams)
        resonance = ResonanceRule(shaderParams: shaderParams, audioParams: audioParams)
    }

    func evaluate(playerState: PlayerState) -> RuleOutput {
        let outputs = [
            doppler.evaluate(playerState: playerState),
            lensing.evaluate(playerState: playerState),
            shadow.evaluate(playerState: playerState),
            interference.evaluate(playerState: playerState),
            chromatic.evaluate(playerState: playerState),
            resonance.evaluate(playerState: playerState),
        ]

        // Merge all shader uniforms, scaling intensity-dependent values
        var mergedUniforms: [String: Float] = [:]
        // Pass-through keys (positions, frequencies — not intensity-scaled)
        let passThroughKeys: Set<String> = [
            "playerPositionX", "playerPositionY", "playerPositionZ",
            "sourceAX", "sourceAY", "sourceAZ",
            "sourceBX", "sourceBY", "sourceBZ",
            "waveFrequency", "vibrationFrequency",
        ]

        for output in outputs {
            for (key, value) in output.shaderUniforms {
                if passThroughKeys.contains(key) {
                    mergedUniforms[key] = value  // don't scale position/frequency values
                } else {
                    mergedUniforms[key] = (mergedUniforms[key] ?? 0) + value * intensity
                }
            }
        }

        // Merge audio params (take max for shared keys, scale others)
        var mergedAudio: [String: Float] = [:]
        for output in outputs {
            for (key, value) in output.audioParameters {
                if key == "reverbMix" {
                    mergedAudio[key] = Swift.max(mergedAudio[key] ?? 0, value * intensity)
                } else {
                    mergedAudio[key] = (mergedAudio[key] ?? 0) + value * intensity
                }
            }
        }

        return RuleOutput(
            shaderUniforms: mergedUniforms,
            audioParameters: mergedAudio,
            exitTriggered: false,
            nudgeActive: false
        )
    }
}
