import Foundation

enum ASUAdminMediaCurrency: String, Codable, CaseIterable, Identifiable, Hashable {
    case USD
    case UZS
    case EUR

    var id: String { rawValue }
}

enum ASUAdminHomeVideoStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case inStock = "in_stock"
    case inShowroom = "in_showroom"
    case inTransit = "in_transit"
    case madeToOrder = "made_to_order"
    case reserved

    var id: String { rawValue }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .inStock:
            return L10n.t("В наличии", "Mavjud", language)
        case .inShowroom:
            return L10n.t("В шоуруме", "Shourumda", language)
        case .inTransit:
            return L10n.t("В пути", "Yo‘lda", language)
        case .madeToOrder:
            return L10n.t("Под заказ", "Buyurtma", language)
        case .reserved:
            return L10n.t("Резерв", "Rezerv", language)
        }
    }
}

struct ASUAdminBrandCover: Decodable, Hashable, Identifiable {
    let key: String
    let url: String
    let size: Int64
    let uploadedAt: String?

    var id: String { key }

    var resolvedURL: URL? {
        ASUAdminMediaURL.resolve(url)
    }
}

struct ASUAdminBrandCoverSnapshot: Hashable {
    let brand: String
    let maxCovers: Int
    let images: [ASUAdminBrandCover]
}

struct ASUAdminHomeVideo: Codable, Hashable, Identifiable {
    let key: String
    let url: String
    let size: Int64
    let uploadedAt: String?
    var brand: String
    var model: String
    var price: Int64?
    var currency: ASUAdminMediaCurrency
    var priceOnRequest: Bool
    var status: ASUAdminHomeVideoStatus

    var id: String { key }

    var resolvedURL: URL? {
        ASUAdminMediaURL.resolve(url)
    }
}

enum ASUAdminMediaURL {
    static func resolve(_ rawValue: String) -> URL? {
        let raw = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }
        if let absolute = URL(string: raw), absolute.scheme != nil { return absolute }
        return URL(string: raw, relativeTo: AppConfig.website)?.absoluteURL
    }
}

enum ASUAdminMediaFormatting {
    static func fileSize(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "—" }
        let megabytes = Double(bytes) / (1024.0 * 1024.0)
        if megabytes < 10 {
            return String(format: "%.1f MB", megabytes)
        }
        return "\(Int(megabytes.rounded())) MB"
    }

    static func price(_ value: Int64?, currency: ASUAdminMediaCurrency, onRequest: Bool, language: AppLanguage) -> String {
        guard !onRequest, let value else {
            return L10n.t("Цена по запросу", "Narx so‘rov bo‘yicha", language)
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = " "
        let number = formatter.string(from: NSNumber(value: value)) ?? String(value)
        switch currency {
        case .USD: return "\(number) $"
        case .EUR: return "\(number) €"
        case .UZS: return "\(number) \(L10n.t("сум", "so‘m", language))"
        }
    }
}
