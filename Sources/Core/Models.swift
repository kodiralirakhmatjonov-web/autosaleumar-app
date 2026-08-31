import Foundation

enum CarStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case inStock = "in_stock"
    case inShowroom = "in_showroom"
    case inTransit = "in_transit"
    case madeToOrder = "made_to_order"
    case reserved
    case sold
    case hidden
    case unknown
    var id: String { rawValue }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .inStock: return L10n.t("В наличии", "Mavjud", language)
        case .inShowroom: return L10n.t("В шоуруме", "Shourumda", language)
        case .inTransit: return L10n.t("В пути", "Yo‘lda", language)
        case .madeToOrder: return L10n.t("Под заказ", "Buyurtma", language)
        case .reserved: return L10n.t("Резерв", "Band qilingan", language)
        case .sold: return L10n.t("Продано", "Sotilgan", language)
        case .hidden: return L10n.t("Скрыто", "Yashirin", language)
        case .unknown: return L10n.t("Статус", "Holat", language)
        }
    }

    var isAvailable: Bool { self == .inStock || self == .inShowroom }
}

struct Car: Identifiable, Codable, Hashable {
    var id: Int
    var slug: String?
    var brand: String
    var model: String
    var year: Int?
    var trim: String?
    var vin: String?
    var stockNumber: String?
    var status: CarStatus
    var countryCode: String?
    var arrivalDate: String?
    var price: Int64?
    var currency: String
    var priceOnRequest: Bool
    var mileageKm: Int?
    var bodyType: String?
    var fuelType: String?
    var driveType: String?
    var transmission: String?
    var engineText: String?
    var seats: Int?
    var exteriorColor: String?
    var interiorColor: String?
    var shortDescriptionRu: String?
    var shortDescriptionUz: String?
    var descriptionRu: String?
    var descriptionUz: String?
    var isNew: Bool
    var isNewArrival: Bool
    var isPublic: Bool
    var isFeatured: Bool
    var coverURL: URL?
    var imageURLs: [URL]
    var updatedAt: String?

    var displayName: String { "\(brand) \(model)" }
    func localizedShort(_ language: AppLanguage) -> String? { language == .ru ? shortDescriptionRu : shortDescriptionUz }
    func localizedDescription(_ language: AppLanguage) -> String? { language == .ru ? descriptionRu : descriptionUz }
}

enum CatalogState: Equatable { case idle, loading, loaded, unavailable(String) }

enum ContactPreference: String, CaseIterable, Identifiable, Codable {
    case whatsapp = "WhatsApp", telegram = "Telegram", call = "Call"
    var id: String { rawValue }
}

struct ClientRequest: Identifiable, Codable, Hashable {
    enum Kind: String, Codable { case vehicle, visit }
    var id: UUID
    var kind: Kind
    var title: String
    var detail: String
    var createdAt: Date
}
