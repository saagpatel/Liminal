import SceneKit
import XCTest
@testable import Liminal

@MainActor
final class TransitionManagerTests: XCTestCase {
    func testPermanentFadeDoesNotRestoreGameView() {
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }

        let manager = TransitionManager()
        let view = SCNView()
        let completed = expectation(description: "fade completed")

        manager.fadeOutPermanently(in: view) {
            completed.fulfill()
        }

        wait(for: [completed], timeout: 1)
        XCTAssertEqual(view.alpha, 0)
    }
}
