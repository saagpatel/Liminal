import SwiftUI

@main
struct LiminalApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            GameView()
                .ignoresSafeArea()
                .statusBarHidden()
                .persistentSystemOverlays(.hidden)
        }
    }
}

/// Wraps the SceneKit game view for SwiftUI hosting.
struct GameView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> SpaceViewController {
        SpaceViewController()
    }

    func updateUIViewController(_ uiViewController: SpaceViewController, context: Context) {}
}
