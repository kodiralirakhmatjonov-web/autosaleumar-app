import Foundation

enum AppConfig {
    static let website = URL(string: "https://autosaleumar.com")!
    static let appAPI = URL(string: "https://app-api.autosaleumar.com")!

    static let phone = "+998771155553"
    static let phoneDisplay = "+998 77 115 55 53"
    static let whatsappPhone = "998771155553"
    static let telegram = URL(string: "https://t.me/auto_sale_umar777")!
    static let instagram = URL(string: "https://instagram.com/auto_sale_umar")!
    static let yandexMaps = URL(string: "https://yandex.ru/maps/org/auto_sale_umar/98317002086?si=y1pjpr56py0hyc8ar2j2cw1t40")!

    static var carsURL: URL { appAPI.appending(path: "v1/cars") }
    static var compareAIURL: URL { website.appending(path: "api/compare-ai") }
    static var vehicleRequestsURL: URL { website.appending(path: "api/vehicle-requests") }
    static var visitsURL: URL { website.appending(path: "api/visits") }
    static var ramadanGiftURL: URL { website.appending(path: "api/ramadan-gift") }

    static func carDetailURL(slug: String) -> URL {
        appAPI.appending(path: "v1/cars").appending(path: slug)
    }

    static func carShareURL(_ car: Car) -> URL {
        guard let slug = car.slug, !slug.isEmpty else { return website.appending(path: "cars/") }
        var components = URLComponents(url: website.appending(path: "car/"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "slug", value: slug)]
        return components.url ?? website
    }
}
