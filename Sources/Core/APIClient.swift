import Foundation

struct APIClient {
    enum APIError: LocalizedError {
        case unavailable
        case server(Int)
        case malformed
        var errorDescription: String? {
            switch self { case .unavailable: return "Public catalog API is unavailable"; case .server(let code): return "Server returned \(code)"; case .malformed: return "Invalid catalog response" }
        }
    }

    func fetchPublicCars() async throws -> [Car] {
        var lastError: Error = APIError.unavailable
        for path in AppConfig.publicCatalogPaths {
            do {
                let result = try await fetchCars(path: path)
                return result.filter { $0.isPublic && $0.status != .hidden }
            } catch { lastError = error }
        }
        throw lastError
    }

    private func fetchCars(path: String) async throws -> [Car] {
        var request = URLRequest(url: AppConfig.url(path))
        request.httpMethod = "GET"
        request.timeoutInterval = 9
        request.cachePolicy = .reloadRevalidatingCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("AutoSaleUmar-iOS/1.0", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.unavailable }
        guard (200..<300).contains(http.statusCode) else { throw APIError.server(http.statusCode) }
        return try decodeCars(data)
    }

    private func decodeCars(_ data: Data) throws -> [Car] {
        let json = try JSONSerialization.jsonObject(with: data)
        let objects: [[String: Any]]
        if let array = json as? [[String: Any]] { objects = array }
        else if let dict = json as? [String: Any], let cars = dict["cars"] as? [[String: Any]] { objects = cars }
        else if let dict = json as? [String: Any], let items = dict["items"] as? [[String: Any]] { objects = items }
        else { throw APIError.malformed }
        return objects.compactMap(parseCar)
    }

    private func parseCar(_ d: [String: Any]) -> Car? {
        func str(_ keys: String...) -> String? { for k in keys { if let v = d[k] as? String, !v.isEmpty { return v } }; return nil }
        func int(_ keys: String...) -> Int? { for k in keys { if let v = d[k] as? Int { return v }; if let n = d[k] as? NSNumber { return n.intValue }; if let s = d[k] as? String, let v = Int(s) { return v } }; return nil }
        func int64(_ keys: String...) -> Int64? { for k in keys { if let n = d[k] as? NSNumber { return n.int64Value }; if let s = d[k] as? String, let v = Int64(s) { return v } }; return nil }
        func bool(_ keys: String..., fallback: Bool = false) -> Bool { for k in keys { if let v = d[k] as? Bool { return v }; if let n = d[k] as? NSNumber { return n.intValue != 0 } }; return fallback }
        guard let id = int("id"), let brand = str("brand"), let model = str("model") else { return nil }
        let rawStatus = str("status") ?? "unknown"
        let status = CarStatus(rawValue: rawStatus) ?? .unknown
        let cover = absoluteURL(str("coverUrl", "coverURL", "imageUrl", "imageURL", "image", "thumbnail"))
        var images: [URL] = []
        if let cover { images.append(cover) }
        for key in ["images", "media"] {
            if let list = d[key] as? [String] { images.append(contentsOf: list.compactMap(absoluteURL)) }
            if let list = d[key] as? [[String: Any]] {
                for item in list { if let u = absoluteURL(item["publicUrl"] as? String ?? item["url"] as? String) { images.append(u) } }
            }
        }
        images = Array(NSOrderedSet(array: images).array.compactMap { $0 as? URL })
        let price = int64("price", "priceAmount")
        return Car(
            id: id, slug: str("slug"), brand: brand, model: model, year: int("year", "modelYear"), trim: str("trim"), vin: str("vin"), stockNumber: str("stockNumber"),
            status: status, countryCode: str("countryCode", "sourceCountry"), arrivalDate: str("arrivalDate"), price: price,
            currency: str("currency", "priceCurrency") ?? "USD", priceOnRequest: bool("priceOnRequest", fallback: price == nil), mileageKm: int("mileageKm"), bodyType: str("bodyType"),
            fuelType: str("fuelType"), driveType: str("driveType", "drivetrain"), transmission: str("transmission"), engineText: str("engineText", "engineName"), seats: int("seats"),
            exteriorColor: str("exteriorColor"), interiorColor: str("interiorColor"), shortDescriptionRu: str("shortDescriptionRu"), shortDescriptionUz: str("shortDescriptionUz"),
            descriptionRu: str("descriptionRu"), descriptionUz: str("descriptionUz"), isNew: bool("isNew", fallback: (int("mileageKm") ?? 0) == 0),
            isNewArrival: bool("isNewArrival"), isPublic: bool("isPublic", "isPublished", fallback: true), isFeatured: bool("isFeatured"), coverURL: cover, imageURLs: images, updatedAt: str("updatedAt")
        )
    }

    private func absoluteURL(_ raw: String?) -> URL? {
        guard let raw, !raw.isEmpty else { return nil }
        if let url = URL(string: raw), url.scheme != nil { return url }
        return URL(string: raw, relativeTo: AppConfig.origin)?.absoluteURL
    }
}
