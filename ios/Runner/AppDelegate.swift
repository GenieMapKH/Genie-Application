import Flutter
import GoogleMaps
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    provideMapsApiKey()
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// The key comes from ios/Flutter/Secrets.xcconfig (never committed). Without
  /// one the map stays blank, as on Android; not providing any would crash.
  private func provideMapsApiKey() {
    let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String ?? ""
    if key.isEmpty {
      NSLog("MAPS_API_KEY is not set: the map will stay blank.")
    }
    GMSServices.provideAPIKey(key.isEmpty ? "missing" : key)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerAccessibilityChannel(engineBridge.pluginRegistry)
  }

  /// Settings Flutter does not report itself (see reduce_transparency.dart).
  private func registerAccessibilityChannel(_ registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "TilomnovAccessibility") else { return }
    let channel = FlutterMethodChannel(
      name: "tilomnov/accessibility",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "reduceTransparency":
        result(UIAccessibility.isReduceTransparencyEnabled)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
