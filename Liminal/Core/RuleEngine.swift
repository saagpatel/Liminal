import Foundation
import os

/// Per-frame evaluation engine: reads PlayerState → produces RuleOutput →
/// integrates exit condition evaluation and nudge dispatch with thread-safe state.
final class RuleEngine: @unchecked Sendable {
    private var currentRule: (any SpaceRule)?

    private struct MutableState: Sendable {
        var exitCondition: AnyExitCondition?
        var exitTriggered: Bool = false
        // Nudge
        var nudgeConfig: NudgeConfig?
        var nudgeActive: Bool = false
        var nudgePulsePhase: Float = 0
        var lastExitProgress: Float = 0
    }

    private let state: OSAllocatedUnfairLock<MutableState>

    init() {
        state = OSAllocatedUnfairLock(initialState: MutableState())
    }

    // MARK: - Configuration (call before rendering starts)

    func configure(rule: any SpaceRule, exitCondition: AnyExitCondition? = nil,
                   nudgeConfig: NudgeConfig? = nil) {
        currentRule = rule
        state.withLock { s in
            s.exitCondition = exitCondition
            s.exitTriggered = false
            s.nudgeConfig = nudgeConfig
            s.nudgeActive = false
            s.nudgePulsePhase = 0
            s.lastExitProgress = 0
        }
    }

    // MARK: - Per-frame evaluation (render thread)

    func evaluate(playerState: PlayerState) -> RuleOutput {
        guard let rule = currentRule else { return .empty }
        let base = rule.evaluate(playerState: playerState)

        let (exitTriggered, nudgeUniforms) = state.withLock { s -> (Bool, [String: Float]) in
            // Exit condition
            var exitResult = false
            if var condition = s.exitCondition {
                if s.exitTriggered {
                    exitResult = true
                } else {
                    exitResult = condition.evaluate(playerState: playerState, ruleOutput: base)
                    s.exitCondition = condition
                    s.exitTriggered = exitResult
                }
            }

            // Nudge system
            var nudge: [String: Float] = [:]
            if let config = s.nudgeConfig, !s.exitTriggered {
                let currentExitProgress = s.exitCondition?.progress ?? 0

                // Activate nudge if idle too long AND exit progress hasn't increased
                if playerState.idleSeconds > Float(config.idleThresholdSeconds)
                    && currentExitProgress <= s.lastExitProgress {
                    s.nudgeActive = true
                    s.nudgePulsePhase += playerState.deltaTime * 3.0
                    let intensity = (sin(s.nudgePulsePhase) * 0.5 + 0.5)
                    nudge["nudgeIntensity"] = intensity
                    nudge["nudgeVolume"] = intensity * 0.3
                }

                // Reset nudge if player moves or makes progress
                if playerState.idleSeconds < 0.1 || currentExitProgress > s.lastExitProgress + 0.01 {
                    s.nudgeActive = false
                    s.nudgePulsePhase = 0
                }

                s.lastExitProgress = currentExitProgress
            }

            return (exitResult, nudge)
        }

        // Merge nudge uniforms into rule output
        var shaderUniforms = base.shaderUniforms
        var audioParameters = base.audioParameters
        for (key, value) in nudgeUniforms {
            if key == "nudgeVolume" {
                audioParameters[key] = value
            } else {
                shaderUniforms[key] = value
            }
        }

        return RuleOutput(
            shaderUniforms: shaderUniforms,
            audioParameters: audioParameters,
            exitTriggered: exitTriggered,
            nudgeActive: nudgeUniforms["nudgeIntensity"] != nil
        )
    }

    // MARK: - Debug accessors

    /// Exit condition completion progress (0.0–1.0). Safe to read from any thread.
    var exitProgress: Float {
        state.withLock { $0.exitCondition?.progress ?? 0 }
    }
}
