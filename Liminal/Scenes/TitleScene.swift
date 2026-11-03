import SpriteKit

/// SpriteKit title screen: "Liminal" fade in/out only.
/// Presented as an SKView overlay on the SpaceViewController before Space 1 loads.
final class TitleScene: SKScene {
    var onComplete: (() -> Void)?

    #if DEBUG
    var appStoreScreenshotTime: TimeInterval?

    override func didChangeSize(_ oldSize: CGSize) {
        if appStoreScreenshotTime != nil {
            children.first?.position = CGPoint(x: frame.midX, y: frame.midY)
        }
    }
    #endif

    override func didMove(to view: SKView) {
        backgroundColor = .black

        let label = SKLabelNode(text: "Liminal")
        label.fontName = "Menlo-Regular"
        label.fontSize = 48
        label.fontColor = .white
        label.alpha = 0
        label.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(label)

        #if DEBUG
        if let time = appStoreScreenshotTime {
            // Sample the real 1.5s fade-in / 1s hold / 1.5s fade-out timeline.
            label.alpha = CGFloat(max(0, min(1, min(time / 1.5, (4 - time) / 1.5))))
            return
        }
        #endif

        // Fade in 1.5s → hold 1.0s → fade out 1.5s → notify completion
        let sequence = SKAction.sequence([
            SKAction.fadeIn(withDuration: 1.5),
            SKAction.wait(forDuration: 1.0),
            SKAction.fadeOut(withDuration: 1.5),
            SKAction.run { [weak self] in
                self?.onComplete?()
            }
        ])
        label.run(sequence)
    }
}
