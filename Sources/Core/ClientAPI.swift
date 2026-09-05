import Foundation

struct ClientAPI {
    enum APIError: LocalizedError {
        case unavailable
        case server(Int, String?)
        case malformed
        case validation(String)

        var errorDescription: String? {
            switch self {
            case .unavailable:
                return "Сервис временно недоступен."
            case .server(_, let message):
                return message ?? "Сервис временно недоступен."
            case .malformed:
                return "Сервер вернул некорректный ответ."
            case .validation(let message):
                return message
            }
        }
    }

    private struct VehicleRequestEnvelope: Decodable {
        let success: Bool?
        let error: String?
        let request: VehicleRequestReceipt?
    }

    private struct VisitEnvelope: Decodable {
        let success: Bool?
        let error: String?
        let visit: VisitReceipt?
    }

    private struct CompareAvailabilityEnvelope: Decodable {
        let success: Bool?
        let available: Bool?
        let reason: String?
    }

    private struct CompareEnvelope: Decodable {
        let success: Bool?
        let error: String?
        let code: String?
        let quota: CompareQuota?
        let result: CompareAIResult?
    }

    private struct CompareRequest: Encodable {
        let action: CompareAIAction
        let slugs: [String]
        let criteria: [AdviceCriterion]
        let note: String
        let budget: Double?
        let budgetCurrency: ASUCurrency
        let language: String
    }

    private struct GiftEnvelope: Decodable {
        let success: Bool?
        let error: String?
        let gift: RamadanGift?
    }

    func submitVehicleRequest(_ draft: VehicleRequestDraft) async throws -> VehicleRequestReceipt {
        let data = try await postJSON(url: AppConfig.vehicleRequestsURL, payload: draft)
        let envelope = try decode(VehicleRequestEnvelope.self, from: data)
        guard envelope.success == true, let receipt = envelope.request else {
            throw APIError.validation(envelope.error ?? "Не удалось отправить запрос.")
        }
        return receipt
    }

    func submitVisit(_ draft: VisitDraft) async throws -> VisitReceipt {
        let data = try await postJSON(url: AppConfig.visitsURL, payload: draft)
        let envelope = try decode(VisitEnvelope.self, from: data)
        guard envelope.success == true, let receipt = envelope.visit else {
            throw APIError.validation(envelope.error ?? "Не удалось забронировать визит.")
        }
        return receipt
    }

    func compareAvailability() async -> CompareAIAvailability {
        do {
            let data = try await requestData(url: AppConfig.compareAIURL, method: "GET", body: nil, browserHeaders: true)
            let envelope = try decode(CompareAvailabilityEnvelope.self, from: data)
            return CompareAIAvailability(available: envelope.available ?? false, reason: envelope.reason)
        } catch {
            return CompareAIAvailability(available: false, reason: nil)
        }
    }

    func compare(
        action: CompareAIAction,
        cars: [Car],
        criteria: [AdviceCriterion],
        note: String,
        budget: Double?,
        currency: ASUCurrency,
        language: AppLanguage
    ) async throws -> (CompareAIResult, CompareQuota?) {
        let slugs = cars.compactMap(\.slug)
        guard slugs.count >= 2 else { throw APIError.validation("Выберите минимум два автомобиля.") }

        let payload = CompareRequest(
            action: action,
            slugs: Array(slugs.prefix(3)),
            criteria: criteria,
            note: note,
            budget: budget,
            budgetCurrency: currency,
            language: language == .ru ? "ru" : "uz"
        )
        let body = try JSONEncoder().encode(payload)
        let data = try await requestData(url: AppConfig.compareAIURL, method: "POST", body: body, browserHeaders: true)
        let envelope = try decode(CompareEnvelope.self, from: data)
        guard envelope.success == true, let result = envelope.result else {
            throw APIError.validation(envelope.error ?? "Консультант временно недоступен.")
        }
        return (result, envelope.quota)
    }

    func fetchRamadanGift() async throws -> RamadanGift? {
        let data = try await requestData(url: AppConfig.ramadanGiftURL, method: "GET", body: nil)
        let envelope = try decode(GiftEnvelope.self, from: data)
        guard envelope.success == true else {
            throw APIError.validation(envelope.error ?? "Ramadan Gift временно недоступен.")
        }
        guard let gift = envelope.gift, gift.isActive else { return nil }
        return gift
    }

    private func postJSON<T: Encodable>(url: URL, payload: T) async throws -> Data {
        let body = try JSONEncoder().encode(payload)
        return try await requestData(url: url, method: "POST", body: body)
    }

    private func requestData(url: URL, method: String, body: Data?, browserHeaders: Bool = false) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = 20
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("AutoSaleUmar-iOS/3.0", forHTTPHeaderField: "User-Agent")
        if body != nil { request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        if browserHeaders {
            request.setValue("https://autosaleumar.com", forHTTPHeaderField: "Origin")
            request.setValue("https://autosaleumar.com/compare/", forHTTPHeaderField: "Referer")
            request.setValue(Persistence.browserID(), forHTTPHeaderField: "x-asu-browser-id")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.unavailable }
            guard (200..<300).contains(http.statusCode) else {
                let message = decodeServerError(from: data)
                throw APIError.server(http.statusCode, message)
            }
            return data
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.unavailable
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do { return try JSONDecoder().decode(type, from: data) }
        catch { throw APIError.malformed }
    }

    private func decodeServerError(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return object["error"] as? String
    }
}
