import Foundation
import Combine

enum ASURoute: Equatable {
    case home
    case catalog(brand: String?, status: CarStatus?)
    case favorites
    case profile(activityCode: String?)
    case car(slug: String)
    case compare
    case requestCar
    case visit
    case location
    case trust
    case ramadanGift
}

@MainActor
final class AppRouter: ObservableObject {
    @Published private(set) var route: ASURoute?
    @Published private(set) var activityFocusCode: String?

    func open(_ route: ASURoute) {
        self.route = route
    }

    func consumeRoute() {
        route = nil
    }

    func focusActivity(_ code: String?) {
        activityFocusCode = code?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    func clearActivityFocus() {
        activityFocusCode = nil
    }

    @discardableResult
    func handle(url: URL) -> Bool {
        guard let parsed = Self.route(from: url) else { return false }
        open(parsed)
        return true
    }

    nonisolated static func route(from url: URL) -> ASURoute? {
        if url.scheme?.lowercased() == "autosaleumar" {
            return routeFromCustomURL(url)
        }

        guard let host = url.host?.lowercased(), host == "autosaleumar.com" || host == "www.autosaleumar.com" else {
            return nil
        }
        return routeFromWebsiteURL(url)
    }

    nonisolated private static func routeFromCustomURL(_ url: URL) -> ASURoute? {
        let host = (url.host ?? "").lowercased()
        let pathParts = url.pathComponents.filter { $0 != "/" }
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

        switch host {
        case "home": return .home
        case "catalog", "cars":
            return .catalog(brand: query.value(for: "brand"), status: status(from: query.value(for: "status")))
        case "favorites", "saved": return .favorites
        case "profile": return .profile(activityCode: query.value(for: "activity"))
        case "car":
            if let slug = pathParts.first?.removingPercentEncoding?.nilIfEmpty ?? query.value(for: "slug")?.nilIfEmpty {
                return .car(slug: slug)
            }
            return .catalog(brand: nil, status: nil)
        case "compare": return .compare
        case "request", "request-car": return .requestCar
        case "visit", "booking": return .visit
        case "location": return .location
        case "trust": return .trust
        case "ramadan-gift", "gift": return .ramadanGift
        default: return nil
        }
    }

    nonisolated private static func routeFromWebsiteURL(_ url: URL) -> ASURoute? {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let query = components?.queryItems ?? []
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()

        switch path {
        case "", "home": return .home
        case "cars":
            return .catalog(brand: query.value(for: "brand"), status: status(from: query.value(for: "status")))
        case "car":
            guard let slug = query.value(for: "slug")?.nilIfEmpty else { return .catalog(brand: nil, status: nil) }
            return .car(slug: slug)
        case "compare": return .compare
        case "request-car": return .requestCar
        case "booking": return .visit
        case "location": return .location
        case "trust": return .trust
        case "ramadan-gift": return .ramadanGift
        default: return nil
        }
    }

    nonisolated private static func status(from raw: String?) -> CarStatus? {
        guard let normalized = raw?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !normalized.isEmpty else { return nil }
        if let status = CarStatus(rawValue: normalized) { return status }

        switch normalized {
        case "stock", "available": return .inStock
        case "showroom": return .inShowroom
        case "transit", "on-the-way": return .inTransit
        case "order", "made-to-order": return .madeToOrder
        default: return nil
        }
    }
}

private extension Array where Element == URLQueryItem {
    func value(for name: String) -> String? {
        first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame })?.value
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
