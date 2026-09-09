import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension ASUAdminAPI {
    private struct FullCarEnvelope: Decodable {
        let success: Bool?
        let error: String?
        let car: ASUAdminCarDetailPayload?
    }

    private struct CreatedCarEnvelope: Decodable {
        struct CreatedCar: Decodable {
            let id: Int?
            let brand: String?
            let model: String?
            let variants: [ASUAdminSavedVariant]?
        }

        let success: Bool?
        let error: String?
        let car: CreatedCar?
    }

    private struct SavedCarEnvelope: Decodable {
        let success: Bool?
        let error: String?
        let car: ASUAdminCarDetailPayload?
        let variants: [ASUAdminSavedVariant]?
    }

    private struct AIEnvelope: Decodable {
        let success: Bool?
        let error: String?
        let model: String?
        let car: ASUAdminCarAIResult?
    }

    private struct MediaEnvelope: Decodable {
        struct Media: Decodable {
            let id: Int
            let carId: Int
            let variantId: Int
            let group: ASUAdminPhotoGroup
            let publicUrl: String
            let isCover: Bool
        }

        let success: Bool?
        let error: String?
        let media: Media?
    }

    private struct GenericEnvelope: Decodable {
        let success: Bool?
        let error: String?
    }

    private struct AIPayload: Encodable {
        let text: String
    }

    private struct PublishPayload: Encodable {
        let id: Int
        let isPublic: Bool
    }

    func fullCarDetail(id: Int, token: String) async throws -> ASUAdminCarDetailPayload {
        var components = URLComponents(url: AppConfig.website.appending(path: "api/car-detail"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "id", value: String(id))]
        guard let url = components?.url else { throw APIError.invalidResponse }

        let data = try await asuAdminRequest(url: url, method: "GET", token: token, body: nil, contentType: nil)
        let envelope: FullCarEnvelope
        do {
            envelope = try JSONDecoder().decode(FullCarEnvelope.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
        guard envelope.success == true, let car = envelope.car else {
            throw APIError.server(200, envelope.error ?? "Не удалось загрузить автомобиль.")
        }
        return car
    }

    func createFullCar(payload: ASUAdminCarSavePayload, token: String) async throws -> ASUAdminCarPersistenceReceipt {
        let data = try JSONEncoder().encode(payload)
        let response = try await asuAdminRequest(
            url: AppConfig.website.appending(path: "api/cars"),
            method: "POST",
            token: token,
            body: data,
            contentType: "application/json; charset=utf-8"
        )

        let envelope: CreatedCarEnvelope
        do {
            envelope = try JSONDecoder().decode(CreatedCarEnvelope.self, from: response)
        } catch {
            throw APIError.invalidResponse
        }

        guard envelope.success == true,
              let car = envelope.car,
              let carID = car.id else {
            throw APIError.server(200, envelope.error ?? "Не удалось добавить автомобиль.")
        }

        let title = [car.brand, car.model]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return ASUAdminCarPersistenceReceipt(
            carID: carID,
            title: title.isEmpty ? "ID \(carID)" : title,
            variants: car.variants ?? []
        )
    }

    func saveFullCar(payload: ASUAdminCarSavePayload, token: String) async throws -> ASUAdminCarPersistenceReceipt {
        guard let carID = payload.id else { throw APIError.invalidResponse }
        let data = try JSONEncoder().encode(payload)
        let response = try await asuAdminRequest(
            url: AppConfig.website.appending(path: "api/car-detail"),
            method: "PATCH",
            token: token,
            body: data,
            contentType: "application/json; charset=utf-8"
        )

        let envelope: SavedCarEnvelope
        do {
            envelope = try JSONDecoder().decode(SavedCarEnvelope.self, from: response)
        } catch {
            throw APIError.invalidResponse
        }

        guard envelope.success == true else {
            throw APIError.server(200, envelope.error ?? "Не удалось сохранить изменения автомобиля.")
        }

        let title: String
        if let car = envelope.car {
            title = "\(car.brand) \(car.model)"
        } else {
            title = "ID \(carID)"
        }

        return ASUAdminCarPersistenceReceipt(
            carID: carID,
            title: title,
            variants: envelope.variants ?? []
        )
    }

    func publishFullCar(id: Int, isPublic: Bool, token: String) async throws {
        let data = try JSONEncoder().encode(PublishPayload(id: id, isPublic: isPublic))
        let response = try await asuAdminRequest(
            url: AppConfig.website.appending(path: "api/cars"),
            method: "PATCH",
            token: token,
            body: data,
            contentType: "application/json; charset=utf-8"
        )
        let envelope = try? JSONDecoder().decode(GenericEnvelope.self, from: response)
        if envelope?.success != true {
            throw APIError.server(200, envelope?.error ?? "Не удалось изменить публикацию автомобиля.")
        }
    }

    func carAIAutofill(text: String, token: String) async throws -> ASUAdminCarAIResponse {
        let source = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard source.count >= 20 else {
            throw APIError.server(400, "Вставьте текст с данными автомобиля.")
        }
        guard source.count <= 180_000 else {
            throw APIError.server(413, "Текст слишком большой. Максимум 180 000 символов.")
        }

        let data = try JSONEncoder().encode(AIPayload(text: source))
        let response = try await asuAdminRequest(
            url: AppConfig.website.appending(path: "api/car-ai"),
            method: "POST",
            token: token,
            body: data,
            contentType: "application/json; charset=utf-8",
            timeout: 90
        )

        let envelope: AIEnvelope
        do {
            envelope = try JSONDecoder().decode(AIEnvelope.self, from: response)
        } catch {
            throw APIError.invalidResponse
        }
        guard envelope.success == true, let result = envelope.car else {
            throw APIError.server(200, envelope.error ?? "Не удалось выполнить умное автозаполнение.")
        }
        return ASUAdminCarAIResponse(model: envelope.model, result: result)
    }

    func uploadCarMedia(
        carID: Int,
        variantID: Int,
        group: ASUAdminPhotoGroup,
        photo: ASUAdminPendingPhoto,
        sortOrder: Int,
        isCover: Bool,
        token: String
    ) async throws -> ASUAdminUploadedMedia {
        guard !photo.data.isEmpty, photo.data.count <= 20 * 1024 * 1024 else {
            throw APIError.server(400, "Размер одной фотографии должен быть до 20 МБ.")
        }

        let boundary = "ASU-\(UUID().uuidString)"
        let safeFilename = photo.filename
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")

        var body = Data()
        func appendField(_ name: String, _ value: String) {
            body.append(Data("--\(boundary)\r\n".utf8))
            body.append(Data("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".utf8))
            body.append(Data("\(value)\r\n".utf8))
        }

        appendField("carId", String(carID))
        appendField("variantId", String(variantID))
        appendField("group", group.rawValue)
        appendField("sortOrder", String(sortOrder))
        appendField("isCover", isCover ? "1" : "0")

        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"file\"; filename=\"\(safeFilename)\"\r\n".utf8))
        body.append(Data("Content-Type: \(photo.mimeType)\r\n\r\n".utf8))
        body.append(photo.data)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))

        let response = try await asuAdminRequest(
            url: AppConfig.website.appending(path: "api/car-media"),
            method: "POST",
            token: token,
            body: body,
            contentType: "multipart/form-data; boundary=\(boundary)",
            timeout: 90
        )

        let envelope: MediaEnvelope
        do {
            envelope = try JSONDecoder().decode(MediaEnvelope.self, from: response)
        } catch {
            throw APIError.invalidResponse
        }
        guard envelope.success == true, let media = envelope.media else {
            throw APIError.server(200, envelope.error ?? "Не удалось загрузить фотографию.")
        }

        return ASUAdminUploadedMedia(
            id: media.id,
            carID: media.carId,
            variantID: media.variantId,
            group: media.group,
            publicURL: media.publicUrl,
            isCover: media.isCover,
            sortOrder: sortOrder
        )
    }

    func deleteCarMedia(id: Int, token: String) async throws {
        var components = URLComponents(url: AppConfig.website.appending(path: "api/car-media"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "id", value: String(id))]
        guard let url = components?.url else { throw APIError.invalidResponse }

        let response = try await asuAdminRequest(url: url, method: "DELETE", token: token, body: nil, contentType: nil)
        let envelope = try? JSONDecoder().decode(GenericEnvelope.self, from: response)
        if envelope?.success != true {
            throw APIError.server(200, envelope?.error ?? "Не удалось удалить фотографию.")
        }
    }

    private func asuAdminRequest(
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
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.transport("Не удалось подключиться к Auto Sale Umar Control System.")
        }

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode(GenericEnvelope.self, from: data))?.error
            switch http.statusCode {
            case 401:
                throw APIError.unauthorized(message)
            case 403:
                throw APIError.forbidden(message)
            default:
                throw APIError.server(http.statusCode, message)
            }
        }
        return data
    }
}
