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
    private let appStoreScreenshotIndex: Int? = {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flag = arguments.firstIndex(of: "-AppStoreScreenshot") else { return nil }
        guard arguments.indices.contains(flag + 1),
              let index = Int(arguments[flag + 1]), (1...8).contains(index) else {
            fatalError("-AppStoreScreenshot requires a number from 1 through 8")
        }
        return index
    }()
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
        #if DEBUG
        if let index = appStoreScreenshotIndex {
            showAppStoreScreenshot(index: index)
            return
        }
        #endif
        setupGestures()
        showTitle()  // show title before loading Space 1

        #if DEBUG
        setupDebugOverlay()
        #endif
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        #if DEBUG
        if appStoreScreenshotIndex != nil {
            setNeedsUpdateOfSupportedInterfaceOrientations()
            view.window?.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            return
        }
        #endif
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

    #if DEBUG
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        appStoreScreenshotIndex == nil ? super.supportedInterfaceOrientations : .portrait
    }
    #endif

    // MARK: - Scene Setup

    private func setupSCNView() {
        scnView = SCNView(frame: view.bounds)
        scnView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scnView.backgroundColor = .black
        scnView.rendersContinuously = true
        scnView.isPlaying = true
        scnView.antialiasingMode = .multisampling4X
        scnView.delegate = self
        scnView.isAccessibilityElement = true
        scnView.accessibilityLabel = "Liminal game world"
        scnView.accessibilityHint = "Explore with drag gestures. Use the Actions rotor to open settings."
        scnView.accessibilityCustomActions = [
            UIAccessibilityCustomAction(
                name: "Open Settings",
                target: self,
                selector: #selector(openSettingsAccessibilityAction)
            )
        ]
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
        #if DEBUG
        if appStoreScreenshotIndex == 4 {
            titleScene.appStoreScreenshotTime = 1.5
            titleScene.scaleMode = .resizeFill
        }
        #endif
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
                                       subdirectory: "Spaces") ?? []
        guard let url = allURLs.first(where: { $0.lastPathComponent.hasPrefix(prefix) }) else {
            #if DEBUG
            print("[SpaceViewController] No JSON found for space index \(index)")
            #endif
            presentRuntimeError(
                title: "Space Unavailable",
                message: "Liminal could not load Space \(index). Relaunch the app to try again."
            )
            return
        }

        do {
            let name = url.deletingPathExtension().lastPathComponent
            let definition = try SpaceLoader.load(name)
            spaceDefinition = definition
            let scene = try SpaceScene(definition: definition)
            let savedSensitivity = UserDefaults.standard.object(forKey: "liminal.sensitivity") == nil
                ? 1
                : UserDefaults.standard.float(forKey: "liminal.sensitivity")
            scene.playerController.setControlSensitivity(savedSensitivity)
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
            presentRuntimeError(
                title: "Space Unavailable",
                message: "Liminal could not load Space \(index). Relaunch the app to try again."
            )
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
            presentRuntimeError(
                title: "Audio Unavailable",
                message: "Liminal could not start its soundscape. Check your audio output and relaunch the app."
            )
        }
    }

    private func presentRuntimeError(title: String, message: String) {
        guard presentedViewController == nil else { return }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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

    @objc private func openSettingsAccessibilityAction() -> Bool {
        if settingsPanel == nil {
            showSettings()
        }
        UIAccessibility.post(notification: .screenChanged, argument: settingsPanel)
        return true
    }

    private func showSettings() {
        let panel = UIView(frame: CGRect(x: 20, y: 80, width: 280, height: 200))
        panel.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        panel.layer.cornerRadius = 12

        // Haptic toggle
        let hapticLabel = UILabel(frame: CGRect(x: 16, y: 16, width: 150, height: 30))
        hapticLabel.text = "Haptic Feedback"
        hapticLabel.accessibilityIdentifier = "settings.haptics.label"
        hapticLabel.textColor = .white
        hapticLabel.font = .systemFont(ofSize: 14)
        panel.addSubview(hapticLabel)

        let hapticSwitch = UISwitch(frame: CGRect(x: 220, y: 16, width: 0, height: 0))
        hapticSwitch.isOn = HapticManager.shared.isEnabled
        hapticSwitch.accessibilityLabel = "Haptic feedback"
        hapticSwitch.accessibilityIdentifier = "settings.haptics"
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
        volumeSlider.value = UserDefaults.standard.object(forKey: "liminal.volume") == nil
            ? 1
            : UserDefaults.standard.float(forKey: "liminal.volume")
        volumeSlider.accessibilityLabel = "Volume"
        volumeSlider.accessibilityIdentifier = "settings.volume"
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
        sensitivitySlider.value = UserDefaults.standard.object(forKey: "liminal.sensitivity") == nil
            ? 1
            : UserDefaults.standard.float(forKey: "liminal.sensitivity")
        sensitivitySlider.accessibilityLabel = "Control sensitivity"
        sensitivitySlider.accessibilityIdentifier = "settings.sensitivity"
        sensitivitySlider.addTarget(self, action: #selector(sensitivityChanged), for: .valueChanged)
        panel.addSubview(sensitivitySlider)

        // Dismiss button
        let dismissButton = UIButton(frame: CGRect(x: 16, y: 150, width: 248, height: 36))
        dismissButton.setTitle("Done", for: .normal)
        dismissButton.accessibilityIdentifier = "settings.done"
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
        AudioManager.shared.setMasterVolume(sender.value)
    }

    @objc private func sensitivityChanged(_ sender: UISlider) {
        UserDefaults.standard.set(sender.value, forKey: "liminal.sensitivity")
        spaceScene?.playerController.setControlSensitivity(sender.value)
    }

    // MARK: - Exit + Transitions

    private func handleExitTriggered() {
        guard currentSpaceIndex < totalSpaces else {
            AudioManager.shared.stopEngine()
            HapticManager.shared.stop()
            transitionManager.fadeOutPermanently(in: scnView)
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
    /// Uses the bundled spaces and their real rules, then holds one gameplay frame.
    /// No input, audio, haptics, progression, nudge, or overlay runs during capture.
    private func showAppStoreScreenshot(index: Int) {
        scnView.delegate = nil
        scnView.isPlaying = false
        scnView.sceneTime = 1.25
        if index == 4 {
            showTitle()
            return
        }

        switch index {
        case 1: currentSpaceIndex = 1
        case 2: currentSpaceIndex = 2
        case 3: currentSpaceIndex = 5
        case 5: currentSpaceIndex = 3
        case 6: currentSpaceIndex = 6
        case 7: currentSpaceIndex = 7
        case 8: currentSpaceIndex = 4
        default: preconditionFailure("Invalid screenshot index")
        }
        loadSpace(index: currentSpaceIndex)
        guard let scene = spaceScene, let definition = spaceDefinition else { return }

        let position: SIMD3<Float>
        let angles: SIMD3<Float>
        switch definition.geometry.type {
        case .corridor:
            position = SIMD3(-definition.geometry.scale.x * 0.25, 1.7, 0)
            angles = SIMD3(-0.06, -.pi / 2, 0)
        case .sphere:
            if index == 6 {
                // Look tangentially along the nearby wall so its curvature and
                // ordinary vertex displacement occupy more of the frame.
                position = SIMD3(definition.geometry.scale.x / 2 - 1, 1.7, 0)
                angles = SIMD3(-0.10, 0, 0)
            } else {
                position = SIMD3(1, 1.7, 2)
                angles = SIMD3(0.12, -0.4, 0)
            }
        case .openField:
            if index == 5 {
                // Frame the real field boundary, facing away from the central
                // groove: that authored exit hint must stay out of the shot.
                position = SIMD3(definition.geometry.scale.x / 2 - 3, 1.7,
                                 definition.geometry.scale.z * 0.2)
                angles = SIMD3(-0.55, -.pi / 3, 0)
            } else {
                position = SIMD3(2, 1.7, 5)
                angles = SIMD3(-0.45, -0.25, 0)
            }
        case .lattice:
            position = SIMD3(1, 1.7, 7)
            angles = SIMD3(-0.12, 0.25, 0)
        }
        let camera = scene.playerController.cameraNode
        camera.simdPosition = position
        camera.simdEulerAngles = angles

        let speed: Float
        if index == 1 {
            speed = 0.75
        } else if index == 5 {
            speed = 0.35
        } else if index == 6 || index == 7 {
            // Read effect parameters from the authored JSON rather than duplicate them.
            let parameters = definition.shader.parameters
            // Partial resonance retains more of the wall's lighting variation.
            let falloffFraction: Float = index == 6 ? 0.4 : 0.2
            speed = Float(parameters["resonantSpeed"] ?? 0.55)
                + Float(parameters["falloffWidth"] ?? 0.15) * falloffFraction
        } else {
            speed = 0
        }
        // One deterministic stillness step gives partial desaturation through the
        // existing rule. Other shots need only a single ordinary evaluation step.
        let deltaTime: Float = index == 3
            ? Float(definition.shader.parameters["maxDesaturationSeconds"] ?? 15) * 0.5
            : 1.0 / 60.0
        let playerState = PlayerState(
            position: position,
            velocity: camera.simdWorldFront * speed * scene.playerController.baseMovementSpeed * 3,
            speed: speed,
            lookDirection: camera.simdWorldFront,
            idleSeconds: speed == 0 ? deltaTime : 0,
            deltaTime: deltaTime
        )
        let output = scene.ruleEngine.evaluate(playerState: playerState)
        shaderUniformBus.update(scene.shaderMaterial, uniforms: output.shaderUniforms)
        scene.shaderMaterial.setValue(Float(0), forKey: "nudgeIntensity")

        // SceneKit's shader clock can advance independently of sceneTime. Freeze
        // only the clock expression in the existing modifiers, leaving their
        // authored geometry, patterns, and effect amplitudes intact.
        scene.shaderMaterial.shaderModifiers = scene.shaderMaterial.shaderModifiers?.mapValues {
            $0.replacingOccurrences(of: "scn_frame.time", with: "1.25")
        }
    }

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
