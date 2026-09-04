import Foundation

enum CarStatus: String, Codable, CaseIterable, Hashable {
    case inStock = "in_stock"
    case inShowroom = "in_showroom"
    case inTransit = "in_transit"
    case madeToOrder = "made_to_order"
    case reserved
    case sold
    case hidden
    case unknown

    var isAvailable: Bool {
        switch self {
        case .inStock, .inShowroom, .inTransit, .madeToOrder: return true
        default: return false
        }
    }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .inStock: return L10n.t("В наличии", "Mavjud", language)
        case .inShowroom: return L10n.t("В шоуруме", "Shourumda", language)
        case .inTransit: return L10n.t("В пути", "Yo‘lda", language)
        case .madeToOrder: return L10n.t("Под заказ", "Buyurtma", language)
        case .reserved: return L10n.t("Зарезервирован", "Band qilingan", language)
        case .sold: return L10n.t("Продан", "Sotilgan", language)
        case .hidden: return L10n.t("Скрыт", "Yashirilgan", language)
        case .unknown: return L10n.t("Статус", "Holat", language)
        }
    }
}

struct Car: Identifiable, Codable, Hashable {
    let id: Int
    let slug: String?
    let brand: String
    let model: String
    let year: Int?
    let trim: String?
    let vin: String?
    let stockNumber: String?
    let status: CarStatus
    let countryCode: String?
    let arrivalDate: String?
    let price: Int64?
    let currency: String
    let priceOnRequest: Bool
    let mileageKm: Int?
    let engineText: String?
    let fuelType: String?
    let driveType: String?
    let transmission: String?
    let seats: Int?
    let exteriorColor: String?
    let interiorColor: String?
    let shortDescriptionRu: String?
    let shortDescriptionUz: String?
    let descriptionRu: String?
    let descriptionUz: String?
    let isNew: Bool
    let isNewArrival: Bool
    let isPublic: Bool
    let isFeatured: Bool
    let coverURL: URL?
    let imageURLs: [URL]
    let updatedAt: String?

    var displayName: String { "\(brand) \(model)" }

    var primaryImageURL: URL? {
        imageURLs.first ?? coverURL
    }

    var galleryImageURLs: [URL] {
        var seen = Set<String>()
        var result: [URL] = []

        for item in ([coverURL].compactMap { $0 } + imageURLs) {
            let key = item.absoluteString
            if seen.insert(key).inserted {
                result.append(item)
            }
        }

        return result
    }

    func description(_ language: AppLanguage) -> String? {
        switch language {
        case .ru: return descriptionRu ?? shortDescriptionRu
        case .uz: return descriptionUz ?? shortDescriptionUz ?? descriptionRu ?? shortDescriptionRu
        }
    }
}

enum CatalogState: Equatable {
    case idle
    case loading
    case loaded
    case unavailable(String)
}
