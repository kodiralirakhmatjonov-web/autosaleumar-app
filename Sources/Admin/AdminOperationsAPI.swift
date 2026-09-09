import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct ASUAdminOperationsAPI {
    private struct VisitsEnvelope: Decodable {
        let success: Bool?
        let visits: [ASUAdminVisit]?
        let visit: ASUAdminVisit?
        let error: String?
    }

    private struct RequestsEnvelope: Decodable {
        let success: Bool?
        let requests: [ASUAdminVehicleRequest]?
        let request: ASUAdminVehicleRequest?
        let error: String?
    }

    private struct StatusPayload: Encodable {
        let id: Int
        let status: String
    }

    private let api = ASUAdminAPI()

    func visits(token: String) async throws -> [ASUAdminVisit] {
        let data = try await api.authorizedData(path: "api/visits", token: token)
        let envelope: VisitsEnvelope
        do { envelope = try JSONDecoder().decode(VisitsEnvelope.self, from: data) }
        catch { throw ASUAdminAPI.APIError.invalidResponse }
        guard envelope.success == true else {
            throw ASUAdminAPI.APIError.server(200, envelope.error ?? "Не удалось загрузить визиты.")
        }
        return envelope.visits ?? []
    }

    func updateVisit(id: Int, status: ASUAdminVisitStatus, token: String) async throws -> ASUAdminVisit {
        let body = try JSONEncoder().encode(StatusPayload(id: id, status: status.rawValue))
        let data = try await api.authorizedData(path: "api/visits", method: "PATCH", token: token, body: body)
        let envelope: VisitsEnvelope
        do { envelope = try JSONDecoder().decode(VisitsEnvelope.self, from: data) }
        catch { throw ASUAdminAPI.APIError.invalidResponse }
        guard envelope.success == true, let visit = envelope.visit else {
            throw ASUAdminAPI.APIError.server(200, envelope.error ?? "Не удалось обновить визит.")
        }
        return visit
    }

    func vehicleRequests(token: String) async throws -> [ASUAdminVehicleRequest] {
        let data = try await api.authorizedData(path: "api/vehicle-requests", token: token)
        let envelope: RequestsEnvelope
        do { envelope = try JSONDecoder().decode(RequestsEnvelope.self, from: data) }
        catch { throw ASUAdminAPI.APIError.invalidResponse }
        guard envelope.success == true else {
            throw ASUAdminAPI.APIError.server(200, envelope.error ?? "Не удалось загрузить запросы.")
        }
        return envelope.requests ?? []
    }

    func updateVehicleRequest(id: Int, status: ASUAdminRequestStatus, token: String) async throws -> ASUAdminVehicleRequest {
        let body = try JSONEncoder().encode(StatusPayload(id: id, status: status.rawValue))
        let data = try await api.authorizedData(path: "api/vehicle-requests", method: "PATCH", token: token, body: body)
        let envelope: RequestsEnvelope
        do { envelope = try JSONDecoder().decode(RequestsEnvelope.self, from: data) }
        catch { throw ASUAdminAPI.APIError.invalidResponse }
        guard envelope.success == true, let request = envelope.request else {
            throw ASUAdminAPI.APIError.server(200, envelope.error ?? "Не удалось обновить запрос.")
        }
        return request
    }
}

struct ASUAdminRamadanAPI {
    private struct GiftEnvelope: Decodable {
        let success: Bool?
        let gift: RamadanGift?
        let error: String?
    }

    private struct MediaEnvelope: Decodable {
        let success: Bool?
        let error: String?
    }

    private struct GiftPayload: Encodable {
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
        let minPurchaseAmount: Int64
        let marketPrice: Int64?
        let currency: ASUCurrency
        let instagramUrl: String?
        let orderHref: String?
    }

    private struct ErrorEnvelope: Decodable {
        let error: String?
    }

    private var giftURL: URL { AppConfig.website.appending(path: "api/ramadan-gift") }
    private var mediaURL: URL { AppConfig.website.appending(path: "api/ramadan-gift-media") }

    func loadGift(token: String) async throws -> RamadanGift {
        let data = try await request(url: giftURL, method: "GET", token: token, body: nil, contentType: nil)
        let envelope: GiftEnvelope
        do { envelope = try JSONDecoder().decode(GiftEnvelope.self, from: data) }
        catch { throw ASUAdminAPI.APIError.invalidResponse }
        guard envelope.success == true, let gift = envelope.gift else {
            throw ASUAdminAPI.APIError.server(200, envelope.error ?? "Не удалось загрузить Ramadan Gift.")
        }
        return gift
    }

    func saveGift(draft: ASUAdminRamadanGiftDraft, token: String) async throws -> RamadanGift {
        let titleRu = clean(draft.titleRu)
        let titleUz = clean(draft.titleUz)
        let subtitleRu = clean(draft.subtitleRu)
        let subtitleUz = clean(draft.subtitleUz)
        let shortPhraseRu = clean(draft.shortPhraseRu)
        let shortPhraseUz = clean(draft.shortPhraseUz)
        let descriptionRu = clean(draft.descriptionRu)
        let descriptionUz = clean(draft.descriptionUz)
        let brand = clean(draft.brand)
        let model = clean(draft.model)

        guard !titleRu.isEmpty, !titleUz.isEmpty else {
            throw ASUAdminAPI.APIError.server(400, "Укажите заголовок на двух языках.")
        }
        guard !subtitleRu.isEmpty, !subtitleUz.isEmpty else {
            throw ASUAdminAPI.APIError.server(400, "Укажите название автомобиля на двух языках.")
        }
        guard !shortPhraseRu.isEmpty, !shortPhraseUz.isEmpty else {
            throw ASUAdminAPI.APIError.server(400, "Укажите короткую фразу на двух языках.")
        }
        guard !descriptionRu.isEmpty, !descriptionUz.isEmpty else {
            throw ASUAdminAPI.APIError.server(400, "Укажите подробное описание на двух языках.")
        }
        guard !brand.isEmpty, !model.isEmpty else {
            throw ASUAdminAPI.APIError.server(400, "Укажите марку и модель подарочного автомобиля.")
        }

        let year = try optionalInteger(draft.year, min: 2000, max: 2100, field: "год автомобиля")
        guard let minPurchase = try optionalInteger64(draft.minPurchaseAmount, min: 1, max: 1_000_000_000, field: "минимальную сумму покупки") else {
            throw ASUAdminAPI.APIError.server(400, "Укажите минимальную сумму покупки.")
        }
        let marketPrice = try optionalInteger64(draft.marketPrice, min: 1, max: 1_000_000_000, field: "рыночную цену")

        let instagram = try normalizedInstagram(draft.instagramUrl)
        let orderHref = try normalizedInternalHref(draft.orderHref) ?? "/compare/"

        let payload = GiftPayload(
            isActive: draft.isActive,
            titleRu: String(titleRu.prefix(160)),
            titleUz: String(titleUz.prefix(160)),
            subtitleRu: String(subtitleRu.prefix(160)),
            subtitleUz: String(subtitleUz.prefix(160)),
            shortPhraseRu: String(shortPhraseRu.prefix(240)),
            shortPhraseUz: String(shortPhraseUz.prefix(240)),
            descriptionRu: String(descriptionRu.prefix(4000)),
            descriptionUz: String(descriptionUz.prefix(4000)),
            brand: String(brand.prefix(120)),
            model: String(model.prefix(160)),
            year: year,
            trim: nullable(draft.trim, max: 160),
            exteriorColor: nullable(draft.exteriorColor, max: 120),
            interiorColor: nullable(draft.interiorColor, max: 120),
            minPurchaseAmount: minPurchase,
            marketPrice: marketPrice,
            currency: draft.currency,
            instagramUrl: instagram,
            orderHref: orderHref
        )

        let body = try JSONEncoder().encode(payload)
        let data = try await request(
            url: giftURL,
            method: "POST",
            token: token,
            body: body,
            contentType: "application/json; charset=utf-8"
        )
        let envelope: GiftEnvelope
        do { envelope = try JSONDecoder().decode(GiftEnvelope.self, from: data) }
        catch { throw ASUAdminAPI.APIError.invalidResponse }
        guard envelope.success == true, let gift = envelope.gift else {
            throw ASUAdminAPI.APIError.server(200, envelope.error ?? "Не удалось сохранить Ramadan Gift.")
        }
        return gift
    }

    func uploadMedia(
        giftID: Int,
        group: ASUAdminRamadanPhotoGroup,
        photo: ASUAdminPendingPhoto,
        sortOrder: Int,
        isCover: Bool,
        token: String
    ) async throws {
        guard !photo.data.isEmpty, photo.data.count <= 20 * 1024 * 1024 else {
            throw ASUAdminAPI.APIError.server(400, "Размер одной фотографии должен быть до 20 МБ.")
        }

        let boundary = "ASU-RAMADAN-\(UUID().uuidString)"
        var body = Data()
        func field(_ name: String, _ value: String) {
            body.append(Data("--\(boundary)\r\n".utf8))
            body.append(Data("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".utf8))
            body.append(Data("\(value)\r\n".utf8))
        }

        field("giftId", String(giftID))
        field("group", group.rawValue)
        field("sortOrder", String(max(0, sortOrder)))
        field("isCover", isCover ? "1" : "0")

        let filename = photo.filename
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")

        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".utf8))
        body.append(Data("Content-Type: \(photo.mimeType)\r\n\r\n".utf8))
        body.append(photo.data)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))

        let data = try await request(
            url: mediaURL,
            method: "POST",
            token: token,
            body: body,
            contentType: "multipart/form-data; boundary=\(boundary)",
            timeout: 90
        )
        let envelope = try? JSONDecoder().decode(MediaEnvelope.self, from: data)
        guard envelope?.success == true else {
            throw ASUAdminAPI.APIError.server(200, envelope?.error ?? "Не удалось загрузить фотографию Ramadan Gift.")
        }
    }

    func deleteMedia(id: Int, token: String) async throws {
        var components = URLComponents(url: mediaURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "id", value: String(id))]
        guard let url = components?.url else { throw ASUAdminAPI.APIError.invalidResponse }
        let data = try await request(url: url, method: "DELETE", token: token, body: nil, contentType: nil)
        let envelope = try? JSONDecoder().decode(MediaEnvelope.self, from: data)
        guard envelope?.success == true else {
            throw ASUAdminAPI.APIError.server(200, envelope?.error ?? "Не удалось удалить фотографию Ramadan Gift.")
        }
    }

    private func request(
        url: URL,
        method: String,
        token: String,
        body: Data?,
        contentType: String?,
        timeout: TimeInterval = 35
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = timeout
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("AutoSaleUmar-iOS-ControlSystem/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let body { request.httpBody = body }
        if let contentType { request.setValue(contentType, forHTTPHeaderField: "Content-Type") }

        let data: Data
        let response: URLResponse
        do { (data, response) = try await URLSession.shared.data(for: request) }
        catch { throw ASUAdminAPI.APIError.transport("Не удалось подключиться к Auto Sale Umar Control System.") }

        guard let http = response as? HTTPURLResponse else { throw ASUAdminAPI.APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode(ErrorEnvelope.self, from: data))?.error
            switch http.statusCode {
            case 401: throw ASUAdminAPI.APIError.unauthorized(message)
            case 403: throw ASUAdminAPI.APIError.forbidden(message)
            default: throw ASUAdminAPI.APIError.server(http.statusCode, message)
            }
        }
        return data
    }

    private func clean(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func nullable(_ value: String, max: Int) -> String? {
        let result = clean(value)
        return result.isEmpty ? nil : String(result.prefix(max))
    }

    private func optionalInteger(_ raw: String, min: Int, max: Int, field: String) throws -> Int? {
        let value = clean(raw)
        guard !value.isEmpty else { return nil }
        guard let number = Int(value), number >= min, number <= max else {
            throw ASUAdminAPI.APIError.server(400, "Проверьте \(field).")
        }
        return number
    }

    private func optionalInteger64(_ raw: String, min: Int64, max: Int64, field: String) throws -> Int64? {
        let value = clean(raw).replacingOccurrences(of: " ", with: "")
        guard !value.isEmpty else { return nil }
        guard let number = Int64(value), number >= min, number <= max else {
            throw ASUAdminAPI.APIError.server(400, "Проверьте \(field).")
        }
        return number
    }

    private func normalizedInstagram(_ raw: String) throws -> String? {
        let value = clean(raw)
        guard !value.isEmpty else { return nil }
        let candidate = value.lowercased().hasPrefix("http://") || value.lowercased().hasPrefix("https://") ? value : "https://\(value)"
        guard var components = URLComponents(string: candidate),
              let host = components.host?.lowercased(),
              host == "instagram.com" || host.hasSuffix(".instagram.com") else {
            throw ASUAdminAPI.APIError.server(400, "Проверьте ссылку Instagram.")
        }
        components.scheme = "https"
        guard let normalized = components.url?.absoluteString else {
            throw ASUAdminAPI.APIError.server(400, "Проверьте ссылку Instagram.")
        }
        return String(normalized.prefix(500))
    }

    private func normalizedInternalHref(_ raw: String) throws -> String? {
        let value = clean(raw)
        guard !value.isEmpty else { return nil }
        guard value.hasPrefix("/") else {
            throw ASUAdminAPI.APIError.server(400, "Ссылка кнопки должна начинаться с /.")
        }
        return String(value.prefix(500))
    }
}

enum ASUAdminRamadanMediaURL {
    static func resolve(_ rawValue: String) -> URL? {
        let raw = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }
        if let absolute = URL(string: raw), absolute.scheme != nil { return absolute }
        if raw.hasPrefix("/") {
            return URL(string: raw, relativeTo: AppConfig.website)?.absoluteURL
        }
        return AppConfig.website.appending(path: raw)
    }

    static func isManaged(_ media: RamadanGiftMedia) -> Bool {
        media.publicUrl.contains("/api/ramadan-gift-media")
    }
}
