import UIKit
import UserNotifications
import FirebaseMessaging
import AppMetricaPush

class AppNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo

        Messaging.messaging().appDidReceiveMessage(userInfo)
        AppMetricaPush.handleRemoteNotification(userInfo)

        PushBridge.shared.sendPushPayload(userInfo, source: "foreground")

        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        Messaging.messaging().appDidReceiveMessage(userInfo)
        AppMetricaPush.handleRemoteNotification(userInfo)

        PushBridge.shared.sendPushPayload(userInfo, source: "tap")

        completionHandler()
    }
}
