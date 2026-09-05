import UIKit
import UserNotifications

extension Notification.Name {
    static let asuNotificationRoute = Notification.Name("com.autosaleumar.app.notificationRoute")
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        ASUNotificationBridge.store(response.notification.request.content.userInfo)
        NotificationCenter.default.post(
            name: .asuNotificationRoute,
            object: nil,
            userInfo: response.notification.request.content.userInfo
        )
        completionHandler()
    }
}
