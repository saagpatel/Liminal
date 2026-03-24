import simd

// MARK: - Top-level definition

struct SpaceDefinition: Codable, Sendable {
    let id: String
    let index: Int
    let geometry: GeometryConfig
    let shader: ShaderConfig
    let audio: AudioConfig
    let exit: ExitConfig
    let nudge: NudgeConfig
}

// MARK: - Geometry

struct GeometryConfig: Sendable {
    let type: GeometryType
    let scale: SIMD3<Float>
    let subdivisions: Int
}

extension GeometryConfig: Codable {
    enum CodingKeys: String, CodingKey {
        case type, scale, subdivisions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(GeometryType.self, forKey: .type)
        subdivisions = try container.decode(Int.self, forKey: .subdivisions)

        let scaleArray = try container.decode([Float].self, forKey: .scale)
        guard scaleArray.count == 3 else {
            throw DecodingError.dataCorruptedError(
                forKey: .scale,
                in: container,
                debugDescription: "scale must be an array of exactly 3 floats, got \(scaleArray.count)"
            )
        }
        scale = SIMD3<Float>(scaleArray[0], scaleArray[1], scaleArray[2])
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(subdivisions, forKey: .subdivisions)
        try container.encode([scale.x, scale.y, scale.z], forKey: .scale)
    }
}

enum GeometryType: String, Codable, Sendable {
    case corridor
    case sphere
    case lattice
    case openField = "open_field"
}

// MARK: - Shader

struct ShaderConfig: Codable, Sendable {
    let name: String
    let parameters: [String: Double]
}

// MARK: - Audio

struct AudioSourceDefinition: Codable, Sendable {
    let stem: String
    let position: [Float]  // [x, y, z]
}

struct AudioConfig: Codable, Sendable {
    let stem: String
    let rule: String
    let parameters: [String: Double]
    /// Multiple positioned audio sources (e.g. Space 4 interference).
    /// When nil, single `stem` is used. When present, each source has its own stem + 3D position.
    let sources: [AudioSourceDefinition]?
}

// MARK: - Exit

struct ExitConfig: Codable, Sendable {
    let condition: String
    let parameters: [String: Double]
}

// MARK: - Nudge

struct NudgeConfig: Codable, Sendable {
    let idleThresholdSeconds: Double
    let type: NudgeType
}

enum NudgeType: String, Codable, Sendable {
    case amplitudeFlare
    case colorPulse
    case shadowReveal
}
