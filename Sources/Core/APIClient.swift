import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct APIClient {
    enum APIError: LocalizedError {
        case unavailable
        case server(Int)
        case malformed
        case notFound

        var errorDescription: String? {
            switch self {
            case .unavailable: return "Нет соединения с каталогом Auto Sale Umar."
            case .server(let code): return "Каталог временно недоступен (HTTP \(code))."
            case .malformed: return "Сервер вернул некорректные данные каталога."
            case .notFound: return "Автомобиль не найден."
            }
        }
    }

    private struct Envelope: Decodable {
        let success: Bool
        let cars: [CarPayload]
    }

    private struct DetailEnvelope: Decodable {
        let success: Bool
        let car: CarDetailPayload?
    }

    private struct CarPayload: Decodable {
        let id: Int
        let slug: String?
        let brand: String
        let model: String
        let year: Int?
        let trim: String?
        let vin: String?
        let stockNumber: String?
        let status: String
        let countryCode: String?
        let arrivalDate: String?
        let price: Int64?
        let currency: String?
        let priceOnRequest: Bool?
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
        let isNew: Bool?
        let isNewArrival: Bool?
        let isPublic: Bool?
        let isFeatured: Bool?
        let coverUrl: String?
        let images: [String]?
        let updatedAt: String?
    }

    private struct PhotoPayload: Decodable {
        let id: Int
        let url: String
        let isCover: Bool?
        let sortOrder: Int?
    }

    private struct VariantPayload: Decodable {
        let id: Int
        let exteriorColorName: String?
        let exteriorSwatch: String?
        let interiorColorName: String?
        let interiorSwatch: String?
        let photos: [PhotoPayload]?
        let interiorPhotos: [PhotoPayload]?
        let detailPhotos: [PhotoPayload]?
    }

    private struct CarDetailPayload: Decodable {
        let id: Int
        let slug: String
        let brand: String
        let model: String
        let year: Int?
        let trim: String?
        let status: String
        let countryCode: String?
        let arrivalDate: String?
        let price: Int64?
        let currency: String?
        let priceOnRequest: Bool?
        let mileageKm: Int?
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
        let isNew: Bool?
        let isNewArrival: Bool?
        let isFeatured: Bool?
        let coverUrl: String?
        let weeklyViews: Int?
        let engineDisplacementL: Double?
        let horsepowerHp: Int?
        let torqueNm: Int?
        let acceleration0100: Double?
        let topSpeedKmh: Int?
        let fuelConsumptionL100: Double?
        let electricRangeKm: Int?
        let instagramUrl: String?
        let variants: [VariantPayload]?
    }

    func fetchPublicCars() async throws -> [Car] {
        let data = try await data(from: AppConfig.carsURL)
        let envelope: Envelope
        do { envelope = try JSONDecoder().decode(Envelope.self, from: data) }
        catch { throw APIError.malformed }
        guard envelope.success else { throw APIError.malformed }

        return envelope.cars.compactMap { payload -> Car? in
            let status = CarStatus(rawValue: payload.status) ?? .unknown
            guard payload.isPublic ?? true, status != .hidden else { return nil }

            let cover = normalizedRemoteURL(payload.coverUrl)
            let images = deduplicatedURLs(from: payload.images, cover: cover)

            return Car(
                id: payload.id,
                slug: payload.slug,
                brand: payload.brand,
                model: payload.model,
                year: payload.year,
                trim: payload.trim,
                vin: nil,
                stockNumber: nil,
                status: status,
                countryCode: payload.countryCode,
                arrivalDate: payload.arrivalDate,
                price: payload.price,
                currency: payload.currency ?? "USD",
                priceOnRequest: payload.priceOnRequest ?? (payload.price == nil),
                mileageKm: payload.mileageKm,
                engineText: payload.engineText,
                fuelType: payload.fuelType,
                driveType: payload.driveType,
                transmission: payload.transmission,
                seats: payload.seats,
                exteriorColor: payload.exteriorColor,
                exteriorSwatch: payload.exteriorSwatch,
                interiorColor: payload.interiorColor,
                interiorSwatch: payload.interiorSwatch,
                shortDescriptionRu: payload.shortDescriptionRu,
                shortDescriptionUz: payload.shortDescriptionUz,
                descriptionRu: payload.descriptionRu,
                descriptionUz: payload.descriptionUz,
                isNew: payload.isNew ?? ((payload.mileageKm ?? 0) == 0),
                isNewArrival: payload.isNewArrival ?? false,
                isPublic: payload.isPublic ?? true,
                isFeatured: payload.isFeatured ?? false,
                coverURL: cover,
                imageURLs: images,
                updatedAt: payload.updatedAt
            )
        }
    }

    func fetchCarDetail(slug: String) async throws -> CarDetail {
        let cleaned = slug.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw APIError.notFound }

        do {
            return try await fetchCarDetail(url: AppConfig.carDetailURL(slug: cleaned))
        } catch {
            var components = URLComponents(url: AppConfig.website.appending(path: "api/catalog"), resolvingAgainstBaseURL: false)!
            components.queryItems = [URLQueryItem(name: "slug", value: cleaned)]
            guard let fallback = components.url else { throw error }
            return try await fetchCarDetail(url: fallback)
        }
    }

    private func fetchCarDetail(url: URL) async throws -> CarDetail {
        let payloadData = try await data(from: url)
        let envelope: DetailEnvelope
        do { envelope = try JSONDecoder().decode(DetailEnvelope.self, from: payloadData) }
        catch { throw APIError.malformed }
        guard envelope.success, let payload = envelope.car else { throw APIError.notFound }

        let variants = (payload.variants ?? []).map { variant in
            CarVariant(
                id: variant.id,
                exteriorColorName: variant.exteriorColorName,
                exteriorSwatch: variant.exteriorSwatch ?? "#111214",
                interiorColorName: variant.interiorColorName,
                interiorSwatch: variant.interiorSwatch ?? "#111214",
                photos: photos(from: variant.photos),
                interiorPhotos: photos(from: variant.interiorPhotos),
                detailPhotos: photos(from: variant.detailPhotos)
            )
        }

        let cover = normalizedRemoteURL(payload.coverUrl)
        let performance = CarPerformance(
            engineDisplacementL: payload.engineDisplacementL,
            horsepowerHp: payload.horsepowerHp,
            torqueNm: payload.torqueNm,
            acceleration0100: payload.acceleration0100,
            topSpeedKmh: payload.topSpeedKmh,
            fuelConsumptionL100: payload.fuelConsumptionL100,
            electricRangeKm: payload.electricRangeKm
        )

        return CarDetail(
            id: payload.id,
            slug: payload.slug,
            brand: payload.brand,
            model: payload.model,
            year: payload.year,
            trim: payload.trim,
            status: CarStatus(rawValue: payload.status) ?? .unknown,
            countryCode: payload.countryCode,
            arrivalDate: payload.arrivalDate,
            price: payload.price,
            currency: payload.currency ?? "USD",
            priceOnRequest: payload.priceOnRequest ?? (payload.price == nil),
            mileageKm: payload.mileageKm ?? 0,
            fuelType: payload.fuelType,
            driveType: payload.driveType,
            transmission: payload.transmission,
            engineText: payload.engineText,
            seats: payload.seats,
            exteriorColor: payload.exteriorColor,
            interiorColor: payload.interiorColor,
            shortDescriptionRu: payload.shortDescriptionRu,
            shortDescriptionUz: payload.shortDescriptionUz,
            descriptionRu: payload.descriptionRu,
            descriptionUz: payload.descriptionUz,
            isNew: payload.isNew ?? ((payload.mileageKm ?? 0) == 0),
            isNewArrival: payload.isNewArrival ?? false,
            isFeatured: payload.isFeatured ?? false,
            coverURL: cover,
            weeklyViews: payload.weeklyViews ?? 0,
            performance: performance,
            instagramURL: normalizedRemoteURL(payload.instagramUrl),
            variants: variants
        )
    }

    private func data(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 18
        request.cachePolicy = .reloadRevalidatingCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("AutoSaleUmar-iOS/2.0", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.unavailable }
            if http.statusCode == 404 { throw APIError.notFound }
            guard (200..<300).contains(http.statusCode) else { throw APIError.server(http.statusCode) }
            return data
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.unavailable
        }
    }

    private func photos(from payloads: [PhotoPayload]?) -> [CarPhoto] {
        (payloads ?? []).compactMap { payload in
            guard let url = normalizedRemoteURL(payload.url) else { return nil }
            return CarPhoto(id: payload.id, url: url, isCover: payload.isCover ?? false, sortOrder: payload.sortOrder ?? 0)
        }
    }

    private func deduplicatedURLs(from rawItems: [String]?, cover: URL?) -> [URL] {
        var seen = Set<String>()
        var urls: [URL] = []
        if let cover, seen.insert(cover.absoluteString).inserted { urls.append(cover) }
        for raw in rawItems ?? [] {
            guard let url = normalizedRemoteURL(raw) else { continue }
            if seen.insert(url.absoluteString).inserted { urls.append(url) }
        }
        return urls
    }

    private func normalizedRemoteURL(_ raw: String?) -> URL? {
        guard var value = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        value = value.replacingOccurrences(of: "\\", with: "/")
        if value.hasPrefix("//") { value = "https:\(value)" }

        if let direct = URL(string: value), direct.scheme != nil { return direct }
        let encoded = encodeURLString(value)
        if let direct = URL(string: encoded), direct.scheme != nil { return direct }

        let relative = value.hasPrefix("/") ? value : "/\(value)"
        return URL(string: encodeURLString(relative), relativeTo: AppConfig.website)?.absoluteURL
    }

    private func encodeURLString(_ string: String) -> String {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~:/?#[]@!$&'()*+,;=%")
        return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
    }
}
