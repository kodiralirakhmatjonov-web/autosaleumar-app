import SwiftUI

enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case home
    case catalog
    case favorites
    case profile

    var id: String { rawValue }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .home: return L10n.t("Главная", "Asosiy", language)
        case .catalog: return L10n.t("Каталог", "Katalog", language)
        case .favorites: return L10n.t("Избранное", "Saqlangan", language)
        case .profile: return L10n.t("Профиль", "Profil", language)
        }
    }

    var symbol: String {
        switch self {
        case .home: return "house"
        case .catalog: return "square.grid.2x2"
        case .favorites: return "heart"
        case .profile: return "person.crop.circle"
        }
    }
}
