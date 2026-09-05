import Foundation
import UserNotifications

enum ASUNotificationBridge {
    private static let pendingActivityCodeKey = "ASUPendingNotificationActivityCodeV1"
    private static let pendingRouteURLKey = "ASUPendingNotificationRouteURLV1"

    static func store(_ userInfo: [AnyHashable: Any]) {
        if let rawURL = userInfo["asu_deep_link"] as? String,
           let url = URL(string: rawURL),
           AppRouter.route(from: url) != nil {
            UserDefaults.standard.set(url.absoluteString, forKey: pendingRouteURLKey)
        }

        if let code = userInfo["asu_activity_code"] as? String {
            let cleaned = code.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleaned.isEmpty { UserDefaults.standard.set(cleaned, forKey: pendingActivityCodeKey) }
        }
    }

    static func consumePendingRouteURL() -> URL? {
        guard let raw = UserDefaults.standard.string(forKey: pendingRouteURLKey) else { return nil }
        UserDefaults.standard.removeObject(forKey: pendingRouteURLKey)
        return URL(string: raw)
    }

    static func consumePendingActivityCode() -> String? {
        guard let code = UserDefaults.standard.string(forKey: pendingActivityCodeKey), !code.isEmpty else { return nil }
        UserDefaults.standard.removeObject(forKey: pendingActivityCodeKey)
        return code
    }
}

enum ASUVisitReminder {
    private static let identifierPrefix = "asu-visit-"
    private static let tashkentTimeZone = TimeZone(identifier: "Asia/Tashkent") ?? .current

    static func schedule(for receipt: VisitReceipt, language: AppLanguage) async {
        guard let visitDate = makeVisitDate(receipt) else { return }
        let reminderDate = visitDate.addingTimeInterval(-2 * 60 * 60)
        guard reminderDate.timeIntervalSinceNow > 60 else { return }

        let center = UNUserNotificationCenter.current()
        let granted: Bool
        do {
            granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return
        }
        guard granted else { return }

        let content = UNMutableNotificationContent()
        content.title = L10n.t("Визит в Auto Sale Umar", "Auto Sale Umar tashrifi", language)
        content.body = L10n.t(
            "Через 2 часа у вас забронирован визит в шоурум. Код: \(receipt.code)",
            "2 soatdan keyin shourumga tashrifingiz bor. Kod: \(receipt.code)",
            language
        )
        content.sound = .default
        content.threadIdentifier = "asu-showroom-visits"
        var route = URLComponents()
        route.scheme = "autosaleumar"
        route.host = "profile"
        route.queryItems = [URLQueryItem(name: "activity", value: receipt.code)]
        content.userInfo = [
            "asu_activity_code": receipt.code,
            "asu_activity_kind": "visit",
            "asu_deep_link": route.url?.absoluteString ?? "autosaleumar://profile"
        ]

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tashkentTimeZone
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        components.timeZone = tashkentTimeZone

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifierPrefix + receipt.code, content: content, trigger: trigger)
        try? await center.add(request)
    }

    static func cancel(code: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifierPrefix + code])
    }

    static func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let identifiers = requests.map(\.identifier).filter { $0.hasPrefix(identifierPrefix) }
            guard !identifiers.isEmpty else { return }
            center.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }

    static func rescheduleSavedVisits(language: AppLanguage) async {
        let futureVisits = Persistence.clientActivities().filter {
            $0.kind == .showroomVisit && $0.scheduledDate != nil && $0.timeSlot != nil
        }
        for activity in futureVisits {
            guard let date = activity.scheduledDate, let slot = activity.timeSlot else { continue }
            let receipt = VisitReceipt(
                code: activity.code,
                visitDate: date,
                timeSlot: slot,
                brand: nil,
                carLabel: activity.title
            )
            await schedule(for: receipt, language: language)
        }
    }

    private static func makeVisitDate(_ receipt: VisitReceipt) -> Date? {
        let start = receipt.timeSlot
            .components(separatedBy: "–")
            .first?
            .components(separatedBy: "-")
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "10:00"

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = tashkentTimeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: "\(receipt.visitDate) \(start)")
    }
}
