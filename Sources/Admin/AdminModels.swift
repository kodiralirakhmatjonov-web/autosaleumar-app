import Foundation

// MARK: - Control System identity

enum ASUAdminRole: String, Codable, CaseIterable, Hashable {
    case superAdmin = "super_admin"
    case admin
    case salesManager = "sales_manager"

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .superAdmin:
            return L10n.t("Суперадминистратор", "Super administrator", language)
        case .admin:
            return L10n.t("Администратор", "Administrator", language)
        case .salesManager:
            return L10n.t("Менеджер", "Menejer", language)
        }
    }

    func shortTitle(_ language: AppLanguage) -> String {
        switch self {
        case .superAdmin:
            return "SUPER ADMIN"
        case .admin:
            return L10n.t("АДМИН", "ADMIN", language)
        case .salesManager:
            return L10n.t("МЕНЕДЖЕР", "MENEJER", language)
        }
    }
}

struct ASUAdminUser: Codable, Hashable, Identifiable {
    let id: Int
    let email: String
    let fullName: String
    let phone: String?
    let role: ASUAdminRole
}

struct ASUAdminSession: Codable, Hashable {
    let token: String
    let tokenType: String
    let expiresAt: String

    var isExpired: Bool {
        guard let expiry = Self.parseISO8601(expiresAt) else { return true }
        return expiry <= Date().addingTimeInterval(10)
    }

    private static func parseISO8601(_ value: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: value) { return date }

        let standard = ISO8601DateFormatter()
        standard.formatOptions = [.withInternetDateTime]
        return standard.date(from: value)
    }
}

struct ASUStoredAdminSession: Codable, Hashable {
    let session: ASUAdminSession
    let user: ASUAdminUser
}

// MARK: - Control System navigation

enum ASUAdminSection: String, CaseIterable, Identifiable, Hashable {
    case staff
    case cars
    case brands
    case home
    case visits
    case requests
    case ramadan

    var id: String { rawValue }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .staff: return L10n.t("Команда", "Jamoa", language)
        case .cars: return L10n.t("Автомобили", "Avtomobillar", language)
        case .brands: return L10n.t("Марки", "Markalar", language)
        case .home: return L10n.t("Главная", "Bosh sahifa", language)
        case .visits: return L10n.t("Визиты", "Tashriflar", language)
        case .requests: return L10n.t("Запросы", "So‘rovlar", language)
        case .ramadan: return "Ramadan Gift"
        }
    }

    func subtitle(_ language: AppLanguage) -> String {
        switch self {
        case .staff:
            return L10n.t("Сотрудники и роли", "Xodimlar va rollar", language)
        case .cars:
            return L10n.t("Каталог и статусы", "Katalog va statuslar", language)
        case .brands:
            return L10n.t("Обложки автомарок", "Marka muqovalari", language)
        case .home:
            return L10n.t("Рекламные видео", "Reklama videolari", language)
        case .visits:
            return L10n.t("Записи в шоурум", "Shourum tashriflari", language)
        case .requests:
            return L10n.t("Подбор автомобилей", "Avtomobil tanlovi", language)
        case .ramadan:
            return L10n.t("Подарочная программа", "Sovg‘a dasturi", language)
        }
    }

    var symbol: String {
        switch self {
        case .staff: return "person.2"
        case .cars: return "car.2"
        case .brands: return "shield.lefthalf.filled"
        case .home: return "play.rectangle.on.rectangle"
        case .visits: return "calendar"
        case .requests: return "text.page"
        case .ramadan: return "gift"
        }
    }

    func isVisible(for role: ASUAdminRole) -> Bool {
        switch role {
        case .superAdmin, .admin:
            return true
        case .salesManager:
            return self == .cars || self == .visits || self == .requests
        }
    }
}
