import SceneKit

/// Typed wrapper that pushes [String: Float] uniforms to SCNMaterial per frame.
///
/// Stub — real implementation in Phase 1.
final class ShaderUniformBus: @unchecked Sendable {
    func update(_ material: SCNMaterial, uniforms: [String: Float]) {
        for (key, value) in uniforms {
            material.setValue(value, forKey: key)
        }
    }
}
