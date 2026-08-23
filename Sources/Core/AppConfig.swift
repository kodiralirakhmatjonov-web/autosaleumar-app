import Foundation

enum AppConfig {
    static let siteOrigin = URL(string: "https://autosaleumar.com")!
    static let allowedHosts: Set<String> = ["autosaleumar.com", "www.autosaleumar.com"]

    static func siteURL(path: String, language: AppLanguage, theme: AppTheme) -> URL {
        let normalizedPath = path.hasPrefix("/") ? path : "/\(path)"
        let absolute = siteOrigin.absoluteString + normalizedPath
        var components = URLComponents(string: absolute) ?? URLComponents(url: siteOrigin, resolvingAgainstBaseURL: false)!
        var items = components.queryItems ?? []
        items.removeAll { ["asu_app", "asu_lang", "asu_theme"].contains($0.name) }
        items.append(URLQueryItem(name: "asu_app", value: "1"))
        items.append(URLQueryItem(name: "asu_lang", value: language.rawValue))
        items.append(URLQueryItem(name: "asu_theme", value: theme.rawValue))
        components.queryItems = items
        return components.url ?? siteOrigin
    }
}
