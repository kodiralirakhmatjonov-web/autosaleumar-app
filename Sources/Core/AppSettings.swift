import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable, Hashable {
    case ru, uz
    var id: String { rawValue }
    var title: String { self == .ru ? "Русский" : "O‘zbekcha" }
}

enum AppTheme: String, CaseIterable, Identifiable, Hashable {
    case system, light, dark
    var id: String { rawValue }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .system: return L10n.t("Система", "Tizim", language)
        case .light: return L10n.t("Светлая", "Yorug‘", language)
        case .dark: return L10n.t("Тёмная", "Qorong‘i", language)
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    private enum Keys {
        static let language = "ASULanguage"
        static let theme = "ASUTheme"
        static let visitReminders = "ASUVisitRemindersEnabled"
    }

    @Published var language: AppLanguage { didSet { UserDefaults.standard.set(language.rawValue, forKey: Keys.language) } }
    @Published var theme: AppTheme { didSet { UserDefaults.standard.set(theme.rawValue, forKey: Keys.theme) } }
    @Published var visitRemindersEnabled: Bool {
        didSet {
            UserDefaults.standard.set(visitRemindersEnabled, forKey: Keys.visitReminders)
            if visitRemindersEnabled {
                let language = language
                Task { await ASUVisitReminder.rescheduleSavedVisits(language: language) }
            } else {
                ASUVisitReminder.cancelAll()
            }
        }
    }

    init() {
        language = AppLanguage(rawValue: UserDefaults.standard.string(forKey: Keys.language) ?? "") ?? .ru
        theme = AppTheme(rawValue: UserDefaults.standard.string(forKey: Keys.theme) ?? "") ?? .system
        if UserDefaults.standard.object(forKey: Keys.visitReminders) == nil {
            visitRemindersEnabled = true
        } else {
            visitRemindersEnabled = UserDefaults.standard.bool(forKey: Keys.visitReminders)
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch theme { case .system: return nil; case .light: return .light; case .dark: return .dark }
    }
}
