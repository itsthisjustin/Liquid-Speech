import Flutter
import Speech

public class LiquidSpeechPlugin: NSObject, FlutterPlugin {
  private static var speechAnalyzerHandler: AnyObject?
  private static var speechChannel: FlutterMethodChannel?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.liquid.speech/native",
      binaryMessenger: registrar.messenger()
    )

    speechChannel = channel

    // Only initialize handler on iOS 26+
    if #available(iOS 26, *) {
      speechAnalyzerHandler = SpeechAnalyzerHandler(channel: channel)
    }

    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if #available(iOS 26, *) {
        if let handler = speechAnalyzerHandler as? SpeechAnalyzerHandler {
          handler.handleMethodCall(call, result: result)
        } else {
          result(FlutterError(code: "UNAVAILABLE", message: "SpeechAnalyzer not available on this iOS version", details: nil))
        }
      } else {
        result(FlutterError(code: "UNAVAILABLE", message: "SpeechAnalyzer requires iOS 26 or later", details: nil))
      }
    }
  }

  public static func dummyMethodToEnforceBundling(_ call: FlutterMethodCall) {
    // This method is unused, but referenced so that the build system knows this is a Swift plugin.
  }

  public func dummyMethodCall() {
    // This method is unused, but referenced so that the build system knows this is a Swift plugin.
  }
}
