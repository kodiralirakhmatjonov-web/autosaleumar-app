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
        case .reserved: return L10n.t("Резерв", "Rezerv", language)
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
    let exteriorSwatch: String?
    let interiorColor: String?
    let interiorSwatch: String?
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
            if seen.insert(key).inserted { result.append(item) }
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

struct CarPhoto: Identifiable, Hashable {
    let id: Int
    let url: URL
    let isCover: Bool
    let sortOrder: Int
}

struct CarVariant: Identifiable, Hashable {
    let id: Int
    let exteriorColorName: String?
    let exteriorSwatch: String
    let interiorColorName: String?
    let interiorSwatch: String
    let photos: [CarPhoto]
    let interiorPhotos: [CarPhoto]
    let detailPhotos: [CarPhoto]

    var allPhotos: [CarPhoto] {
        photos + interiorPhotos + detailPhotos
    }
}

struct CarPerformance: Hashable {
    let engineDisplacementL: Double?
    let horsepowerHp: Int?
    let torqueNm: Int?
    let acceleration0100: Double?
    let topSpeedKmh: Int?
    let fuelConsumptionL100: Double?
    let electricRangeKm: Int?

    var hasValues: Bool {
        engineDisplacementL != nil || horsepowerHp != nil || torqueNm != nil || acceleration0100 != nil || topSpeedKmh != nil || fuelConsumptionL100 != nil || electricRangeKm != nil
    }
}

struct CarDetail: Identifiable, Hashable {
    let id: Int
    let slug: String
    let brand: String
    let model: String
    let year: Int?
    let trim: String?
    let status: CarStatus
    let countryCode: String?
    let arrivalDate: String?
    let price: Int64?
    let currency: String
    let priceOnRequest: Bool
    let mileageKm: Int
    let fuelType: String?
    let driveType: String?
    let transmission: String?
    let engineText: String?
    let seats: Int?
    let exteriorColor: String?
    let interiorColor: String?
    let shortDescriptionRu: String?
    let shortDescriptionUz: String?
    let descriptionRu: String?
    let descriptionUz: String?
    let isNew: Bool
    let isNewArrival: Bool
    let isFeatured: Bool
    let coverURL: URL?
    let weeklyViews: Int
    let performance: CarPerformance
    let instagramURL: URL?
    let variants: [CarVariant]

    var displayName: String { "\(brand) \(model)" }

    var defaultVariant: CarVariant? { variants.first }

    var exteriorPhotos: [CarPhoto] {
        let photos = defaultVariant?.photos ?? []
        if !photos.isEmpty { return photos }
        if let coverURL { return [CarPhoto(id: -1, url: coverURL, isCover: true, sortOrder: 0)] }
        return []
    }

    var interiorPhotos: [CarPhoto] { defaultVariant?.interiorPhotos ?? [] }

    var allPhotos: [CarPhoto] {
        var seen = Set<String>()
        var result: [CarPhoto] = []
        for photo in variants.flatMap(\.allPhotos) + exteriorPhotos {
            if seen.insert(photo.url.absoluteString).inserted { result.append(photo) }
        }
        return result
    }

    func description(_ language: AppLanguage) -> String? {
        switch language {
        case .ru: return descriptionRu ?? shortDescriptionRu
        case .uz: return descriptionUz ?? shortDescriptionUz ?? descriptionRu ?? shortDescriptionRu
        }
    }

    func shortDescription(_ language: AppLanguage) -> String? {
        switch language {
        case .ru: return shortDescriptionRu
        case .uz: return shortDescriptionUz ?? shortDescriptionRu
        }
    }
}

enum CatalogState: Equatable {
    case idle
    case loading
    case loaded
    case unavailable(String)
}
