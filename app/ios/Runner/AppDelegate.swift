import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static let settingsChannel = "activotrade/app_settings"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    FlutterMethodChannel(
      name: AppDelegate.settingsChannel,
      binaryMessenger: engineBridge.binaryMessenger
    ).setMethodCallHandler { call, result in
      guard call.method == "openNotificationSettings" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(AppDelegate.openNotificationSettings())
    }
  }

  /// iOS has no notification-only settings page, so this opens the app's own
  /// settings screen — Notifications is the first row there.
  private static func openNotificationSettings() -> Bool {
    guard let url = URL(string: UIApplication.openSettingsURLString),
          UIApplication.shared.canOpenURL(url) else {
      return false
    }
    UIApplication.shared.open(url)
    return true
  }
}
