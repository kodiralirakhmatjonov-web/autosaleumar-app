import Foundation

enum Persistence {
    private static let favoritesKey = "ASUFavoriteCarIDs"
    private static let compareKey = "ASUCompareCarIDs"
    private static let legacyCatalogKey = "ASUPublicCatalogCacheV2"
    private static let catalogUpdatedAtKey = "ASUPublicCatalogUpdatedAtV1"
    private static let browserIDKey = "ASUAnonymousBrowserID"
    private static let customerProfileKey = "ASUCustomerProfileV1"
    private static let clientActivitiesKey = "ASUClientActivitiesV1"
    private static let catalogFileName = "asu-public-catalog-v3.json"

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

    static func customerProfile() -> ASUCustomerProfile {
        guard let data = UserDefaults.standard.data(forKey: customerProfileKey),
              let profile = try? JSONDecoder().decode(ASUCustomerProfile.self, from: data) else {
            return .empty
        }
        return profile
    }

    static func saveCustomerProfile(_ profile: ASUCustomerProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        UserDefaults.standard.set(data, forKey: customerProfileKey)
    }

    static func clientActivities() -> [ASUClientActivity] {
        guard let data = UserDefaults.standard.data(forKey: clientActivitiesKey),
              let items = try? JSONDecoder().decode([ASUClientActivity].self, from: data) else {
            return []
        }
        return items.sorted { $0.createdAt > $1.createdAt }
    }

    static func recordVehicleRequest(_ receipt: VehicleRequestReceipt) {
        let item = ASUClientActivity(
            kind: .vehicleRequest,
            code: receipt.code,
            title: "\(receipt.brand) \(receipt.model)",
            subtitle: receipt.status
        )
        appendActivity(item)
    }

    static func recordVisit(_ receipt: VisitReceipt) {
        let label = receipt.carLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
        let brand = receipt.brand?.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = (label?.isEmpty == false ? label : nil)
            ?? (brand?.isEmpty == false ? brand : nil)
            ?? "Auto Sale Umar Showroom"

        let item = ASUClientActivity(
            kind: .showroomVisit,
            code: receipt.code,
            title: title,
            subtitle: receipt.timeSlot,
            scheduledDate: receipt.visitDate,
            timeSlot: receipt.timeSlot
        )
        appendActivity(item)
    }

    static func removeActivity(id: UUID) {
        let items = clientActivities().filter { $0.id != id }
        saveActivities(items)
    }

    static func clearActivities() {
        UserDefaults.standard.removeObject(forKey: clientActivitiesKey)
    }

    private static func appendActivity(_ item: ASUClientActivity) {
        var items = clientActivities()
        items.removeAll { $0.kind == item.kind && $0.code == item.code }
        items.insert(item, at: 0)
        saveActivities(Array(items.prefix(30)))
    }

    private static func saveActivities(_ items: [ASUClientActivity]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: clientActivitiesKey)
    }

    static func cachedCars() -> [Car] {
        if let url = catalogCacheURL,
           let data = try? Data(contentsOf: url),
           let cars = try? JSONDecoder().decode([Car].self, from: data) {
            return cars
        }

        guard let legacy = UserDefaults.standard.data(forKey: legacyCatalogKey),
              let cars = try? JSONDecoder().decode([Car].self, from: legacy) else {
            return []
        }

        saveCars(cars, updateTimestamp: false)
        UserDefaults.standard.removeObject(forKey: legacyCatalogKey)
        return cars
    }

    static func saveCars(_ cars: [Car], updateTimestamp: Bool = true) {
        guard let data = try? JSONEncoder().encode(cars) else { return }

        if let url = catalogCacheURL {
            try? data.write(to: url, options: .atomic)
        }

        if updateTimestamp {
            let now = Date()
            UserDefaults.standard.set(now.timeIntervalSince1970, forKey: catalogUpdatedAtKey)
        }
    }

    static func catalogUpdatedAt() -> Date? {
        let value = UserDefaults.standard.double(forKey: catalogUpdatedAtKey)
        guard value > 0 else { return nil }
        return Date(timeIntervalSince1970: value)
    }

    static func browserID() -> String {
        if let existing = UserDefaults.standard.string(forKey: browserIDKey), !existing.isEmpty { return existing }
        let value = "asu-ios-\(UUID().uuidString.lowercased())"
        UserDefaults.standard.set(value, forKey: browserIDKey)
        return value
    }

    private static var catalogCacheURL: URL? {
        guard let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        return directory.appendingPathComponent(catalogFileName, isDirectory: false)
    }
}
