import CoreHaptics

/// CoreHaptics exit-approach feedback. Plays increasing-intensity transient taps
/// as exit condition progress rises from 0% to 100%.
/// Defaults to off; toggled via hidden settings (Phase 4).
@MainActor
final class HapticManager {
    static let shared = HapticManager()

    private var engine: CHHapticEngine?
    private let supportsHaptics: Bool
    private var lastProgress: Float = 0

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "liminal.hapticEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "liminal.hapticEnabled") }
    }

    private init() {
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        guard supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()
            engine?.isAutoShutdownEnabled = true
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
        } catch {
            #if DEBUG
            print("[HapticManager] Engine init failed: \(error)")
            #endif
        }
    }

    func start() {
        guard supportsHaptics, isEnabled else { return }
        try? engine?.start()
    }

    func stop() {
        engine?.stop()
        lastProgress = 0
    }

    /// Call per-frame with exit progress 0.0–1.0.
    /// Throttled: only fires when progress changes by > 0.02.
    func updateExitProgress(_ progress: Float) {
        guard supportsHaptics, isEnabled, progress > 0.05 else { return }
        guard abs(progress - lastProgress) > 0.02 else { return }
        lastProgress = progress

        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: progress)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: progress * 0.5)

        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensity, sharpness],
            relativeTime: 0
        )

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            #if DEBUG
            print("[HapticManager] Play failed: \(error)")
            #endif
        }
    }
}
