import SceneKit
import XCTest
@testable import Liminal

@MainActor
final class AccessibilityTests: XCTestCase {
    func testGameSurfaceExposesSettingsThroughVoiceOverActions() {
        let controller = SpaceViewController()
        controller.loadViewIfNeeded()

        let gameView = controller.view.subviews.compactMap { $0 as? SCNView }.first
        XCTAssertEqual(gameView?.accessibilityLabel, "Liminal game world")
        XCTAssertEqual(
            gameView?.accessibilityCustomActions?.map(\.name),
            ["Open Settings"]
        )
    }
}
