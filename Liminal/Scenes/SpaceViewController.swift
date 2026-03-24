import UIKit
import SceneKit

/// Main game view controller. Creates the SCNView, loads space definitions,
/// wires gesture input, runs the per-frame game loop, and manages transitions.
final class SpaceViewController: UIViewController {

    // Set once before rendering starts, then read-only from render thread.
    nonisolated(unsafe) private var spaceScene: SpaceScene?
    nonisolated(unsafe) private var shaderUniformBus = ShaderUniformBus()
    nonisolated(unsafe) private var previousTime: TimeInterval = 0
    nonisolated(unsafe) private var hasStarted = false

    private var scnView: SCNView!
    private var transitionManager = TransitionManager()
    private var spaceDefinition: SpaceDefinition?
    private var currentSpaceIndex = 1
    private let totalSpaces = 6  // Phase 3 supports Spaces 1–6

    #if DEBUG
    private var debugOverlay: DebugOverlay?
    private nonisolated(unsafe) var lastFPSTime: TimeInterval = 0
    private nonisolated(unsafe) var frameCount: Int = 0
    private nonisolated(unsafe) var currentFPS: Int = 60
    #endif

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupSCNView()
        loadSpace(index: currentSpaceIndex)
        setupGestures()

        #if DEBUG
        setupDebugOverlay()
        #endif
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAudio()
        HapticManager.shared.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AudioManager.shared.stopEngine()
        HapticManager.shared.stop()
    }

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }

    // MARK: - Scene Setup

    private func setupSCNView() {
        scnView = SCNView(frame: view.bounds)
        scnView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scnView.backgroundColor = .black
        scnView.rendersContinuously = true
        scnView.isPlaying = true
        scnView.antialiasingMode = .multisampling4X
        scnView.delegate = self
        view.addSubview(scnView)
    }

    private func loadSpace(index: Int) {
        // Find the JSON file matching this space index prefix
        let prefix = String(format: "space_%02d", index)
        let allURLs = Bundle.main.urls(forResourcesWithExtension: "json",
                                       subdirectory: "Resources/Spaces") ?? []
        guard let url = allURLs.first(where: { $0.lastPathComponent.hasPrefix(prefix) }) else {
            #if DEBUG
            print("[SpaceViewController] No JSON found for space index \(index)")
            #endif
            return
        }

        do {
            let name = url.deletingPathExtension().lastPathComponent
            let definition = try SpaceLoader.load(name)
            spaceDefinition = definition
            let scene = try SpaceScene(definition: definition)
            spaceScene = scene
            scnView.scene = scene.scene
            scnView.pointOfView = scene.playerController.cameraNode
            // Reset render loop state for new scene
            hasStarted = false
            previousTime = 0
        } catch {
            #if DEBUG
            print("[SpaceViewController] Failed to load space \(index): \(error)")
            #endif
        }
    }

    private func startAudio() {
        guard let definition = spaceDefinition else { return }
        do {
            try AudioManager.shared.configure(audioConfig: definition.audio)
            AudioManager.shared.startPlayback()
        } catch {
            #if DEBUG
            print("[SpaceViewController] Audio setup failed: \(error)")
            #endif
        }
    }

    // MARK: - Gesture Setup

    private func setupGestures() {
        let lookPan = UIPanGestureRecognizer(target: self, action: #selector(handleLookPan))
        lookPan.minimumNumberOfTouches = 1
        lookPan.maximumNumberOfTouches = 1
        lookPan.delegate = self
        scnView.addGestureRecognizer(lookPan)

        let movePan = UIPanGestureRecognizer(target: self, action: #selector(handleMovePan))
        movePan.minimumNumberOfTouches = 2
        movePan.delegate = self
        scnView.addGestureRecognizer(movePan)

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        pinch.delegate = self
        scnView.addGestureRecognizer(pinch)
    }

    @objc private func handleLookPan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: scnView)
        spaceScene?.playerController.handleLookPan(translation: translation)
        gesture.setTranslation(.zero, in: scnView)
    }

    @objc private func handleMovePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: scnView)
        let isActive = gesture.state == .changed || gesture.state == .began
        spaceScene?.playerController.handleMovePan(translation: translation, isActive: isActive)
        gesture.setTranslation(.zero, in: scnView)
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        spaceScene?.playerController.handlePinch(scale: gesture.scale)
    }

    // MARK: - Exit + Transitions

    private func handleExitTriggered() {
        guard currentSpaceIndex < totalSpaces else {
            // Last space — fade to black and stay
            transitionManager.handleExit(in: scnView) {}
            return
        }

        transitionManager.handleExit(in: scnView) { [weak self] in
            guard let self else { return }
            // Stop audio, release old scene, load next
            AudioManager.shared.stopEngine()
            self.spaceScene = nil
            self.currentSpaceIndex += 1
            self.loadSpace(index: self.currentSpaceIndex)
            self.startAudio()
        }
    }

    // MARK: - Debug Overlay

    #if DEBUG
    private func setupDebugOverlay() {
        let overlay = DebugOverlay(frame: CGRect(x: 0, y: 44, width: 200, height: 200))
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            overlay.widthAnchor.constraint(equalToConstant: 200),
        ])
        debugOverlay = overlay
    }
    #endif
}

// MARK: - SCNSceneRendererDelegate

extension SpaceViewController: SCNSceneRendererDelegate {
    nonisolated func renderer(_ renderer: any SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let scene = spaceScene else { return }

        if !hasStarted {
            previousTime = time
            hasStarted = true
            return
        }
        let deltaTime = Float(Swift.min(time - previousTime, 0.033))
        previousTime = time

        let playerState = scene.playerController.consumeInputAndUpdate(deltaTime: deltaTime)
        let ruleOutput = scene.ruleEngine.evaluate(playerState: playerState)
        shaderUniformBus.update(scene.shaderMaterial, uniforms: ruleOutput.shaderUniforms)

        let audioParams = ruleOutput.audioParameters
        let exitTriggered = ruleOutput.exitTriggered
        let cameraPosition = scene.playerController.cameraNode.simdPosition
        let exitProg = scene.ruleEngine.exitProgress

        #if DEBUG
        frameCount += 1
        if time - lastFPSTime >= 1.0 {
            currentFPS = frameCount
            frameCount = 0
            lastFPSTime = time
        }
        let fps = currentFPS
        let exitProgress = scene.ruleEngine.exitProgress
        let speed = playerState.speed
        let idle = playerState.idleSeconds
        let uniforms = ruleOutput.shaderUniforms
        #endif

        DispatchQueue.main.async { [weak self] in
            AudioManager.shared.updateParameters(audioParams)
            AudioManager.shared.updateListenerPosition(cameraPosition)
            HapticManager.shared.updateExitProgress(exitProg)

            if exitTriggered {
                self?.handleExitTriggered()
            }

            #if DEBUG
            self?.debugOverlay?.update(
                speed: speed,
                uniforms: uniforms,
                fps: fps,
                idleSeconds: idle,
                exitProgress: exitProgress
            )
            #endif
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension SpaceViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
