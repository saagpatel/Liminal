import simd

extension SIMD3 where Scalar == Float {
    /// Magnitude (length) of the vector.
    var magnitude: Float {
        simd_length(self)
    }

    /// Unit vector in the same direction. Returns zero vector if magnitude is near zero.
    var normalized: SIMD3<Float> {
        let len = magnitude
        guard len > 1e-6 else { return .zero }
        return self / len
    }

    /// Linear interpolation between self and target by factor t (clamped 0–1).
    func lerp(to target: SIMD3<Float>, t: Float) -> SIMD3<Float> {
        let clamped = Swift.min(Swift.max(t, 0), 1)
        return self + (target - self) * clamped
    }
}
