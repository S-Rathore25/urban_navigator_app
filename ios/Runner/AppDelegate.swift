import Flutter
import UIKit
import GoogleMaps // Add this import for Google Maps Services

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Provide your Google Maps API Key for iOS here
    GMSServices.provideAPIKey("AIzaSyB6DL_7VrYgrWoiDNI-SJcEWRQ4ERP66fhQ")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
