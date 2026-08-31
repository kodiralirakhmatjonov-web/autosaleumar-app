import Foundation

enum AppConfig {
    static let origin = URL(string: "https://autosaleumar.com")!
    static let phone = "+998771155553"
    static let phoneDisplay = "+998 77 115 55 53"
    static let whatsappPhone = "998771155553"
    static let telegram = URL(string: "https://t.me/auto_sale_umar777")!
    static let instagram = URL(string: "https://instagram.com/auto_sale_umar")!
    static let website = URL(string: "https://autosaleumar.com")!
    static let yandexMaps = URL(string: "https://yandex.com/maps/?text=Auto%20Sale%20Umar%20Tashkent")!

    // The native client never renders website HTML. These are JSON API candidates only.
    // The first live public route wins; protected/admin routes are intentionally not used.
    static let publicCatalogPaths = [
        "/api/public/cars",
        "/api/catalog/cars",
        "/api/cars/public",
        "/api/cars?public=1"
    ]

    static func url(_ path: String) -> URL {
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            return URL(string: path) ?? origin
        }
        return URL(string: path, relativeTo: origin)!.absoluteURL
    }

    static func carShareURL(_ car: Car) -> URL {
        if let slug = car.slug, !slug.isEmpty {
            return url("/car/?slug=\(slug.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? slug)")
        }
        return url("/cars/")
    }
}
