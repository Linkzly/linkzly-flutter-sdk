import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    continue userActivity: NSUserActivity
  ) {
    super.scene(scene, continue: userActivity)
    NSLog("[LinkzlyExample] scene continue userActivity: \(userActivity.webpageURL?.absoluteString ?? "nil")")
  }

  override func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    super.scene(scene, openURLContexts: URLContexts)
    for context in URLContexts {
      NSLog("[LinkzlyExample] scene openURL: \(context.url.absoluteString)")
    }
  }
}
