import Foundation
import Combine

struct CatalogIntent: Identifiable, Equatable {
    let id = UUID()
    let brand: String?
    let status: CarStatus?
}

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var cars: [Car]
    @Published private(set) var catalogState: CatalogState
    @Published private(set) var favoriteIDs: Set<Int> = Persistence.favoriteIDs()
    @Published private(set) var compareIDs: [Int] = Persistence.compareIDs()
    @Published var catalogIntent: CatalogIntent?

    private let api = APIClient()
    private var didLoad = false
    private var detailCache: [String: CarDetail] = [:]

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
    var compareCars: [Car] { compareIDs.compactMap { id in cars.first(where: { $0.id == id }) } }
    var showroomCars: [Car] { cars.filter { $0.status == .inShowroom } }
    var stockCars: [Car] { cars.filter { $0.status == .inStock || $0.status == .inShowroom } }
    var transitCars: [Car] { cars.filter { $0.status == .inTransit } }
    var soldCars: [Car] { cars.filter { $0.status == .sold } }

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

    func detail(for car: Car, force: Bool = false) async throws -> CarDetail {
        guard let slug = car.slug, !slug.isEmpty else { throw APIClient.APIError.notFound }
        if !force, let cached = detailCache[slug] { return cached }
        let detail = try await api.fetchCarDetail(slug: slug)
        detailCache[slug] = detail
        return detail
    }

    func requestCatalog(brand: String? = nil, status: CarStatus? = nil) {
        catalogIntent = CatalogIntent(brand: brand, status: status)
    }

    func clearCatalogIntent() { catalogIntent = nil }

    func toggleFavorite(_ car: Car) {
        if favoriteIDs.contains(car.id) { favoriteIDs.remove(car.id) }
        else { favoriteIDs.insert(car.id) }
        Persistence.saveFavoriteIDs(favoriteIDs)
    }

    func isFavorite(_ car: Car) -> Bool { favoriteIDs.contains(car.id) }

    func toggleCompare(_ car: Car) {
        if let index = compareIDs.firstIndex(of: car.id) {
            compareIDs.remove(at: index)
        } else {
            if compareIDs.count >= 3 { compareIDs.removeFirst() }
            compareIDs.append(car.id)
        }
        Persistence.saveCompareIDs(compareIDs)
    }

    func isCompared(_ car: Car) -> Bool { compareIDs.contains(car.id) }
}
