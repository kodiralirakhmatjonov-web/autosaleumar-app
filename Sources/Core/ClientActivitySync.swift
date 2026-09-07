import Foundation
import UserNotifications

struct ASUClientActivitySyncResult: Equatable {
    let syncedAt: Date
    let checkedCount: Int
    let changedCount: Int
    let failedCount: Int

    var isComplete: Bool { failedCount == 0 }
}

enum ASUClientActivitySync {
    static func refresh(
        activities: [ASUClientActivity] = Persistence.clientActivities(),
        phone: String = Persistence.customerProfile().phone,
        language: AppLanguage,
        notificationsEnabled: Bool
    ) async -> ASUClientActivitySyncResult {
        let eligible = Array(activities.prefix(30))
        guard !eligible.isEmpty else {
            return ASUClientActivitySyncResult(syncedAt: Date(), checkedCount: 0, changedCount: 0, failedCount: 0)
        }

        let fallbackPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        var groups: [String: (phone: String, activities: [ASUClientActivity])] = [:]
        var invalidPhoneCount = 0

        for activity in eligible {
            let rawPhone = (activity.customerPhone?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                            ? activity.customerPhone!
                            : fallbackPhone)
            let key = rawPhone.filter(\.isNumber)
            guard key.count >= 7 else {
                invalidPhoneCount += 1
                continue
            }
            var group = groups[key] ?? (phone: rawPhone, activities: [])
            group.activities.append(activity)
            groups[key] = group
        }

        let syncedAt = Date()
        var changedCount = 0
        var matchedCodes = Set<String>()
        var requestFailures = invalidPhoneCount

        for group in groups.values {
            let remoteStatuses: [ASUClientActivityStatus]
            do {
                remoteStatuses = try await ClientAPI().fetchClientActivityStatuses(activities: group.activities, phone: group.phone)
            } catch {
                requestFailures += group.activities.count
                continue
            }

            for remote in remoteStatuses {
                matchedCodes.insert(remote.code)
                guard let update = Persistence.updateActivity(
                    code: remote.code,
                    status: remote.status,
                    serverUpdatedAt: remote.updatedAt,
                    syncedAt: syncedAt
                ) else { continue }

                if update.changed {
                    changedCount += 1
                    if update.activity.kind == .showroomVisit,
                       ["completed", "cancelled"].contains(remote.status.lowercased()) {
                        ASUVisitReminder.cancel(code: update.activity.code)
                    }
                    if notificationsEnabled {
                        await ASUStatusNotifications.notifyStatusChange(activity: update.activity, language: language)
                    }
                }
            }

            requestFailures += max(0, group.activities.count - remoteStatuses.count)
        }

        return ASUClientActivitySyncResult(
            syncedAt: syncedAt,
            checkedCount: matchedCodes.count,
            changedCount: changedCount,
            failedCount: min(eligible.count, requestFailures)
        )
    }
}

enum ASUStatusNotifications {
    private static let identifierPrefix = "asu-status-"

    static func ensureAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    static func notifyStatusChange(activity: ASUClientActivity, language: AppLanguage) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus) else { return }

        let content = UNMutableNotificationContent()
        content.title = title(for: activity, language: language)
        content.body = body(for: activity, language: language)
        content.sound = .default
        content.threadIdentifier = activity.kind == .showroomVisit ? "asu-showroom-visits" : "asu-vehicle-requests"
        content.userInfo = [
            "asu_activity_code": activity.code,
            "asu_activity_kind": activity.kind.rawValue,
            "asu_deep_link": "autosaleumar://profile?activity=\(activity.code.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? activity.code)"
        ]

        let request = UNNotificationRequest(
            identifier: identifierPrefix + activity.code + "-" + (activity.status ?? "updated"),
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        )
        try? await center.add(request)
    }

    private static func title(for activity: ASUClientActivity, language: AppLanguage) -> String {
        switch activity.kind {
        case .vehicleRequest:
            return L10n.t("Статус подбора обновлён", "Tanlov holati yangilandi", language)
        case .showroomVisit:
            return L10n.t("Статус визита обновлён", "Tashrif holati yangilandi", language)
        }
    }

    private static func body(for activity: ASUClientActivity, language: AppLanguage) -> String {
        let status = ASUClientStatusPresentation.statusTitle(activity.status, kind: activity.kind, language: language)
        return "\(activity.title) · \(status)"
    }
}

enum ASUClientStatusPresentation {
    static func statusTitle(_ raw: String?, kind: ASUClientActivityKind, language: AppLanguage) -> String {
        let status = normalized(raw, kind: kind)
        switch kind {
        case .vehicleRequest:
            switch status {
            case "contacted": return L10n.t("Мы связались", "Bog‘landik", language)
            case "sourcing": return L10n.t("Ищем автомобиль", "Avtomobil qidirilmoqda", language)
            case "offered": return L10n.t("Предложение готово", "Taklif tayyor", language)
            case "completed": return L10n.t("Автомобиль найден", "Avtomobil topildi", language)
            case "cancelled": return L10n.t("Запрос закрыт", "So‘rov yopildi", language)
            default: return L10n.t("Запрос принят", "So‘rov qabul qilindi", language)
            }
        case .showroomVisit:
            switch status {
            case "confirmed": return L10n.t("Визит подтверждён", "Tashrif tasdiqlandi", language)
            case "completed": return L10n.t("Визит завершён", "Tashrif yakunlandi", language)
            case "cancelled": return L10n.t("Визит отменён", "Tashrif bekor qilindi", language)
            default: return L10n.t("Ожидает подтверждения", "Tasdiqlanishi kutilmoqda", language)
            }
        }
    }

    static func compactStatusTitle(_ raw: String?, kind: ASUClientActivityKind, language: AppLanguage) -> String {
        let status = normalized(raw, kind: kind)
        switch kind {
        case .vehicleRequest:
            switch status {
            case "contacted": return L10n.t("Связались", "Bog‘landik", language)
            case "sourcing": return L10n.t("Ищем", "Qidiruv", language)
            case "offered": return L10n.t("Предложено", "Taklif", language)
            case "completed": return L10n.t("Готово", "Tayyor", language)
            case "cancelled": return L10n.t("Закрыто", "Yopildi", language)
            default: return L10n.t("Принят", "Qabul qilindi", language)
            }
        case .showroomVisit:
            switch status {
            case "confirmed": return L10n.t("Подтверждён", "Tasdiqlandi", language)
            case "completed": return L10n.t("Завершён", "Yakunlandi", language)
            case "cancelled": return L10n.t("Отменён", "Bekor qilindi", language)
            default: return L10n.t("Ожидает", "Kutilmoqda", language)
            }
        }
    }

    static func statusCaption(_ raw: String?, kind: ASUClientActivityKind, language: AppLanguage) -> String {
        let status = normalized(raw, kind: kind)
        switch kind {
        case .vehicleRequest:
            switch status {
            case "contacted": return L10n.t("Менеджер уже взял запрос в работу и уточняет детали.", "Menejer so‘rovni ishga oldi va tafsilotlarni aniqlamoqda.", language)
            case "sourcing": return L10n.t("Команда проверяет доступные рынки и подходящие конфигурации.", "Jamoa mavjud bozorlar va mos konfiguratsiyalarni tekshirmoqda.", language)
            case "offered": return L10n.t("Подходящий вариант подготовлен. Команда свяжется с вами по выбранному каналу.", "Mos variant tayyor. Jamoa tanlangan aloqa kanali orqali bog‘lanadi.", language)
            case "completed": return L10n.t("Подбор завершён. История обращения остаётся доступной в приложении.", "Tanlov yakunlandi. Murojaat tarixi ilovada saqlanadi.", language)
            case "cancelled": return L10n.t("Работа по этому запросу завершена без активного подбора.", "Bu so‘rov bo‘yicha faol qidiruv yakunlangan.", language)
            default: return L10n.t("Запрос уже в Control System. Следующий статус появится здесь автоматически.", "So‘rov Control System’da. Keyingi holat shu yerda avtomatik paydo bo‘ladi.", language)
            }
        case .showroomVisit:
            switch status {
            case "confirmed": return L10n.t("Шоурум подтвердил выбранное время и готовится к вашему визиту.", "Shourum tanlangan vaqtni tasdiqladi va tashrifingizga tayyorlanmoqda.", language)
            case "completed": return L10n.t("Визит отмечен как завершённый в Control System.", "Tashrif Control System’da yakunlangan deb belgilandi.", language)
            case "cancelled": return L10n.t("Этот визит отменён. При необходимости можно создать новое бронирование.", "Bu tashrif bekor qilindi. Kerak bo‘lsa, yangi tashrif band qilishingiz mumkin.", language)
            default: return L10n.t("Бронирование принято. После подтверждения шоурума статус обновится здесь.", "Band qilish qabul qilindi. Shourum tasdiqlagach, holat shu yerda yangilanadi.", language)
            }
        }
    }

    static func normalized(_ raw: String?, kind: ASUClientActivityKind) -> String {
        let value = raw?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        switch kind {
        case .vehicleRequest:
            return ["new", "contacted", "sourcing", "offered", "completed", "cancelled"].contains(value) ? value : "new"
        case .showroomVisit:
            return ["new", "confirmed", "completed", "cancelled"].contains(value) ? value : "new"
        }
    }

    static func progress(_ raw: String?, kind: ASUClientActivityKind) -> Double {
        let status = normalized(raw, kind: kind)
        if status == "cancelled" { return 1 }
        switch kind {
        case .vehicleRequest:
            return ["new": 0.12, "contacted": 0.34, "sourcing": 0.58, "offered": 0.80, "completed": 1][status] ?? 0.12
        case .showroomVisit:
            return ["new": 0.18, "confirmed": 0.62, "completed": 1][status] ?? 0.18
        }
    }

    static func symbol(_ raw: String?, kind: ASUClientActivityKind) -> String {
        let status = normalized(raw, kind: kind)
        if status == "cancelled" { return "xmark" }
        switch kind {
        case .vehicleRequest:
            switch status {
            case "contacted": return "message.fill"
            case "sourcing": return "scope"
            case "offered": return "doc.text.fill"
            case "completed": return "checkmark"
            default: return "sparkles"
            }
        case .showroomVisit:
            switch status {
            case "confirmed": return "checkmark"
            case "completed": return "checkmark.seal.fill"
            default: return "calendar"
            }
        }
    }
}

enum ASUBackgroundClientStatus {
    static func refresh() async -> Bool {
        let activities = Persistence.clientActivities()
        guard !activities.isEmpty else { return true }

        let language = AppLanguage(rawValue: UserDefaults.standard.string(forKey: "ASULanguage") ?? "") ?? .ru
        let notificationKey = "ASUStatusNotificationsEnabled"
        let notificationsEnabled = UserDefaults.standard.object(forKey: notificationKey) == nil
            ? true
            : UserDefaults.standard.bool(forKey: notificationKey)

        let result = await ASUClientActivitySync.refresh(
            activities: activities,
            phone: Persistence.customerProfile().phone,
            language: language,
            notificationsEnabled: notificationsEnabled
        )
        return result.failedCount == 0 || result.checkedCount > 0
    }
}
