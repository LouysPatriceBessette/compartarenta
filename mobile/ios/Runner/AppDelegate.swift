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
    let messenger = engineBridge.applicationRegistrar.messenger()
    let channel = FlutterMethodChannel(
      name: "com.compartarenta/device_binding",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "collectSignals":
        result(self.collectDeviceBindingSignals())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func collectDeviceBindingSignals() -> [String: String] {
    var signals: [String: String] = [:]
    let device = UIDevice.current
    signals["model"] = device.model
    signals["system_name"] = device.systemName
    signals["system_version"] = device.systemVersion
    if let idfv = device.identifierForVendor?.uuidString {
      signals["identifier_for_vendor"] = idfv
    }
    let screen = UIScreen.main
    signals["screen_bounds"] = "\(screen.bounds.width)x\(screen.bounds.height)"
    signals["screen_scale"] = "\(screen.scale)"
    signals["native_bounds"] = "\(screen.nativeBounds.width)x\(screen.nativeBounds.height)"
    signals["locale"] = Locale.current.identifier
    signals["timezone"] = TimeZone.current.identifier
    signals["processor_count"] = "\(ProcessInfo.processInfo.processorCount)"
    return signals
  }
}
