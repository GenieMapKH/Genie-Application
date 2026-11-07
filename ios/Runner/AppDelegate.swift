import AVFAudio
import CallKit
import WebRTC
import Flutter
import GoogleMaps
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var nativeCalls: NativeCalls?

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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "TilomnovCalls") {
      nativeCalls = NativeCalls(messenger: registrar.messenger())
    }
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


/// CallKit supplies the system call controls and supported devices' call indicator.
private final class NativeCalls: NSObject, CXProviderDelegate {
  private let channel: FlutterMethodChannel
  private let provider: CXProvider
  private let controller = CXCallController()
  private var current: UUID?
  private var connected = false
  private var answerRequested = false

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "tilomnov/call", binaryMessenger: messenger)
    let configuration = CXProviderConfiguration(localizedName: "Tilomnov")
    configuration.supportedHandleTypes = [.generic]
    configuration.maximumCallsPerCallGroup = 1
    configuration.maximumCallGroups = 1
    configuration.includesCallsInRecents = false
    provider = CXProvider(configuration: configuration)
    super.init()
    provider.setDelegate(self, queue: .main)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "update", let args = call.arguments as? [String: Any], let self else {
        result(FlutterMethodNotImplemented); return
      }
      self.update(args, result: result)
    }
  }

  private func update(_ args: [String: Any], result: @escaping FlutterResult) {
    let phase = args["phase"] as? String ?? "idle"
    if phase == "ended" || phase == "idle" {
      if let id = current { provider.reportCall(with: id, endedAt: Date(), reason: .remoteEnded) }
      current = nil
      connected = false
      result(nil)
      return
    }
    guard let text = args["id"] as? String, let id = UUID(uuidString: text) else {
      result(FlutterError(code: "call_id", message: "Invalid call identifier", details: nil)); return
    }
    let caller = args["caller"] as? Bool ?? false
    if current != id {
      current = id
      connected = false
      answerRequested = false
      let name = args["name"] as? String ?? "Tilomnov"
      if caller {
        let start = CXStartCallAction(call: id, handle: CXHandle(type: .generic, value: name))
        controller.request(CXTransaction(action: start)) { [weak self] error in
          if let error {
            self?.current = nil
            result(FlutterError(code: "call_start", message: error.localizedDescription, details: nil))
          } else {
            let update = CXCallUpdate()
            update.localizedCallerName = name
            update.supportsHolding = false
            update.supportsGrouping = false
            update.supportsUngrouping = false
            self?.provider.reportCall(with: id, updated: update)
            result(nil)
          }
        }
      } else {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: name)
        update.localizedCallerName = name
        update.supportsHolding = false
        update.supportsGrouping = false
        update.supportsUngrouping = false
        provider.reportNewIncomingCall(with: id, update: update) { [weak self] error in
          if let error {
            self?.current = nil
            result(FlutterError(code: "call_incoming", message: error.localizedDescription, details: nil))
          } else { result(nil) }
        }
      }
      return
    }
    if phase == "connecting" && !caller && !answerRequested {
      answerRequested = true
      // In-app Accept uses the same system audio-session activation as lock-screen Accept.
      controller.request(CXTransaction(action: CXAnswerCallAction(call: id))) { _ in }
    }
    if phase == "active" && !connected {
      connected = true
      if caller { provider.reportOutgoingCall(with: id, connectedAt: Date()) }
    }
    let muted = args["muted"] as? Bool ?? false
    controller.request(CXTransaction(action: CXSetMutedCallAction(call: id, muted: muted))) { _ in }
    result(nil)
  }

  func providerDidReset(_ provider: CXProvider) {
    current = nil
    connected = false
    channel.invokeMethod("end", arguments: nil)
  }

  private func prepareAudio() throws {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth])
    RTCAudioSession.sharedInstance().useManualAudio = true
  }

  func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
    do {
      try prepareAudio()
      provider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: Date())
      action.fulfill()
    } catch { action.fail() }
  }

  func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
    answerRequested = true
    do {
      try prepareAudio()
      channel.invokeMethod("answer", arguments: nil) { result in
        if result is FlutterError { action.fail() } else { action.fulfill() }
      }
    } catch { action.fail() }
  }

  func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
    channel.invokeMethod("end", arguments: nil) { result in
      if result is FlutterError { action.fail() } else { action.fulfill() }
    }
  }

  func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
    channel.invokeMethod("mute", arguments: action.isMuted) { result in
      if result is FlutterError { action.fail() } else { action.fulfill() }
    }
  }

  func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
    RTCAudioSession.sharedInstance().audioSessionDidActivate(audioSession)
    RTCAudioSession.sharedInstance().isAudioEnabled = true
  }

  func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
    RTCAudioSession.sharedInstance().isAudioEnabled = false
    RTCAudioSession.sharedInstance().audioSessionDidDeactivate(audioSession)
  }
}
