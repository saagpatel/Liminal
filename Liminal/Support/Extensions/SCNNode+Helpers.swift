import SceneKit

extension SCNNode {
    /// Convenience lookup for a named child node (non-recursive by default).
    func child(named name: String, recursively: Bool = false) -> SCNNode? {
        childNode(withName: name, recursively: recursively)
    }

    /// Current position as SIMD3<Float>.
    var simdPos: SIMD3<Float> {
        get { simdPosition }
        set { simdPosition = newValue }
    }
}
