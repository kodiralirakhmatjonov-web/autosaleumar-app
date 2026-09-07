import UIKit
import UserNotifications
import BackgroundTasks

extension Notification.Name {
    static let asuNotificationRoute = Notification.Name("com.autosaleumar.app.notificationRoute")
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private let clientStatusRefreshIdentifier = "com.autosaleumar.app.client-status-refresh"

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        BGTaskScheduler.shared.register(forTaskWithIdentifier: clientStatusRefreshIdentifier, using: nil) { [weak self] task in
            guard let self, let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handleClientStatusRefresh(refreshTask)
        }
        scheduleClientStatusRefresh()
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleClientStatusRefresh()
    }

    private func scheduleClientStatusRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: clientStatusRefreshIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private func handleClientStatusRefresh(_ task: BGAppRefreshTask) {
        scheduleClientStatusRefresh()
        let operation = Task {
            let success = await ASUBackgroundClientStatus.refresh()
            guard !Task.isCancelled else { return }
            task.setTaskCompleted(success: success)
        }
        task.expirationHandler = { operation.cancel() }
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
