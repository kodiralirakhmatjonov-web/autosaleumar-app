import Foundation
import Combine

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var cars: [Car]
    @Published private(set) var catalogState: CatalogState
    @Published private(set) var favoriteIDs: Set<Int> = Persistence.favoriteIDs()

    private let api = APIClient()
    private var didLoad = false

    init() {
        let cached = Persistence.cachedCars()
        cars = cached
        catalogState = cached.isEmpty ? .idle : .loaded
    }

    var featuredCar: Car? {
        cars.first(where: { $0.isFeatured })
            ?? cars.first(where: { $0.status == .inShowroom })
            ?? cars.first(where: { $0.status == .inStock })
            ?? cars.first
    }

    var favorites: [Car] { cars.filter { favoriteIDs.contains($0.id) } }

    func loadIfNeeded(force: Bool = false) async {
        if didLoad && !force { return }
        didLoad = true
        if cars.isEmpty { catalogState = .loading }

        do {
            let fresh = try await api.fetchPublicCars()
            cars = fresh
            Persistence.saveCars(fresh)
            catalogState = .loaded
        } catch {
            catalogState = .unavailable(error.localizedDescription)
        }
    }

    func toggleFavorite(_ car: Car) {
        if favoriteIDs.contains(car.id) { favoriteIDs.remove(car.id) }
        else { favoriteIDs.insert(car.id) }
        Persistence.saveFavoriteIDs(favoriteIDs)
    }

    func isFavorite(_ car: Car) -> Bool { favoriteIDs.contains(car.id) }
}
