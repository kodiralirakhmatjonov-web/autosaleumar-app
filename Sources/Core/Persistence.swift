import Foundation

enum Persistence {
    private static let favoritesKey = "ASUFavoriteCarIDs"
    private static let catalogKey = "ASUPublicCatalogCacheV2"

    static func favoriteIDs() -> Set<Int> {
        Set(UserDefaults.standard.array(forKey: favoritesKey) as? [Int] ?? [])
    }

    static func saveFavoriteIDs(_ value: Set<Int>) {
        UserDefaults.standard.set(Array(value).sorted(), forKey: favoritesKey)
    }

    static func cachedCars() -> [Car] {
        guard let data = UserDefaults.standard.data(forKey: catalogKey) else { return [] }
        return (try? JSONDecoder().decode([Car].self, from: data)) ?? []
    }

    static func saveCars(_ cars: [Car]) {
        guard let data = try? JSONEncoder().encode(cars) else { return }
        UserDefaults.standard.set(data, forKey: catalogKey)
    }
}
