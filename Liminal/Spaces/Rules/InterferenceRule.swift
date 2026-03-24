import simd

/// Space 4: position between two audio nodes → phase cancellation.
/// Computes cancellation factor from player position relative to two fixed sources.
/// At the midpoint, audio cancels completely (silence).
struct InterferenceRule: SpaceRule {
    let sourceA: SIMD3<Float>
    let sourceB: SIMD3<Float>
    let waveFrequency: Float

    init(shaderParams: [String: Double] = [:], audioParams: [String: Double] = [:]) {
        sourceA = SIMD3<Float>(
            Float(shaderParams["sourceAX"] ?? -6.0),
            Float(shaderParams["sourceAY"] ?? 1.7),
            Float(shaderParams["sourceAZ"] ?? 0.0)
        )
        sourceB = SIMD3<Float>(
            Float(shaderParams["sourceBX"] ?? 6.0),
            Float(shaderParams["sourceBY"] ?? 1.7),
            Float(shaderParams["sourceBZ"] ?? 0.0)
        )
        waveFrequency = Float(shaderParams["waveFrequency"] ?? 8.0)
    }

    func evaluate(playerState: PlayerState) -> RuleOutput {
        let distA = simd_distance(playerState.position, sourceA)
        let distB = simd_distance(playerState.position, sourceB)
        let halfSpan = simd_distance(sourceA, sourceB) / 2.0

        // Cancellation = 1 when equidistant from both sources (path diff = 0)
        // Cancellation = 0 when at either source (path diff = full span)
        let pathDiff = abs(distA - distB)
        let cancellation = Swift.max(0, 1.0 - pathDiff / Swift.max(halfSpan, 0.01))
        let amplitude = 1.0 - cancellation

        return RuleOutput(
            shaderUniforms: [
                "cancellationFactor": cancellation,
                "sourceAX": sourceA.x, "sourceAY": sourceA.y, "sourceAZ": sourceA.z,
                "sourceBX": sourceB.x, "sourceBY": sourceB.y, "sourceBZ": sourceB.z,
                "waveFrequency": waveFrequency,
                "playerPositionX": playerState.position.x,
                "playerPositionZ": playerState.position.z,
            ],
            audioParameters: [
                "amplitude": amplitude,
                "cancellationFactor": cancellation,
            ],
            exitTriggered: false,
            nudgeActive: false
        )
    }
}
