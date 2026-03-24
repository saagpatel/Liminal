import UIKit
import SceneKit
import SpriteKit

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
    private let totalSpaces = 7  // All 7 spaces

    private var settingsPanel: UIView?

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
        setupGestures()
        showTitle()  // show title before loading Space 1

        #if DEBUG
        setupDebugOverlay()
        #endif
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        HapticManager.shared.start()
        // Audio starts after title completes (in showTitle callback)
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

    // MARK: - Title Screen

    private func showTitle() {
        let skView = SKView(frame: view.bounds)
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        skView.backgroundColor = .black
        skView.tag = 999  // for removal
        view.addSubview(skView)

        let titleScene = TitleScene(size: view.bounds.size)
        titleScene.scaleMode = .aspectFill
        titleScene.onComplete = { [weak self] in
            skView.removeFromSuperview()
            self?.loadSpace(index: 1)
            self?.startAudio()
        }
        skView.presentScene(titleScene)
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

        let settingsTap = UITapGestureRecognizer(target: self, action: #selector(handleSettingsTap))
        settingsTap.numberOfTapsRequired = 5
        scnView.addGestureRecognizer(settingsTap)
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

    // MARK: - Hidden Settings Panel

    @objc private func handleSettingsTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: scnView)
        // Only trigger in top-left 44×44pt corner
        guard location.x < 44, location.y < 44 else { return }

        if settingsPanel != nil {
            dismissSettings()
        } else {
            showSettings()
        }
    }

    private func showSettings() {
        let panel = UIView(frame: CGRect(x: 20, y: 80, width: 280, height: 200))
        panel.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        panel.layer.cornerRadius = 12

        // Haptic toggle
        let hapticLabel = UILabel(frame: CGRect(x: 16, y: 16, width: 150, height: 30))
        hapticLabel.text = "Haptic Feedback"
        hapticLabel.textColor = .white
        hapticLabel.font = .systemFont(ofSize: 14)
        panel.addSubview(hapticLabel)

        let hapticSwitch = UISwitch(frame: CGRect(x: 220, y: 16, width: 0, height: 0))
        hapticSwitch.isOn = HapticManager.shared.isEnabled
        hapticSwitch.addTarget(self, action: #selector(hapticToggled), for: .valueChanged)
        panel.addSubview(hapticSwitch)

        // Volume slider
        let volumeLabel = UILabel(frame: CGRect(x: 16, y: 60, width: 100, height: 30))
        volumeLabel.text = "Volume"
        volumeLabel.textColor = .white
        volumeLabel.font = .systemFont(ofSize: 14)
        panel.addSubview(volumeLabel)

        let volumeSlider = UISlider(frame: CGRect(x: 100, y: 60, width: 164, height: 30))
        volumeSlider.minimumValue = 0
        volumeSlider.maximumValue = 1
        volumeSlider.value = UserDefaults.standard.float(forKey: "liminal.volume").nonZeroOr(1.0)
        volumeSlider.addTarget(self, action: #selector(volumeChanged), for: .valueChanged)
        panel.addSubview(volumeSlider)

        // Sensitivity slider
        let sensitivityLabel = UILabel(frame: CGRect(x: 16, y: 104, width: 100, height: 30))
        sensitivityLabel.text = "Sensitivity"
        sensitivityLabel.textColor = .white
        sensitivityLabel.font = .systemFont(ofSize: 14)
        panel.addSubview(sensitivityLabel)

        let sensitivitySlider = UISlider(frame: CGRect(x: 100, y: 104, width: 164, height: 30))
        sensitivitySlider.minimumValue = 0.2
        sensitivitySlider.maximumValue = 2.0
        sensitivitySlider.value = UserDefaults.standard.float(forKey: "liminal.sensitivity").nonZeroOr(1.0)
        sensitivitySlider.addTarget(self, action: #selector(sensitivityChanged), for: .valueChanged)
        panel.addSubview(sensitivitySlider)

        // Dismiss button
        let dismissButton = UIButton(frame: CGRect(x: 16, y: 150, width: 248, height: 36))
        dismissButton.setTitle("Done", for: .normal)
        dismissButton.setTitleColor(.white.withAlphaComponent(0.7), for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissSettings), for: .touchUpInside)
        panel.addSubview(dismissButton)

        view.addSubview(panel)
        settingsPanel = panel
    }

    @objc private func dismissSettings() {
        settingsPanel?.removeFromSuperview()
        settingsPanel = nil
    }

    @objc private func hapticToggled(_ sender: UISwitch) {
        HapticManager.shared.isEnabled = sender.isOn
    }

    @objc private func volumeChanged(_ sender: UISlider) {
        UserDefaults.standard.set(sender.value, forKey: "liminal.volume")
    }

    @objc private func sensitivityChanged(_ sender: UISlider) {
        UserDefaults.standard.set(sender.value, forKey: "liminal.sensitivity")
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

// MARK: - Float helper

private extension Float {
    func nonZeroOr(_ fallback: Float) -> Float {
        self == 0 ? fallback : self
    }
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
