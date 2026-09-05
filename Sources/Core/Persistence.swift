import Foundation

enum Persistence {
    private static let favoritesKey = "ASUFavoriteCarIDs"
    private static let compareKey = "ASUCompareCarIDs"
    private static let catalogKey = "ASUPublicCatalogCacheV2"
    private static let browserIDKey = "ASUAnonymousBrowserID"

    static func favoriteIDs() -> Set<Int> {
        Set(UserDefaults.standard.array(forKey: favoritesKey) as? [Int] ?? [])
    }

    static func saveFavoriteIDs(_ value: Set<Int>) {
        UserDefaults.standard.set(Array(value).sorted(), forKey: favoritesKey)
    }

    static func compareIDs() -> [Int] {
        Array((UserDefaults.standard.array(forKey: compareKey) as? [Int] ?? []).prefix(3))
    }

    static func saveCompareIDs(_ value: [Int]) {
        UserDefaults.standard.set(Array(value.prefix(3)), forKey: compareKey)
    }

    static func cachedCars() -> [Car] {
        guard let data = UserDefaults.standard.data(forKey: catalogKey) else { return [] }
        return (try? JSONDecoder().decode([Car].self, from: data)) ?? []
    }

    static func saveCars(_ cars: [Car]) {
        guard let data = try? JSONEncoder().encode(cars) else { return }
        UserDefaults.standard.set(data, forKey: catalogKey)
    }

    static func browserID() -> String {
        if let existing = UserDefaults.standard.string(forKey: browserIDKey), !existing.isEmpty { return existing }
        let value = "asu-ios-\(UUID().uuidString.lowercased())"
        UserDefaults.standard.set(value, forKey: browserIDKey)
        return value
    }
}
