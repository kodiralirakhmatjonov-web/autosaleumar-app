import Foundation

enum AppConfig {
    static let website = URL(string: "https://autosaleumar.com")!
    static let appAPI = URL(string: "https://app-api.autosaleumar.com")!

    static let phone = "+998771155553"
    static let phoneDisplay = "+998 77 115 55 53"
    static let whatsappPhone = "998771155553"
    static let telegram = URL(string: "https://t.me/auto_sale_umar777")!
    static let instagram = URL(string: "https://instagram.com/auto_sale_umar")!
    static let yandexMaps = URL(string: "https://yandex.com/maps/?text=Auto%20Sale%20Umar%20Tashkent")!

    static var carsURL: URL { appAPI.appending(path: "v1/cars") }

    static func carShareURL(_ car: Car) -> URL {
        guard let slug = car.slug, !slug.isEmpty else {
            return website.appending(path: "cars/")
        }
        var components = URLComponents(url: website.appending(path: "car/"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "slug", value: slug)]
        return components.url ?? website
    }
}
