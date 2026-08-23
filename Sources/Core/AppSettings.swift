import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable, Hashable {
    case ru
    case uz

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ru: return "Русский"
        case .uz: return "O‘zbekcha"
        }
    }
}

enum AppTheme: String, CaseIterable, Identifiable, Hashable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "Система"
        case .light: return "Светлая"
        case .dark: return "Тёмная"
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    private enum Keys {
        static let language = "ASULanguage"
        static let theme = "ASUTheme"
    }

    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Keys.language) }
    }

    @Published var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: Keys.theme) }
    }

    init() {
        let storedLanguage = UserDefaults.standard.string(forKey: Keys.language)
        let storedTheme = UserDefaults.standard.string(forKey: Keys.theme)
        language = AppLanguage(rawValue: storedLanguage ?? "") ?? .ru
        theme = AppTheme(rawValue: storedTheme ?? "") ?? .system
    }

    var preferredColorScheme: ColorScheme? {
        switch theme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
