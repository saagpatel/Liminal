import SpriteKit

/// SpriteKit title screen: "Liminal" fade in/out only.
/// Presented as an SKView overlay on the SpaceViewController before Space 1 loads.
final class TitleScene: SKScene {
    var onComplete: (() -> Void)?

    override func didMove(to view: SKView) {
        backgroundColor = .black

        let label = SKLabelNode(text: "Liminal")
        label.fontName = "SFMono-Light"
        label.fontSize = 48
        label.fontColor = .white
        label.alpha = 0
        label.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(label)

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
