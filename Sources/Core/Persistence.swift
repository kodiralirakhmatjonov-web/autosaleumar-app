import Foundation

enum Persistence {
    private static let favoritesKey = "ASUFavoriteCarIDs"
    private static let requestsKey = "ASUClientRequests"

    static func favoriteIDs() -> Set<Int> {
        Set(UserDefaults.standard.array(forKey: favoritesKey) as? [Int] ?? [])
    }
    static func saveFavoriteIDs(_ value: Set<Int>) { UserDefaults.standard.set(Array(value).sorted(), forKey: favoritesKey) }

    static func requests() -> [ClientRequest] {
        guard let data = UserDefaults.standard.data(forKey: requestsKey) else { return [] }
        return (try? JSONDecoder().decode([ClientRequest].self, from: data)) ?? []
    }
    static func saveRequests(_ value: [ClientRequest]) {
        if let data = try? JSONEncoder().encode(value) { UserDefaults.standard.set(data, forKey: requestsKey) }
    }
}
