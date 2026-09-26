import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "EnvelopeCacheBackup") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "app.planka/envelope_cache_backup",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "excludeFromBackup" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let path = call.arguments as? String else {
        result(FlutterError(
          code: "invalid_cache_path",
          message: "A cache directory path is required",
          details: nil
        ))
        return
      }

      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      do {
        try URL(fileURLWithPath: path, isDirectory: true).setResourceValues(values)
        result(nil)
      } catch {
        result(FlutterError(
          code: "backup_exclusion_failed",
          message: error.localizedDescription,
          details: nil
        ))
      }
    }
  }
}
