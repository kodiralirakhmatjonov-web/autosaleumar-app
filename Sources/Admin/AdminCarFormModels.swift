import Foundation

// MARK: - Full vehicle editor contracts

enum ASUAdminPhotoGroup: String, CaseIterable, Identifiable, Codable, Hashable {
    case exterior
    case interior
    case detail

    var id: String { rawValue }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .exterior: return L10n.t("Кузов", "Kuzov", language)
        case .interior: return L10n.t("Салон", "Salon", language)
        case .detail: return L10n.t("Детали", "Detallar", language)
        }
    }

    func subtitle(_ language: AppLanguage) -> String {
        switch self {
        case .exterior:
            return L10n.t("Основные фотографии автомобиля", "Avtomobilning asosiy suratlari", language)
        case .interior:
            return L10n.t("Интерьер и материалы салона", "Interyer va salon materiallari", language)
        case .detail:
            return L10n.t("Фары, диски, решётка и уникальные элементы", "Faralar, disklar, panjara va noyob detallar", language)
        }
    }
}

struct ASUAdminCarDetailMedia: Decodable, Hashable, Identifiable {
    let id: Int
    let publicUrl: String
    let objectKey: String
    let isCover: Bool
    let sortOrder: Int
}

struct ASUAdminCarDetailVariant: Decodable, Hashable, Identifiable {
    let id: Int
    let exteriorColorName: String
    let exteriorSwatch: String
    let interiorColorName: String
    let interiorSwatch: String
    let vin: String
    let stockNumber: String
    let quantity: Int
    let exteriorPhotos: [ASUAdminCarDetailMedia]
    let interiorPhotos: [ASUAdminCarDetailMedia]
    let detailPhotos: [ASUAdminCarDetailMedia]
}

struct ASUAdminCarDetailPayload: Decodable, Hashable, Identifiable {
    let id: Int
    let slug: String
    let brand: String
    let model: String
    let year: Int?
    let trim: String
    let status: CarStatus
    let countryCode: String
    let arrivalDate: String
    let isNew: Bool
    let mileageKm: Int

    let engineText: String
    let engineDisplacementL: Double?
    let fuelType: String
    let driveType: String
    let transmission: String
    let seats: Int?
    let horsepowerHp: Int?
    let torqueNm: Int?
    let acceleration0100: Double?
    let topSpeedKmh: Int?
    let fuelConsumptionL100: Double?
    let electricRangeKm: Int?

    let price: Int64?
    let currency: String
    let priceOnRequest: Bool
    let instagramUrl: String

    let shortDescriptionRu: String
    let shortDescriptionUz: String
    let descriptionRu: String
    let descriptionUz: String

    let isPublic: Bool
    let isFeatured: Bool
    let variants: [ASUAdminCarDetailVariant]
}

struct ASUAdminSavedVariant: Decodable, Hashable, Identifiable {
    let id: Int
    let index: Int
}

struct ASUAdminCarPersistenceReceipt: Hashable {
    let carID: Int
    let title: String
    let variants: [ASUAdminSavedVariant]
}

struct ASUAdminUploadedMedia: Hashable, Identifiable {
    let id: Int
    let carID: Int
    let variantID: Int
    let group: ASUAdminPhotoGroup
    let publicURL: String
    let isCover: Bool
    let sortOrder: Int

    func asDetailMedia() -> ASUAdminCarDetailMedia {
        ASUAdminCarDetailMedia(
            id: id,
            publicUrl: publicURL,
            objectKey: "",
            isCover: isCover,
            sortOrder: sortOrder
        )
    }
}

struct ASUAdminPendingPhoto: Identifiable {
    let id: UUID
    let data: Data
    let filename: String
    let mimeType: String

    init(id: UUID = UUID(), data: Data, filename: String, mimeType: String = "image/jpeg") {
        self.id = id
        self.data = data
        self.filename = filename
        self.mimeType = mimeType
    }
}

struct ASUAdminCarVariantDraft: Identifiable {
    let localID: UUID
    var dbID: Int?
    var exteriorColorName: String
    var exteriorSwatch: String
    var interiorColorName: String
    var interiorSwatch: String
    var vin: String
    var stockNumber: String
    var quantity: String

    var existingExteriorPhotos: [ASUAdminCarDetailMedia]
    var existingInteriorPhotos: [ASUAdminCarDetailMedia]
    var existingDetailPhotos: [ASUAdminCarDetailMedia]

    var exteriorPhotos: [ASUAdminPendingPhoto]
    var interiorPhotos: [ASUAdminPendingPhoto]
    var detailPhotos: [ASUAdminPendingPhoto]

    var id: UUID { localID }

    init(index: Int = 0) {
        localID = UUID()
        dbID = nil
        exteriorColorName = ""
        exteriorSwatch = index == 0 ? "#111214" : "#f4f4f0"
        interiorColorName = ""
        interiorSwatch = "#111214"
        vin = ""
        stockNumber = ""
        quantity = "1"
        existingExteriorPhotos = []
        existingInteriorPhotos = []
        existingDetailPhotos = []
        exteriorPhotos = []
        interiorPhotos = []
        detailPhotos = []
    }

    init(detail: ASUAdminCarDetailVariant) {
        localID = UUID()
        dbID = detail.id
        exteriorColorName = detail.exteriorColorName
        exteriorSwatch = detail.exteriorSwatch
        interiorColorName = detail.interiorColorName
        interiorSwatch = detail.interiorSwatch
        vin = detail.vin
        stockNumber = detail.stockNumber
        quantity = String(detail.quantity)
        existingExteriorPhotos = detail.exteriorPhotos
        existingInteriorPhotos = detail.interiorPhotos
        existingDetailPhotos = detail.detailPhotos
        exteriorPhotos = []
        interiorPhotos = []
        detailPhotos = []
    }

    var exteriorPhotoCount: Int { existingExteriorPhotos.count + exteriorPhotos.count }
    var totalNewPhotoCount: Int { exteriorPhotos.count + interiorPhotos.count + detailPhotos.count }

    func existingPhotos(for group: ASUAdminPhotoGroup) -> [ASUAdminCarDetailMedia] {
        switch group {
        case .exterior: return existingExteriorPhotos
        case .interior: return existingInteriorPhotos
        case .detail: return existingDetailPhotos
        }
    }

    func newPhotos(for group: ASUAdminPhotoGroup) -> [ASUAdminPendingPhoto] {
        switch group {
        case .exterior: return exteriorPhotos
        case .interior: return interiorPhotos
        case .detail: return detailPhotos
        }
    }
}

struct ASUAdminCarFormDraft {
    var brand: String
    var model: String
    var year: String
    var trim: String
    var status: CarStatus
    var countryCode: String
    var arrivalDate: String
    var isNew: Bool
    var mileageKm: String

    var engineText: String
    var engineDisplacementL: String
    var fuelType: String
    var driveType: String
    var transmission: String
    var seats: String
    var horsepowerHp: String
    var torqueNm: String
    var acceleration0100: String
    var topSpeedKmh: String
    var fuelConsumptionL100: String
    var electricRangeKm: String

    var price: String
    var currency: String
    var priceOnRequest: Bool
    var instagramUrl: String

    var shortDescriptionRu: String
    var shortDescriptionUz: String
    var descriptionRu: String
    var descriptionUz: String

    var isPublic: Bool
    var isFeatured: Bool
    var variants: [ASUAdminCarVariantDraft]

    init() {
        brand = ""
        model = ""
        year = "2026"
        trim = ""
        status = .inStock
        countryCode = "KR"
        arrivalDate = ""
        isNew = true
        mileageKm = "0"
        engineText = ""
        engineDisplacementL = ""
        fuelType = ""
        driveType = ""
        transmission = "automatic"
        seats = ""
        horsepowerHp = ""
        torqueNm = ""
        acceleration0100 = ""
        topSpeedKmh = ""
        fuelConsumptionL100 = ""
        electricRangeKm = ""
        price = ""
        currency = "USD"
        priceOnRequest = false
        instagramUrl = ""
        shortDescriptionRu = ""
        shortDescriptionUz = ""
        descriptionRu = ""
        descriptionUz = ""
        isPublic = false
        isFeatured = false
        variants = [ASUAdminCarVariantDraft(index: 0)]
    }

    static func newCar() -> ASUAdminCarFormDraft {
        ASUAdminCarFormDraft()
    }

    init(detail: ASUAdminCarDetailPayload) {
        brand = detail.brand
        model = detail.model
        year = detail.year.map(String.init) ?? "2026"
        trim = detail.trim
        status = detail.status
        countryCode = detail.countryCode
        arrivalDate = detail.arrivalDate
        isNew = detail.isNew
        mileageKm = String(detail.mileageKm)
        engineText = detail.engineText
        engineDisplacementL = Self.numberText(detail.engineDisplacementL)
        fuelType = detail.fuelType
        driveType = detail.driveType
        transmission = detail.transmission.isEmpty ? "automatic" : detail.transmission
        seats = detail.seats.map(String.init) ?? ""
        horsepowerHp = detail.horsepowerHp.map(String.init) ?? ""
        torqueNm = detail.torqueNm.map(String.init) ?? ""
        acceleration0100 = Self.numberText(detail.acceleration0100)
        topSpeedKmh = detail.topSpeedKmh.map(String.init) ?? ""
        fuelConsumptionL100 = Self.numberText(detail.fuelConsumptionL100)
        electricRangeKm = detail.electricRangeKm.map(String.init) ?? ""
        price = detail.price.map(String.init) ?? ""
        currency = detail.currency
        priceOnRequest = detail.priceOnRequest
        instagramUrl = detail.instagramUrl
        shortDescriptionRu = detail.shortDescriptionRu
        shortDescriptionUz = detail.shortDescriptionUz
        descriptionRu = detail.descriptionRu
        descriptionUz = detail.descriptionUz
        isPublic = detail.isPublic
        isFeatured = detail.isFeatured
        variants = detail.variants.isEmpty ? [ASUAdminCarVariantDraft(index: 0)] : detail.variants.map { ASUAdminCarVariantDraft(detail: $0) }
    }

    var showsArrivalDate: Bool {
        status == .inTransit || status == .madeToOrder || status == .reserved
    }

    var totalExteriorPhotoCount: Int {
        variants.reduce(0) { $0 + $1.exteriorPhotoCount }
    }

    var totalNewPhotoCount: Int {
        variants.reduce(0) { $0 + $1.totalNewPhotoCount }
    }

    var hasExistingExteriorPhoto: Bool {
        variants.contains { !$0.existingExteriorPhotos.isEmpty }
    }

    private static func numberText(_ value: Double?) -> String {
        guard let value else { return "" }
        if value.rounded() == value { return String(Int(value)) }
        return String(value)
    }
}

// MARK: - API payloads

struct ASUAdminCarVariantInput: Encodable {
    let id: Int?
    let exteriorColorName: String?
    let exteriorSwatch: String
    let interiorColorName: String?
    let interiorSwatch: String
    let vin: String?
    let stockNumber: String?
    let quantity: Int
}

struct ASUAdminCarSavePayload: Encodable {
    let id: Int?
    let brand: String
    let model: String
    let year: Int?
    let trim: String?
    let status: String
    let countryCode: String
    let arrivalDate: String?

    let isNew: Bool
    let mileageKm: Int?
    let engineText: String?
    let engineDisplacementL: Double?
    let fuelType: String?
    let driveType: String?
    let transmission: String
    let seats: Int?
    let horsepowerHp: Int?
    let torqueNm: Int?
    let acceleration0100: Double?
    let topSpeedKmh: Int?
    let fuelConsumptionL100: Double?
    let electricRangeKm: Int?

    let price: Int64?
    let currency: String
    let priceOnRequest: Bool
    let instagramUrl: String?

    let shortDescriptionRu: String?
    let shortDescriptionUz: String?
    let descriptionRu: String?
    let descriptionUz: String?

    let isPublic: Bool
    let isFeatured: Bool
    let variants: [ASUAdminCarVariantInput]
}

// MARK: - Mini AI

struct ASUAdminCarAIVariant: Decodable, Hashable {
    let exteriorColorName: String?
    let exteriorSwatch: String?
    let interiorColorName: String?
    let interiorSwatch: String?
    let vin: String?
    let stockNumber: String?
    let quantity: Int?
}

struct ASUAdminCarAIResult: Decodable, Hashable {
    let brand: String?
    let model: String?
    let year: Int?
    let trim: String?
    let status: String?
    let countryCode: String?
    let arrivalDate: String?
    let isNew: Bool?
    let mileageKm: Int?

    let engineText: String?
    let engineDisplacementL: Double?
    let fuelType: String?
    let driveType: String?
    let transmission: String?
    let seats: Int?
    let horsepowerHp: Int?
    let torqueNm: Int?
    let acceleration0100: Double?
    let topSpeedKmh: Int?
    let fuelConsumptionL100: Double?
    let electricRangeKm: Int?

    let price: Int64?
    let currency: String?
    let priceOnRequest: Bool?
    let instagramUrl: String?

    let shortDescriptionRu: String?
    let shortDescriptionUz: String?
    let descriptionRu: String?
    let descriptionUz: String?

    let variants: [ASUAdminCarAIVariant]
    let warnings: [String]
}

struct ASUAdminCarAIResponse: Hashable {
    let model: String?
    let result: ASUAdminCarAIResult
}
