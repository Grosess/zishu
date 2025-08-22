import Flutter
import UIKit
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    let controller = window?.rootViewController as! FlutterViewController
    let ocrChannel = FlutterMethodChannel(name: "com.zishu.ocr", binaryMessenger: controller.binaryMessenger)
    
    ocrChannel.setMethodCallHandler { [weak self] (call, result) in
      if call.method == "performOCR" {
        guard let args = call.arguments as? [String: Any],
              let imageData = args["imageData"] as? FlutterStandardTypedData else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Image data required", details: nil))
          return
        }
        
        guard let image = UIImage(data: imageData.data) else {
          result(FlutterError(code: "INVALID_IMAGE", message: "Could not decode image", details: nil))
          return
        }
        
        if #available(iOS 13.0, *) {
          OCRService.shared.performOCR(on: image) { ocrResult in
            DispatchQueue.main.async {
              switch ocrResult {
              case .success(let data):
                result(data)
              case .failure(let error):
                result(FlutterError(code: "OCR_ERROR", message: error.localizedDescription, details: nil))
              }
            }
          }
        } else {
          result(FlutterError(code: "VERSION_ERROR", message: "OCR requires iOS 13.0 or later", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
