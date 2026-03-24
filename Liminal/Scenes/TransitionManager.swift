import SceneKit

/// Manages fade-out → scene swap → fade-in transitions between spaces.
/// Phase 2: 0.75s fade out + swap + 0.75s fade in = 1.5s total.
@MainActor
final class TransitionManager {
    private var isTransitioning = false

    /// Fades out the view, calls completion (for scene swap), then fades back in.
    func handleExit(in view: SCNView, completion: @escaping () -> Void) {
        guard !isTransitioning else { return }
        isTransitioning = true

        UIView.animate(withDuration: 0.75, animations: {
            view.alpha = 0
        }, completion: { _ in
            completion()

            UIView.animate(withDuration: 0.75, animations: {
                view.alpha = 1
            }, completion: { _ in
                self.isTransitioning = false
            })
        })
    }
}
