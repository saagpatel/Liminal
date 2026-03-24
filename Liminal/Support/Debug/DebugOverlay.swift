#if DEBUG
import UIKit

/// Debug overlay showing FPS, speed, idle time, exit progress, and uniform values.
/// Visible only in DEBUG builds.
final class DebugOverlay: UIView {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLabel()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func setupLabel() {
        label.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        label.textColor = .white.withAlphaComponent(0.7)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
        ])
        isUserInteractionEnabled = false
        backgroundColor = UIColor.black.withAlphaComponent(0.3)
        layer.cornerRadius = 6
    }

    func update(speed: Float, uniforms: [String: Float],
                fps: Int, idleSeconds: Float, exitProgress: Float) {
        var lines = [
            "FPS: \(fps)",
            "SPD: \(String(format: "%.2f", speed))",
            "IDL: \(String(format: "%.1f", idleSeconds))s",
            "EXIT: \(String(format: "%.0f", exitProgress * 100))%"
        ]
        for (key, value) in uniforms.sorted(by: { $0.key < $1.key }) {
            lines.append("\(key): \(String(format: "%.3f", value))")
        }
        label.text = lines.joined(separator: "\n")
    }
}
#endif
