import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct ASUHomeMediaItem: Identifiable, Hashable {
    let key: String
    let url: URL
    let size: Int64
    let uploadedAt: String?
    let brand: String
    let model: String
    let price: Int64?
    let currency: ASUCurrency
    let priceOnRequest: Bool
    let status: CarStatus

    var id: String { key }
}

struct ASUBrandCoverItem: Identifiable, Hashable {
    let key: String
    let url: URL
    let size: Int64
    let uploadedAt: String?

    var id: String { key }
}

struct ASUPublicPresentationAPI {
    enum PresentationError: Error {
        case unavailable
        case malformed
    }

    private struct HomeMediaEnvelope: Decodable {
        let success: Bool?
        let videos: [HomeMediaDTO]?
    }

    private struct HomeMediaDTO: Decodable {
        let key: String
        let url: String
        let size: Int64?
        let uploadedAt: String?
        let brand: String?
        let model: String?
        let price: Int64?
        let currency: String?
        let priceOnRequest: Bool?
        let status: String?
    }

    private struct BrandMediaEnvelope: Decodable {
        let success: Bool?
        let images: [BrandMediaDTO]?
    }

    private struct BrandMediaDTO: Decodable {
        let key: String
        let url: String
        let size: Int64?
        let uploadedAt: String?
    }

    func fetchHomeMedia() async throws -> [ASUHomeMediaItem] {
        let data = try await request(AppConfig.website.appending(path: "api/home-media"))
        let envelope = try JSONDecoder().decode(HomeMediaEnvelope.self, from: data)
        guard envelope.success == true else { throw PresentationError.malformed }

        return (envelope.videos ?? []).compactMap { item in
            guard let url = resolveWebsiteURL(item.url), isPlayableHeroURL(url) else { return nil }
            let currency = ASUCurrency(rawValue: item.currency?.uppercased() ?? "USD") ?? .USD
            let status = CarStatus(rawValue: item.status ?? "") ?? .inShowroom
            return ASUHomeMediaItem(
                key: item.key,
                url: url,
                size: item.size ?? 0,
                uploadedAt: item.uploadedAt,
                brand: cleaned(item.brand, fallback: "AUTO SALE UMAR"),
                model: cleaned(item.model, fallback: "Premium showroom"),
                price: item.price,
                currency: currency,
                priceOnRequest: item.priceOnRequest ?? (item.price == nil),
                status: status
            )
        }
    }

    func fetchBrandCovers(brand: String) async throws -> [ASUBrandCoverItem] {
        var components = URLComponents(url: AppConfig.website.appending(path: "api/brand-media"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "brand", value: brand)]
        guard let url = components?.url else { throw PresentationError.malformed }

        let data = try await request(url)
        let envelope = try JSONDecoder().decode(BrandMediaEnvelope.self, from: data)
        guard envelope.success == true else { throw PresentationError.malformed }

        return (envelope.images ?? []).compactMap { item in
            guard let url = resolveWebsiteURL(item.url) else { return nil }
            return ASUBrandCoverItem(
                key: item.key,
                url: url,
                size: item.size ?? 0,
                uploadedAt: item.uploadedAt
            )
        }
    }

    private func request(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("AutoSaleUmar-iOS/5.0", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode) else {
                throw PresentationError.unavailable
            }
            return data
        } catch let error as PresentationError {
            throw error
        } catch {
            throw PresentationError.unavailable
        }
    }

    private func resolveWebsiteURL(_ rawValue: String) -> URL? {
        let raw = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }
        if let absolute = URL(string: raw), absolute.scheme != nil { return absolute }
        guard let relative = URL(string: raw, relativeTo: AppConfig.website) else { return nil }
        return relative.absoluteURL
    }

    private func isPlayableHeroURL(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        // AVPlayer is reliable with MP4/MOV. Ignore WebM entries rather than showing a broken premium hero.
        return ext == "mp4" || ext == "mov" || ext == "m4v"
    }

    private func cleaned(_ value: String?, fallback: String) -> String {
        let clean = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return clean.isEmpty ? fallback : clean
    }
}
