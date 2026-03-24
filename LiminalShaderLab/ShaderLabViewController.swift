import UIKit
import SceneKit

final class ShaderLabViewController: UIViewController {
    private var scnView: SCNView!
    private var displayLink: CADisplayLink?
    private var startTime: CFTimeInterval = 0
    private var boxMaterial: SCNMaterial!
    private var shaderSegment: UISegmentedControl!

    private let shaderNames = [
        "DopplerTest", "LensingTest", "ShadowTest",
        "InterferenceTest", "ChromaticDecayTest", "ResonanceTest"
    ]
    // Shaders that also have a geometry modifier (loaded alongside fragment)
    private let geometryShaderNames: Set<String> = ["ResonanceTest"]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        setupShaderSelector()
        loadShader(named: shaderNames[0])
        startDisplayLink()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopDisplayLink()
    }

    // MARK: - Scene Setup

    private func setupScene() {
        scnView = SCNView(frame: view.bounds)
        scnView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scnView.backgroundColor = .black
        scnView.rendersContinuously = true
        scnView.antialiasingMode = .multisampling4X
        view.addSubview(scnView)

        let scene = SCNScene()
        scnView.scene = scene

        let box = SCNBox(width: 2, height: 2, length: 2, chamferRadius: 0.1)
        box.widthSegmentCount = 20
        box.heightSegmentCount = 20
        box.lengthSegmentCount = 20
        boxMaterial = SCNMaterial()
        boxMaterial.diffuse.contents = UIColor.white
        boxMaterial.lightingModel = .physicallyBased
        boxMaterial.isDoubleSided = true
        box.materials = [boxMaterial]

        let boxNode = SCNNode(geometry: box)
        boxNode.runAction(.repeatForever(.rotateBy(x: 0.5, y: 1.0, z: 0.3, duration: 4.0)))
        scene.rootNode.addChildNode(boxNode)

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 6)
        scene.rootNode.addChildNode(cameraNode)

        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.light?.intensity = 1000
        lightNode.position = SCNVector3(3, 5, 5)
        scene.rootNode.addChildNode(lightNode)

        let ambientNode = SCNNode()
        ambientNode.light = SCNLight()
        ambientNode.light?.type = .ambient
        ambientNode.light?.intensity = 300
        scene.rootNode.addChildNode(ambientNode)
    }

    // MARK: - Shader Selector

    private func setupShaderSelector() {
        shaderSegment = UISegmentedControl(
            items: ["Dopp", "Lens", "Shad", "Intf", "Chrom", "Res"]
        )
        shaderSegment.selectedSegmentIndex = 0
        shaderSegment.translatesAutoresizingMaskIntoConstraints = false
        shaderSegment.addTarget(self, action: #selector(shaderChanged), for: .valueChanged)
        shaderSegment.backgroundColor = .black.withAlphaComponent(0.5)
        shaderSegment.selectedSegmentTintColor = .white.withAlphaComponent(0.3)
        shaderSegment.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        shaderSegment.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        view.addSubview(shaderSegment)

        NSLayoutConstraint.activate([
            shaderSegment.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            shaderSegment.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    @objc private func shaderChanged(_ sender: UISegmentedControl) {
        let name = shaderNames[sender.selectedSegmentIndex]
        loadShader(named: name)
        startTime = CACurrentMediaTime()
    }

    // MARK: - Shader

    private func loadShader(named name: String) {
        var modifiers: [SCNShaderModifierEntryPoint: String] = [:]

        // Fragment shader
        if let url = Bundle.main.url(forResource: name, withExtension: "metal"),
           let source = try? String(contentsOf: url, encoding: .utf8) {
            modifiers[.fragment] = source
        }

        // Geometry shader (if this shader has one)
        if geometryShaderNames.contains(name) {
            let geoName = name.replacingOccurrences(of: "Test", with: "GeometryTest")
            if let url = Bundle.main.url(forResource: geoName, withExtension: "metal"),
               let source = try? String(contentsOf: url, encoding: .utf8) {
                modifiers[.geometry] = source
            }
        }

        if modifiers.isEmpty {
            #if DEBUG
            print("[ShaderLab] Failed to load \(name).metal — falling back to solid red")
            #endif
            modifiers[.fragment] = """
            #pragma body
            _output.color = float4(1.0, 0.0, 0.0, 1.0);
            """
        }

        boxMaterial.shaderModifiers = modifiers
    }

    // MARK: - Display Link

    private func startDisplayLink() {
        startTime = CACurrentMediaTime()
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkFired))
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func displayLinkFired(_ link: CADisplayLink) {
        let elapsed = Float(link.timestamp - startTime)
        boxMaterial.setValue(NSNumber(value: elapsed), forKey: "time")
    }
}
