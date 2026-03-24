import SceneKit
import simd

/// Constructs an SCNScene for a single space from its JSON definition.
/// Dispatches to the correct geometry builder, rule, exit condition, and lighting
/// based on the definition's types — all driven by JSON, no hardcoding.
final class SpaceScene {
    let scene: SCNScene
    let ruleEngine: RuleEngine
    let playerController: PlayerController
    let shaderMaterial: SCNMaterial

    init(definition: SpaceDefinition) throws {
        scene = SCNScene()

        // 1. Shader material (generic — loads by shader.name)
        shaderMaterial = SpaceScene.createShaderMaterial(shader: definition.shader)

        // 2. Geometry dispatch
        let geometryNode = switch definition.geometry.type {
        case .corridor:  SpaceScene.buildCorridor(config: definition.geometry, material: shaderMaterial)
        case .sphere:    SpaceScene.buildSphereRoom(config: definition.geometry, material: shaderMaterial)
        case .openField: SpaceScene.buildOpenField(config: definition.geometry, material: shaderMaterial, exitParams: definition.exit.parameters)
        case .lattice:   SpaceScene.buildLattice(config: definition.geometry, material: shaderMaterial)
        }
        scene.rootNode.addChildNode(geometryNode)

        // 3. Per-geometry lighting
        SpaceScene.setupLighting(in: scene, geometryType: definition.geometry.type)

        // 4. Player setup — position, yaw, containment, speed per geometry type
        let scale = definition.geometry.scale
        let (startPos, startYaw, containment, baseSpeed) = SpaceScene.playerConfig(
            geometryType: definition.geometry.type, scale: scale
        )
        playerController = PlayerController(
            startPosition: startPos, baseSpeed: baseSpeed,
            containment: containment, startYaw: startYaw
        )
        scene.rootNode.addChildNode(playerController.cameraNode)

        // 5. Rule factory
        ruleEngine = RuleEngine()
        let rule = SpaceScene.createRule(from: definition)
        let exitCondition = SpaceScene.createExitCondition(from: definition)
        ruleEngine.configure(rule: rule, exitCondition: exitCondition, nudgeConfig: definition.nudge)
    }

    // MARK: - Player Configuration

    private static func playerConfig(
        geometryType: GeometryType, scale: SIMD3<Float>
    ) -> (startPos: SIMD3<Float>, startYaw: Float, containment: Containment, baseSpeed: Float) {
        let margin: Float = 0.3
        switch geometryType {
        case .corridor:
            return (
                SIMD3<Float>(-scale.x / 2 + 2, 1.7, 0),
                Float.pi / 2,  // face +X down the corridor
                .rectangular(
                    min: SIMD3(-scale.x / 2 + margin, 1.7, -scale.z / 2 + margin),
                    max: SIMD3(scale.x / 2 - margin, 1.7, scale.z / 2 - margin)),
                scale.x / 8.0
            )
        case .sphere:
            return (
                SIMD3<Float>(0, 1.7, 0),
                0,
                .spherical(center: .zero, radius: scale.x / 2 - 0.5),
                scale.x / 8.0
            )
        case .openField:
            return (
                SIMD3<Float>(0, 1.7, scale.z / 2 - 3),
                0,
                .rectangular(
                    min: SIMD3(-scale.x / 2 + margin, 1.7, -scale.z / 2 + margin),
                    max: SIMD3(scale.x / 2 - margin, 1.7, scale.z / 2 - margin)),
                Swift.max(scale.x, scale.z) / 8.0
            )
        case .lattice:
            return (
                SIMD3<Float>(0, 1.7, scale.z / 2 - 2),
                0,
                .rectangular(
                    min: SIMD3(-scale.x / 2 + margin, 1.7, -scale.z / 2 + margin),
                    max: SIMD3(scale.x / 2 - margin, 1.7, scale.z / 2 - margin)),
                Swift.max(scale.x, scale.z) / 8.0
            )
        }
    }

    // MARK: - Rule Factory

    private static func createRule(from definition: SpaceDefinition) -> any SpaceRule {
        let sp = definition.shader.parameters
        let ap = definition.audio.parameters
        switch definition.shader.name {
        case "Lensing":        return LensingRule(shaderParams: sp, audioParams: ap)
        case "Shadow":         return ShadowRule(shaderParams: sp, audioParams: ap)
        case "Interference":   return InterferenceRule(shaderParams: sp, audioParams: ap)
        case "ChromaticDecay": return ChromaticDecayRule(shaderParams: sp, audioParams: ap)
        case "Resonance":      return ResonanceRule(shaderParams: sp, audioParams: ap)
        default:               return DopplerRule(shaderParams: sp, audioParams: ap)
        }
    }

    // MARK: - Exit Condition Factory

    private static func createExitCondition(from definition: SpaceDefinition) -> AnyExitCondition? {
        let p = definition.exit.parameters
        switch definition.exit.condition {
        case "velocityThresholdHeld":
            return .velocityThresholdHeld(VelocityThresholdHeld(
                targetVelocity: Float(p["targetVelocity"] ?? 0.85),
                durationSeconds: Float(p["durationSeconds"] ?? 3.0)
            ))
        case "enterMassPoint":
            return .enterMassPoint(EnterMassPoint(
                massPoint: SIMD3<Float>(
                    Float(p["massPointX"] ?? 0), Float(p["massPointY"] ?? 0), Float(p["massPointZ"] ?? 0)),
                triggerRadius: Float(p["triggerRadius"] ?? 1.5)
            ))
        case "shadowAlignment":
            return .shadowAlignment(ShadowAlignment(
                grooveAngle: Float(p["grooveAngle"] ?? 0),
                toleranceRadians: Float(p["toleranceRadians"] ?? 0.15),
                requiredDuration: Float(p["requiredDuration"] ?? 2.0)
            ))
        case "silencePoint":
            return .silencePoint(SilencePoint(
                sourceA: SIMD3<Float>(
                    Float(p["sourceAX"] ?? -5), Float(p["sourceAY"] ?? 1.7), Float(p["sourceAZ"] ?? 0)),
                sourceB: SIMD3<Float>(
                    Float(p["sourceBX"] ?? 5), Float(p["sourceBY"] ?? 1.7), Float(p["sourceBZ"] ?? 0)),
                toleranceRadius: Float(p["toleranceRadius"] ?? 0.5)
            ))
        case "stillnessHeld":
            return .stillnessHeld(StillnessHeld(
                requiredDuration: Float(p["requiredDuration"] ?? 10.0),
                speedThreshold: Float(p["speedThreshold"] ?? 0.03)
            ))
        case "resonantSpeedHeld":
            return .resonantSpeedHeld(ResonantSpeedHeld(
                resonantSpeed: Float(p["resonantSpeed"] ?? 0.55),
                speedTolerance: Float(p["speedTolerance"] ?? 0.05),
                requiredDuration: Float(p["requiredDuration"] ?? 5.0)
            ))
        default:
            #if DEBUG
            print("[SpaceScene] Unknown exit condition: \(definition.exit.condition)")
            #endif
            return nil
        }
    }

    // MARK: - Corridor Geometry

    private static func buildCorridor(config: GeometryConfig, material: SCNMaterial) -> SCNNode {
        let length = CGFloat(config.scale.x)
        let height = CGFloat(config.scale.y)
        let width = CGFloat(config.scale.z)
        let subdivisions = config.subdivisions

        let container = SCNNode()
        container.name = "corridor"

        let floor = SCNPlane(width: length, height: width)
        floor.widthSegmentCount = subdivisions
        floor.heightSegmentCount = subdivisions / 4
        floor.materials = [material]
        let floorNode = SCNNode(geometry: floor)
        floorNode.simdEulerAngles = SIMD3<Float>(-.pi / 2, 0, 0)
        floorNode.name = "floor"
        container.addChildNode(floorNode)

        let ceiling = SCNPlane(width: length, height: width)
        ceiling.widthSegmentCount = subdivisions
        ceiling.heightSegmentCount = subdivisions / 4
        ceiling.materials = [material]
        let ceilingNode = SCNNode(geometry: ceiling)
        ceilingNode.simdEulerAngles = SIMD3<Float>(.pi / 2, 0, 0)
        ceilingNode.simdPosition = SIMD3<Float>(0, Float(height), 0)
        ceilingNode.name = "ceiling"
        container.addChildNode(ceilingNode)

        let leftWall = SCNPlane(width: length, height: height)
        leftWall.widthSegmentCount = subdivisions
        leftWall.heightSegmentCount = subdivisions / 4
        leftWall.materials = [material]
        let leftWallNode = SCNNode(geometry: leftWall)
        leftWallNode.simdPosition = SIMD3<Float>(0, Float(height / 2), -Float(width / 2))
        leftWallNode.name = "leftWall"
        container.addChildNode(leftWallNode)

        let rightWall = SCNPlane(width: length, height: height)
        rightWall.widthSegmentCount = subdivisions
        rightWall.heightSegmentCount = subdivisions / 4
        rightWall.materials = [material]
        let rightWallNode = SCNNode(geometry: rightWall)
        rightWallNode.simdEulerAngles = SIMD3<Float>(0, .pi, 0)
        rightWallNode.simdPosition = SIMD3<Float>(0, Float(height / 2), Float(width / 2))
        rightWallNode.name = "rightWall"
        container.addChildNode(rightWallNode)

        let backWall = SCNPlane(width: width, height: height)
        backWall.widthSegmentCount = subdivisions / 4
        backWall.heightSegmentCount = subdivisions / 4
        backWall.materials = [material]
        let backWallNode = SCNNode(geometry: backWall)
        backWallNode.simdEulerAngles = SIMD3<Float>(0, .pi / 2, 0)
        backWallNode.simdPosition = SIMD3<Float>(-Float(length / 2), Float(height / 2), 0)
        backWallNode.name = "backWall"
        container.addChildNode(backWallNode)

        return container
    }

    // MARK: - Sphere Room Geometry

    private static func buildSphereRoom(config: GeometryConfig, material: SCNMaterial) -> SCNNode {
        let sphere = SCNSphere(radius: CGFloat(config.scale.x / 2))
        sphere.segmentCount = config.subdivisions
        sphere.materials = [material]
        let node = SCNNode(geometry: sphere)
        node.name = "sphereRoom"
        return node
    }

    // MARK: - Lattice Geometry

    private static func buildLattice(config: GeometryConfig, material: SCNMaterial) -> SCNNode {
        let container = SCNNode()
        container.name = "lattice"

        let sizeX = config.scale.x
        let sizeY = config.scale.y
        let sizeZ = config.scale.z
        let spacing: Float = 2.0
        let beamRadius: CGFloat = 0.04

        let xSteps = Int(sizeX / spacing) + 1
        let ySteps = Int(sizeY / spacing) + 1
        let zSteps = Int(sizeZ / spacing) + 1

        // X-axis beams
        for yi in 0..<ySteps {
            for zi in 0..<zSteps {
                let beam = SCNCylinder(radius: beamRadius, height: CGFloat(sizeX))
                beam.radialSegmentCount = 6
                beam.materials = [material]
                let node = SCNNode(geometry: beam)
                node.simdEulerAngles = SIMD3<Float>(0, 0, .pi / 2)
                node.simdPosition = SIMD3<Float>(
                    0,
                    Float(yi) * spacing,
                    -sizeZ / 2 + Float(zi) * spacing
                )
                container.addChildNode(node)
            }
        }

        // Y-axis beams (vertical)
        for xi in 0..<xSteps {
            for zi in 0..<zSteps {
                let beam = SCNCylinder(radius: beamRadius, height: CGFloat(sizeY))
                beam.radialSegmentCount = 6
                beam.materials = [material]
                let node = SCNNode(geometry: beam)
                node.simdPosition = SIMD3<Float>(
                    -sizeX / 2 + Float(xi) * spacing,
                    sizeY / 2,
                    -sizeZ / 2 + Float(zi) * spacing
                )
                container.addChildNode(node)
            }
        }

        // Z-axis beams
        for xi in 0..<xSteps {
            for yi in 0..<ySteps {
                let beam = SCNCylinder(radius: beamRadius, height: CGFloat(sizeZ))
                beam.radialSegmentCount = 6
                beam.materials = [material]
                let node = SCNNode(geometry: beam)
                node.simdEulerAngles = SIMD3<Float>(.pi / 2, 0, 0)
                node.simdPosition = SIMD3<Float>(
                    -sizeX / 2 + Float(xi) * spacing,
                    Float(yi) * spacing,
                    0
                )
                container.addChildNode(node)
            }
        }

        // Floor plane for walking on
        let floor = SCNPlane(width: CGFloat(sizeX), height: CGFloat(sizeZ))
        floor.materials = [material]
        let floorNode = SCNNode(geometry: floor)
        floorNode.simdEulerAngles = SIMD3<Float>(-.pi / 2, 0, 0)
        floorNode.name = "floor"
        container.addChildNode(floorNode)

        return container
    }

    // MARK: - Open Field Geometry

    private static func buildOpenField(config: GeometryConfig, material: SCNMaterial,
                                       exitParams: [String: Double]) -> SCNNode {
        let container = SCNNode()
        container.name = "openField"

        // Floor
        let floor = SCNPlane(width: CGFloat(config.scale.x), height: CGFloat(config.scale.z))
        floor.widthSegmentCount = config.subdivisions
        floor.heightSegmentCount = config.subdivisions
        floor.materials = [material]
        let floorNode = SCNNode(geometry: floor)
        floorNode.simdEulerAngles = SIMD3<Float>(-.pi / 2, 0, 0)
        floorNode.name = "floor"
        container.addChildNode(floorNode)

        // Shadow groove — thin dark strip on floor as visual hint
        let grooveAngle = Float(exitParams["grooveAngle"] ?? 0.785)
        let grooveWidth: Float = 0.15
        let grooveLength = config.scale.x * 0.6
        let groove = SCNPlane(width: CGFloat(grooveLength), height: CGFloat(grooveWidth))
        let grooveMaterial = SCNMaterial()
        grooveMaterial.diffuse.contents = UIColor(white: 0.3, alpha: 1.0)
        groove.materials = [grooveMaterial]
        let grooveNode = SCNNode(geometry: groove)
        grooveNode.simdEulerAngles = SIMD3<Float>(-.pi / 2, grooveAngle, 0)
        grooveNode.simdPosition = SIMD3<Float>(0, 0.001, 0)
        grooveNode.name = "groove"
        container.addChildNode(grooveNode)

        return container
    }

    // MARK: - Material + Shader (generic)

    private static func createShaderMaterial(shader: ShaderConfig) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(white: 0.7, alpha: 1.0)
        material.lightingModel = .physicallyBased
        material.isDoubleSided = true

        var modifiers: [SCNShaderModifierEntryPoint: String] = [:]

        // Fragment shader (all spaces)
        if let url = Bundle.main.url(forResource: shader.name, withExtension: "metal",
                                     subdirectory: "Shaders"),
           let source = try? String(contentsOf: url, encoding: .utf8) {
            modifiers[.fragment] = source
        }

        // Geometry/vertex shader (auto-detected: [Name]Geometry.metal)
        if let geoURL = Bundle.main.url(forResource: "\(shader.name)Geometry",
                                        withExtension: "metal", subdirectory: "Shaders"),
           let geoSource = try? String(contentsOf: geoURL, encoding: .utf8) {
            modifiers[.geometry] = geoSource
        }

        if modifiers.isEmpty {
            #if DEBUG
            print("[SpaceScene] Failed to load \(shader.name).metal — using fallback red shader")
            #endif
            modifiers[.fragment] = """
            #pragma body
            _output.color = float4(1.0, 0.0, 0.0, 1.0);
            """
        }

        material.shaderModifiers = modifiers

        // Set initial static uniforms from JSON parameters
        for (key, value) in shader.parameters {
            material.setValue(Float(value), forKey: key)
        }

        return material
    }

    // MARK: - Lighting (per geometry type)

    private static func setupLighting(in scene: SCNScene, geometryType: GeometryType) {
        let ambientNode = SCNNode()
        ambientNode.light = SCNLight()
        ambientNode.light?.type = .ambient
        ambientNode.name = "ambientLight"

        let directionalNode = SCNNode()
        directionalNode.light = SCNLight()
        directionalNode.light?.type = .directional
        directionalNode.name = "directionalLight"

        switch geometryType {
        case .corridor:
            ambientNode.light?.intensity = 200
            ambientNode.light?.color = UIColor(white: 0.85, alpha: 1.0)
            directionalNode.light?.intensity = 600
            directionalNode.light?.castsShadow = false
            directionalNode.simdEulerAngles = SIMD3<Float>(-.pi / 4, .pi / 6, 0)

        case .lattice:
            ambientNode.light?.intensity = 350
            ambientNode.light?.color = UIColor(white: 0.8, alpha: 1.0)
            directionalNode.light?.intensity = 400
            directionalNode.light?.castsShadow = false
            directionalNode.simdEulerAngles = SIMD3<Float>(-.pi / 3, .pi / 5, 0)

        case .sphere:
            // High ambient for sphere interior (normals face outward, directional unreliable)
            ambientNode.light?.intensity = 500
            ambientNode.light?.color = UIColor(white: 0.9, alpha: 1.0)
            directionalNode.light?.intensity = 200
            directionalNode.light?.castsShadow = false
            directionalNode.simdEulerAngles = SIMD3<Float>(-.pi / 3, 0, 0)

        case .openField:
            ambientNode.light?.intensity = 300
            ambientNode.light?.color = UIColor(white: 0.8, alpha: 1.0)
            directionalNode.light?.intensity = 500
            directionalNode.light?.castsShadow = false  // prevent conflict with faux shadow shader
            directionalNode.simdEulerAngles = SIMD3<Float>(-.pi / 2.5, .pi / 4, 0)
        }

        scene.rootNode.addChildNode(ambientNode)
        scene.rootNode.addChildNode(directionalNode)
    }
}
