import Foundation

enum ASUAdminVisitStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case new
    case confirmed
    case completed
    case cancelled

    var id: String { rawValue }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .new: return L10n.t("Новый", "Yangi", language)
        case .confirmed: return L10n.t("Подтверждён", "Tasdiqlangan", language)
        case .completed: return L10n.t("Завершён", "Yakunlangan", language)
        case .cancelled: return L10n.t("Отменён", "Bekor qilingan", language)
        }
    }
}

struct ASUAdminVisit: Decodable, Hashable, Identifiable {
    let id: Int
    let code: String
    let customerName: String
    let phone: String
    let visitDate: String
    let timeSlot: String
    let brand: String?
    let carId: Int?
    let carLabel: String?
    let note: String?
    let status: ASUAdminVisitStatus
    let createdAt: String
    let updatedAt: String
}

enum ASUAdminRequestStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case new
    case contacted
    case sourcing
    case offered
    case completed
    case cancelled

    var id: String { rawValue }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .new: return L10n.t("Новый", "Yangi", language)
        case .contacted: return L10n.t("Связались", "Bog‘landik", language)
        case .sourcing: return L10n.t("Подбор", "Qidiruv", language)
        case .offered: return L10n.t("Предложение", "Taklif", language)
        case .completed: return L10n.t("Сделка", "Savdo", language)
        case .cancelled: return L10n.t("Закрыт", "Yopilgan", language)
        }
    }

    func shortTitle(_ language: AppLanguage) -> String {
        switch self {
        case .new: return L10n.t("Новые", "Yangi", language)
        case .contacted: return L10n.t("Связались", "Bog‘landik", language)
        case .sourcing: return L10n.t("Ищем", "Qidiruvda", language)
        case .offered: return L10n.t("Предложено", "Taklif", language)
        case .completed: return L10n.t("Сделка", "Savdo", language)
        case .cancelled: return L10n.t("Закрыто", "Yopilgan", language)
        }
    }
}

struct ASUAdminVehicleRequest: Decodable, Hashable, Identifiable {
    let id: Int
    let code: String
    let customerName: String
    let phone: String
    let contactChannel: ContactChannel
    let brand: String
    let model: String
    let trim: String?
    let desiredYear: Int?
    let exteriorColor: String?
    let interiorColor: String?
    let importantOptions: String?
    let maxBudget: Double?
    let currency: ASUCurrency
    let purchaseTiming: PurchaseTiming
    let acceptInTransit: Bool
    let sourceUrl: String?
    let note: String?
    let status: ASUAdminRequestStatus
    let createdAt: String
    let updatedAt: String
    let managedBy: Int?
}

struct ASUAdminDemandSignal: Identifiable, Hashable {
    let brand: String
    let model: String
    let count: Int
    let urgent: Int

    var id: String { "\(brand.lowercased())|\(model.lowercased())" }
}

enum ASUAdminRamadanPhotoGroup: String, Codable, CaseIterable, Identifiable, Hashable {
    case exterior
    case interior

    var id: String { rawValue }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .exterior: return L10n.t("Кузов", "Kuzov", language)
        case .interior: return L10n.t("Салон", "Salon", language)
        }
    }
}

struct ASUAdminRamadanGiftDraft {
    var isActive: Bool
    var titleRu: String
    var titleUz: String
    var subtitleRu: String
    var subtitleUz: String
    var shortPhraseRu: String
    var shortPhraseUz: String
    var descriptionRu: String
    var descriptionUz: String
    var brand: String
    var model: String
    var year: String
    var trim: String
    var exteriorColor: String
    var interiorColor: String
    var minPurchaseAmount: String
    var marketPrice: String
    var currency: ASUCurrency
    var instagramUrl: String
    var orderHref: String

    init(gift: RamadanGift) {
        isActive = gift.isActive
        titleRu = gift.titleRu
        titleUz = gift.titleUz
        subtitleRu = gift.subtitleRu
        subtitleUz = gift.subtitleUz
        shortPhraseRu = gift.shortPhraseRu
        shortPhraseUz = gift.shortPhraseUz
        descriptionRu = gift.descriptionRu
        descriptionUz = gift.descriptionUz
        brand = gift.brand
        model = gift.model
        year = gift.year.map(String.init) ?? ""
        trim = gift.trim ?? ""
        exteriorColor = gift.exteriorColor ?? ""
        interiorColor = gift.interiorColor ?? ""
        minPurchaseAmount = Self.numberString(gift.minPurchaseAmount)
        marketPrice = gift.marketPrice.map(Self.numberString) ?? ""
        currency = gift.currency
        instagramUrl = gift.instagramUrl ?? ""
        orderHref = gift.orderHref ?? "/compare/"
    }

    private static func numberString(_ value: Double) -> String {
        if value.rounded() == value { return String(Int64(value)) }
        return String(value)
    }
}
