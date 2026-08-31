import Foundation
import Combine

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var cars: [Car] = []
    @Published private(set) var catalogState: CatalogState = .idle
    @Published private(set) var favoriteIDs: Set<Int> = Persistence.favoriteIDs()
    @Published private(set) var clientRequests: [ClientRequest] = Persistence.requests()
    @Published var compareIDs: [Int] = []

    private let api = APIClient()
    private var didLoad = false

    var featuredCar: Car? { cars.first(where: { $0.isFeatured }) ?? cars.first(where: { $0.status.isAvailable }) ?? cars.first }
    var favorites: [Car] { cars.filter { favoriteIDs.contains($0.id) } }

    func loadIfNeeded(force: Bool = false) async {
        if didLoad && !force { return }
        didLoad = true
        catalogState = .loading
        do {
            cars = try await api.fetchPublicCars()
            catalogState = .loaded
        } catch {
            cars = []
            catalogState = .unavailable(error.localizedDescription)
        }
    }

    func toggleFavorite(_ car: Car) {
        if favoriteIDs.contains(car.id) { favoriteIDs.remove(car.id) } else { favoriteIDs.insert(car.id) }
        Persistence.saveFavoriteIDs(favoriteIDs)
    }
    func isFavorite(_ car: Car) -> Bool { favoriteIDs.contains(car.id) }

    func toggleCompare(_ car: Car) {
        if let i = compareIDs.firstIndex(of: car.id) { compareIDs.remove(at: i); return }
        if compareIDs.count == 2 { compareIDs.removeFirst() }
        compareIDs.append(car.id)
    }
    func isCompared(_ car: Car) -> Bool { compareIDs.contains(car.id) }
    var compareCars: [Car] { compareIDs.compactMap { id in cars.first { $0.id == id } } }

    func recordRequest(kind: ClientRequest.Kind, title: String, detail: String) {
        clientRequests.insert(ClientRequest(id: UUID(), kind: kind, title: title, detail: detail, createdAt: Date()), at: 0)
        if clientRequests.count > 20 { clientRequests = Array(clientRequests.prefix(20)) }
        Persistence.saveRequests(clientRequests)
    }
}
