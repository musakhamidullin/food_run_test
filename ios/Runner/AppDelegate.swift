import UIKit
import Flutter
import Firebase
import UserNotifications
import ActivityKit
import AppMetricaCrashes
import YandexMapsMobile

@main
@objc class AppDelegate: FlutterAppDelegate {

    let notificationDelegate = AppNotificationDelegate()

    private var liveActivityChannelHandler: LiveActivityChannelHandler?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()

        UNUserNotificationCenter.current().delegate = notificationDelegate
        application.registerForRemoteNotifications()

        GeneratedPluginRegistrant.register(with: self)

        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: "push_channel",
                binaryMessenger: controller.binaryMessenger
            )
            PushBridge.shared.setChannel(channel)
        }

        YMKMapKit.setApiKey("3d7a1e4f-8b2c-4a9d-b5f1-2e8c7d3a9b4f")

        guard let controller = window?.rootViewController as? FlutterViewController else {
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }

        liveActivityChannelHandler = LiveActivityChannelHandler(
            binaryMessenger: controller.binaryMessenger
        )

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
