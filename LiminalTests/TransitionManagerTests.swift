import SceneKit
import XCTest
@testable import Liminal

@MainActor
final class TransitionManagerTests: XCTestCase {
    func testPermanentFadeDoesNotRestoreGameView() {
        let manager = TransitionManager()
        let view = SCNView()
        let completed = expectation(description: "fade completed")

        manager.fadeOutPermanently(in: view) {
            completed.fulfill()
        }

        wait(for: [completed], timeout: 2)
        XCTAssertEqual(view.alpha, 0)
    }
}
