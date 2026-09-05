import Foundation

enum ASUCurrency: String, Codable, CaseIterable, Identifiable, Hashable {
    case USD
    case UZS
    case EUR

    var id: String { rawValue }
}

enum ContactChannel: String, Codable, CaseIterable, Identifiable, Hashable {
    case whatsapp
    case telegram
    case phone

    var id: String { rawValue }
}

enum PurchaseTiming: String, Codable, CaseIterable, Identifiable, Hashable {
    case sevenDays = "7_days"
    case thirtyDays = "30_days"
    case ninetyDays = "90_days"
    case flexible

    var id: String { rawValue }
}

enum AdviceCriterion: String, Codable, CaseIterable, Identifiable, Hashable {
    case budget
    case status
    case comfort
    case performance
    case family
    case economy
    case technology
    case ownership
    case resale

    var id: String { rawValue }
}

enum CompareAIAction: String, Codable, Hashable {
    case advice
    case deep
}

struct VehicleRequestDraft: Encodable {
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
}

struct VehicleRequestReceipt: Decodable, Hashable {
    let code: String
    let brand: String
    let model: String
    let status: String
}

struct VisitDraft: Encodable {
    let customerName: String
    let phone: String
    let visitDate: String
    let timeSlot: String
    let brand: String?
    let carId: Int?
    let carLabel: String?
    let note: String?
}

struct VisitReceipt: Decodable, Hashable {
    let code: String
    let visitDate: String
    let timeSlot: String
    let brand: String?
    let carLabel: String?
}

struct CompareQuota: Decodable, Hashable {
    let limit: Int
    let adviceUsed: Int
    let adviceRemaining: Int
    let deepUsed: Int
    let deepRemaining: Int
}

struct CompareSource: Decodable, Hashable, Identifiable {
    let title: String
    let url: String
    var id: String { "\(title)|\(url)" }
}

struct CompareBestFor: Decodable, Hashable, Identifiable {
    let slug: String
    let scenario: String
    var id: String { "\(slug)|\(scenario)" }
}

struct CompareExpandedValue: Decodable, Hashable, Identifiable {
    let slug: String
    let value: String
    var id: String { "\(slug)|\(value)" }
}

struct CompareExpandedRow: Decodable, Hashable, Identifiable {
    let label: String
    let values: [CompareExpandedValue]
    let insight: String
    var id: String { label }
}

struct CompareAIResult: Decodable, Hashable {
    let title: String
    let verdict: String
    let recommendedSlug: String?
    let summary: String
    let reasons: [String]
    let cautions: [String]
    let bestFor: [CompareBestFor]
    let expandedRows: [CompareExpandedRow]
    let verificationNote: String
    let sources: [CompareSource]
}

struct CompareAIAvailability: Hashable {
    let available: Bool
    let reason: String?
}

struct RamadanGiftMedia: Decodable, Hashable, Identifiable {
    let id: Int
    let publicUrl: String
    let photoGroup: String
    let sortOrder: Int
    let isCover: Bool
}

struct RamadanGift: Decodable, Hashable, Identifiable {
    let id: Int?
    let slug: String
    let isActive: Bool
    let titleRu: String
    let titleUz: String
    let subtitleRu: String
    let subtitleUz: String
    let shortPhraseRu: String
    let shortPhraseUz: String
    let descriptionRu: String
    let descriptionUz: String
    let brand: String
    let model: String
    let year: Int?
    let trim: String?
    let exteriorColor: String?
    let interiorColor: String?
    let minPurchaseAmount: Double
    let marketPrice: Double?
    let currency: ASUCurrency
    let instagramUrl: String?
    let orderHref: String?
    let media: [RamadanGiftMedia]
    let updatedAt: String?
    let updatedByName: String?

    var stableID: String { slug }

    func title(_ language: AppLanguage) -> String {
        language == .ru ? titleRu : titleUz
    }

    func subtitle(_ language: AppLanguage) -> String {
        language == .ru ? subtitleRu : subtitleUz
    }

    func shortPhrase(_ language: AppLanguage) -> String {
        language == .ru ? shortPhraseRu : shortPhraseUz
    }

    func description(_ language: AppLanguage) -> String {
        language == .ru ? descriptionRu : descriptionUz
    }

    var coverMedia: RamadanGiftMedia? {
        media.first(where: { $0.isCover }) ?? media.first
    }
}

struct ASUCustomerProfile: Codable, Hashable {
    var name: String
    var phone: String
    var preferredChannel: ContactChannel

    static let empty = ASUCustomerProfile(name: "", phone: "", preferredChannel: .whatsapp)
}

enum ASUClientActivityKind: String, Codable, Hashable {
    case vehicleRequest
    case showroomVisit
}

struct ASUClientActivity: Identifiable, Codable, Hashable {
    let id: UUID
    let kind: ASUClientActivityKind
    let code: String
    let title: String
    let subtitle: String
    let createdAt: Date
    let scheduledDate: String?
    let timeSlot: String?

    init(
        id: UUID = UUID(),
        kind: ASUClientActivityKind,
        code: String,
        title: String,
        subtitle: String,
        createdAt: Date = Date(),
        scheduledDate: String? = nil,
        timeSlot: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.code = code
        self.title = title
        self.subtitle = subtitle
        self.createdAt = createdAt
        self.scheduledDate = scheduledDate
        self.timeSlot = timeSlot
    }
}
