import Foundation

struct APIClient {
    enum APIError: LocalizedError {
        case unavailable
        case server(Int)
        case malformed

        var errorDescription: String? {
            switch self {
            case .unavailable: return "Нет соединения с каталогом Auto Sale Umar."
            case .server(let code): return "Каталог временно недоступен (HTTP \(code))."
            case .malformed: return "Сервер вернул некорректные данные каталога."
            }
        }
    }

    private struct Envelope: Decodable {
        let success: Bool
        let cars: [CarPayload]
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
        let interiorColor: String?
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

    func fetchPublicCars() async throws -> [Car] {
        var request = URLRequest(url: AppConfig.carsURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.cachePolicy = .reloadRevalidatingCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("AutoSaleUmar-iOS/1.0", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.unavailable }
            guard (200..<300).contains(http.statusCode) else { throw APIError.server(http.statusCode) }

            let envelope = try JSONDecoder().decode(Envelope.self, from: data)
            guard envelope.success else { throw APIError.malformed }

            return envelope.cars.compactMap { payload -> Car? in
                let status = CarStatus(rawValue: payload.status) ?? .unknown
                guard payload.isPublic ?? true, status != .hidden else { return nil }

                let cover = absoluteURL(payload.coverUrl)
                var imageURLs = (payload.images ?? []).compactMap(absoluteURL)
                if let cover, !imageURLs.contains(cover) { imageURLs.insert(cover, at: 0) }

                return Car(
                    id: payload.id,
                    slug: payload.slug,
                    brand: payload.brand,
                    model: payload.model,
                    year: payload.year,
                    trim: payload.trim,
                    vin: payload.vin,
                    stockNumber: payload.stockNumber,
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
                    interiorColor: payload.interiorColor,
                    shortDescriptionRu: payload.shortDescriptionRu,
                    shortDescriptionUz: payload.shortDescriptionUz,
                    descriptionRu: payload.descriptionRu,
                    descriptionUz: payload.descriptionUz,
                    isNew: payload.isNew ?? ((payload.mileageKm ?? 0) == 0),
                    isNewArrival: payload.isNewArrival ?? false,
                    isPublic: payload.isPublic ?? true,
                    isFeatured: payload.isFeatured ?? false,
                    coverURL: cover,
                    imageURLs: imageURLs,
                    updatedAt: payload.updatedAt
                )
            }
        } catch let error as APIError {
            throw error
        } catch is DecodingError {
            throw APIError.malformed
        } catch {
            throw APIError.unavailable
        }
    }

    private func absoluteURL(_ raw: String?) -> URL? {
        guard let raw, !raw.isEmpty else { return nil }
        if let url = URL(string: raw), url.scheme != nil { return url }
        return URL(string: raw, relativeTo: AppConfig.website)?.absoluteURL
    }
}
