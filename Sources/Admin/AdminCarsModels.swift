import Foundation

struct ASUAdminCarPhoto: Decodable, Hashable, Identifiable {
    let id: Int
    let url: String
    let isCover: Bool
    let sortOrder: Int
}

struct ASUAdminCarVariant: Decodable, Hashable, Identifiable {
    let id: Int
    let exteriorColorName: String?
    let exteriorSwatch: String
    let interiorColorName: String?
    let interiorSwatch: String
    let vin: String?
    let stockNumber: String?
    let quantity: Int
    let exteriorPhotos: [ASUAdminCarPhoto]
}

struct ASUAdminCarRecord: Decodable, Hashable, Identifiable {
    let id: Int
    let slug: String
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
    let mileageKm: Int
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
    let createdBy: Int?
    let updatedBy: Int?
    let createdAt: String
    let updatedAt: String
    let coverUrl: String?
    let variants: [ASUAdminCarVariant]

    var displayName: String { "\(brand) \(model)" }

    var allExteriorPhotoValues: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for value in variants.flatMap(\.exteriorPhotos).map(\.url) + [coverUrl].compactMap({ $0 }) {
            if seen.insert(value).inserted { result.append(value) }
        }
        return result
    }

    func applying(_ patch: ASUAdminCarPatchResult) -> ASUAdminCarRecord {
        ASUAdminCarRecord(
            id: id,
            slug: patch.slug,
            brand: patch.brand,
            model: patch.model,
            year: patch.year,
            trim: patch.trim,
            vin: patch.vin,
            stockNumber: patch.stockNumber,
            status: patch.status,
            countryCode: patch.countryCode,
            arrivalDate: patch.arrivalDate,
            price: patch.price,
            currency: patch.currency,
            priceOnRequest: patch.priceOnRequest,
            mileageKm: patch.mileageKm,
            engineText: patch.engineText,
            fuelType: patch.fuelType,
            driveType: patch.driveType,
            transmission: patch.transmission,
            seats: patch.seats,
            exteriorColor: patch.exteriorColor,
            interiorColor: patch.interiorColor,
            shortDescriptionRu: patch.shortDescriptionRu,
            shortDescriptionUz: patch.shortDescriptionUz,
            descriptionRu: patch.descriptionRu,
            descriptionUz: patch.descriptionUz,
            isNew: patch.isNew,
            isNewArrival: patch.isNewArrival,
            isPublic: patch.isPublic,
            isFeatured: patch.isFeatured,
            createdBy: patch.createdBy,
            updatedBy: patch.updatedBy,
            createdAt: patch.createdAt,
            updatedAt: patch.updatedAt,
            coverUrl: patch.coverUrl,
            variants: variants
        )
    }
}

struct ASUAdminCarPatchResult: Decodable, Hashable {
    let id: Int
    let slug: String
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
    let mileageKm: Int
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
    let createdBy: Int?
    let updatedBy: Int?
    let createdAt: String
    let updatedAt: String
    let coverUrl: String?
}

struct ASUAdminCarsSnapshot: Hashable {
    let total: Int
    let brands: [String]
    let cars: [ASUAdminCarRecord]
}

struct ASUAdminCarQuickUpdate {
    var status: CarStatus
    var price: Int64?
    var currency: String
    var priceOnRequest: Bool
    var isPublic: Bool
}

enum ASUAdminCarStatusFilter: String, CaseIterable, Identifiable, Hashable {
    case all
    case inStock = "in_stock"
    case inShowroom = "in_showroom"
    case inTransit = "in_transit"
    case madeToOrder = "made_to_order"
    case reserved
    case sold
    case hidden

    var id: String { rawValue }

    var carStatus: CarStatus? {
        switch self {
        case .all: return nil
        case .inStock: return .inStock
        case .inShowroom: return .inShowroom
        case .inTransit: return .inTransit
        case .madeToOrder: return .madeToOrder
        case .reserved: return .reserved
        case .sold: return .sold
        case .hidden: return .hidden
        }
    }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .all: return L10n.t("Все", "Barchasi", language)
        case .inStock: return L10n.t("В наличии", "Mavjud", language)
        case .inShowroom: return L10n.t("В шоуруме", "Shourumda", language)
        case .inTransit: return L10n.t("В пути", "Yo‘lda", language)
        case .madeToOrder: return L10n.t("Под заказ", "Buyurtma", language)
        case .reserved: return L10n.t("Резерв", "Rezerv", language)
        case .sold: return L10n.t("Продан", "Sotilgan", language)
        case .hidden: return L10n.t("Скрыт", "Yashirilgan", language)
        }
    }
}

enum ASUAdminCarCountryFilter: String, CaseIterable, Identifiable, Hashable {
    case all
    case KR, US, CA, AE, AU, EU, DE, GB, JP, CN, SA, QA, CH

    var id: String { rawValue }

    var queryValue: String? { self == .all ? nil : rawValue }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .all: return L10n.t("Все страны", "Barcha davlatlar", language)
        case .KR: return L10n.t("Корея", "Koreya", language)
        case .US: return L10n.t("США", "AQSh", language)
        case .CA: return L10n.t("Канада", "Kanada", language)
        case .AE: return L10n.t("ОАЭ", "BAA", language)
        case .AU: return L10n.t("Австралия", "Avstraliya", language)
        case .EU: return L10n.t("Европа", "Yevropa", language)
        case .DE: return L10n.t("Германия", "Germaniya", language)
        case .GB: return L10n.t("Великобритания", "Buyuk Britaniya", language)
        case .JP: return L10n.t("Япония", "Yaponiya", language)
        case .CN: return L10n.t("Китай", "Xitoy", language)
        case .SA: return L10n.t("Саудовская Аравия", "Saudiya Arabistoni", language)
        case .QA: return L10n.t("Катар", "Qatar", language)
        case .CH: return L10n.t("Швейцария", "Shveytsariya", language)
        }
    }
}

extension CarStatus {
    func adminTitle(_ language: AppLanguage) -> String {
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
