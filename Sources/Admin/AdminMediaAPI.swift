import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct ASUAdminMediaAPI {
    private struct ErrorEnvelope: Decodable {
        let success: Bool?
        let error: String?
    }

    private struct BrandEnvelope: Decodable {
        let success: Bool?
        let error: String?
        let brand: String?
        let maxCovers: Int?
        let images: [ASUAdminBrandCover]?
        let image: ASUAdminBrandCover?
    }

    private struct HomeEnvelope: Decodable {
        let success: Bool?
        let error: String?
        let videos: [ASUAdminHomeVideo]?
        let video: ASUAdminHomeVideo?
    }

    private struct HomePatchPayload: Encodable {
        let key: String
        let brand: String
        let model: String
        let price: Int64?
        let currency: ASUAdminMediaCurrency
        let priceOnRequest: Bool
        let status: ASUAdminHomeVideoStatus
    }

    private var website: URL { AppConfig.website }
    private var brandMediaURL: URL { website.appending(path: "api/brand-media") }
    private var homeMediaURL: URL { website.appending(path: "api/home-media") }

    func brandCovers(brand: String, token: String) async throws -> ASUAdminBrandCoverSnapshot {
        var components = URLComponents(url: brandMediaURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "brand", value: brand)]
        guard let url = components?.url else { throw ASUAdminAPI.APIError.invalidResponse }

        let data = try await request(url: url, method: "GET", token: token, body: nil, contentType: nil)
        let envelope: BrandEnvelope
        do {
            envelope = try JSONDecoder().decode(BrandEnvelope.self, from: data)
        } catch {
            throw ASUAdminAPI.APIError.invalidResponse
        }
        guard envelope.success == true else {
            throw ASUAdminAPI.APIError.server(200, envelope.error ?? "Не удалось загрузить обложки марки.")
        }
        return ASUAdminBrandCoverSnapshot(
            brand: envelope.brand ?? brand,
            maxCovers: envelope.maxCovers ?? 3,
            images: envelope.images ?? []
        )
    }

    func uploadBrandCover(
        brand: String,
        data: Data,
        filename: String,
        mimeType: String = "image/jpeg",
        token: String
    ) async throws -> ASUAdminBrandCover {
        guard !data.isEmpty, data.count <= 20 * 1024 * 1024 else {
            throw ASUAdminAPI.APIError.server(400, "Размер одной обложки должен быть до 20 МБ.")
        }

        let boundary = "ASU-BRAND-\(UUID().uuidString)"
        var body = Data()
        appendField(name: "brand", value: brand, boundary: boundary, to: &body)

        let safeFilename = sanitizeFilename(filename)
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"file\"; filename=\"\(safeFilename)\"\r\n".utf8))
        body.append(Data("Content-Type: \(mimeType)\r\n\r\n".utf8))
        body.append(data)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))

        let response = try await request(
            url: brandMediaURL,
            method: "POST",
            token: token,
            body: body,
            contentType: "multipart/form-data; boundary=\(boundary)",
            timeout: 90
        )
        let envelope: BrandEnvelope
        do {
            envelope = try JSONDecoder().decode(BrandEnvelope.self, from: response)
        } catch {
            throw ASUAdminAPI.APIError.invalidResponse
        }
        guard envelope.success == true, let image = envelope.image else {
            throw ASUAdminAPI.APIError.server(200, envelope.error ?? "Не удалось загрузить обложку.")
        }
        return image
    }

    func deleteBrandCover(key: String, token: String) async throws {
        var components = URLComponents(url: brandMediaURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "key", value: key)]
        guard let url = components?.url else { throw ASUAdminAPI.APIError.invalidResponse }
        let data = try await request(url: url, method: "DELETE", token: token, body: nil, contentType: nil)
        let envelope = try? JSONDecoder().decode(ErrorEnvelope.self, from: data)
        guard envelope?.success == true else {
            throw ASUAdminAPI.APIError.server(200, envelope?.error ?? "Не удалось удалить обложку.")
        }
    }

    func homeVideos(token: String) async throws -> [ASUAdminHomeVideo] {
        let data = try await request(url: homeMediaURL, method: "GET", token: token, body: nil, contentType: nil)
        let envelope: HomeEnvelope
        do {
            envelope = try JSONDecoder().decode(HomeEnvelope.self, from: data)
        } catch {
            throw ASUAdminAPI.APIError.invalidResponse
        }
        guard envelope.success == true else {
            throw ASUAdminAPI.APIError.server(200, envelope.error ?? "Не удалось загрузить видео главной страницы.")
        }
        return envelope.videos ?? []
    }

    func uploadHomeVideo(fileURL: URL, token: String) async throws -> ASUAdminHomeVideo {
        let values = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
        guard values.isRegularFile == true else {
            throw ASUAdminAPI.APIError.server(400, "Выбранный файл недоступен.")
        }
        let size = values.fileSize ?? 0
        guard size > 0, size <= 80 * 1024 * 1024 else {
            throw ASUAdminAPI.APIError.server(400, "Размер одного видео должен быть до 80 МБ.")
        }

        let ext = fileURL.pathExtension.lowercased()
        guard ["mp4", "mov", "webm"].contains(ext) else {
            throw ASUAdminAPI.APIError.server(400, "Разрешены MP4, WebM и MOV. Для iPhone рекомендуется MP4.")
        }

        let boundary = "ASU-HOME-\(UUID().uuidString)"
        let multipartURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("asu-home-upload-\(UUID().uuidString).multipart")
        defer { try? FileManager.default.removeItem(at: multipartURL) }

        _ = FileManager.default.createFile(atPath: multipartURL.path, contents: nil)
        let output = try FileHandle(forWritingTo: multipartURL)
        defer { try? output.close() }

        try writeField(name: "status", value: ASUAdminHomeVideoStatus.inShowroom.rawValue, boundary: boundary, to: output)
        try writeField(name: "currency", value: ASUAdminMediaCurrency.USD.rawValue, boundary: boundary, to: output)
        try writeField(name: "priceOnRequest", value: "1", boundary: boundary, to: output)

        let filename = sanitizeFilename(fileURL.lastPathComponent)
        let mimeType = mimeTypeForVideoExtension(ext)
        try output.write(contentsOf: Data("--\(boundary)\r\n".utf8))
        try output.write(contentsOf: Data("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".utf8))
        try output.write(contentsOf: Data("Content-Type: \(mimeType)\r\n\r\n".utf8))
        try streamFile(fileURL, to: output)
        try output.write(contentsOf: Data("\r\n--\(boundary)--\r\n".utf8))
        try output.synchronize()

        var request = baseRequest(
            url: homeMediaURL,
            method: "POST",
            token: token,
            contentType: "multipart/form-data; boundary=\(boundary)",
            timeout: 180
        )
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.upload(for: request, fromFile: multipartURL)
        } catch {
            throw ASUAdminAPI.APIError.transport("Не удалось загрузить видео в Auto Sale Umar Control System.")
        }
        try validate(response: response, data: data)

        let envelope: HomeEnvelope
        do {
            envelope = try JSONDecoder().decode(HomeEnvelope.self, from: data)
        } catch {
            throw ASUAdminAPI.APIError.invalidResponse
        }
        guard envelope.success == true, let video = envelope.video else {
            throw ASUAdminAPI.APIError.server(200, envelope.error ?? "Не удалось загрузить видео.")
        }
        return video
    }

    func saveHomeVideo(_ video: ASUAdminHomeVideo, token: String) async throws -> ASUAdminHomeVideo {
        let payload = HomePatchPayload(
            key: video.key,
            brand: video.brand,
            model: video.model,
            price: video.priceOnRequest ? nil : video.price,
            currency: video.currency,
            priceOnRequest: video.priceOnRequest,
            status: video.status
        )
        let body = try JSONEncoder().encode(payload)
        let data = try await request(
            url: homeMediaURL,
            method: "PATCH",
            token: token,
            body: body,
            contentType: "application/json; charset=utf-8"
        )
        let envelope: HomeEnvelope
        do {
            envelope = try JSONDecoder().decode(HomeEnvelope.self, from: data)
        } catch {
            throw ASUAdminAPI.APIError.invalidResponse
        }
        guard envelope.success == true, let updated = envelope.video else {
            throw ASUAdminAPI.APIError.server(200, envelope.error ?? "Не удалось сохранить подпись видео.")
        }
        return updated
    }

    func deleteHomeVideo(key: String, token: String) async throws {
        var components = URLComponents(url: homeMediaURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "key", value: key)]
        guard let url = components?.url else { throw ASUAdminAPI.APIError.invalidResponse }
        let data = try await request(url: url, method: "DELETE", token: token, body: nil, contentType: nil)
        let envelope = try? JSONDecoder().decode(ErrorEnvelope.self, from: data)
        guard envelope?.success == true else {
            throw ASUAdminAPI.APIError.server(200, envelope?.error ?? "Не удалось удалить видео.")
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
        var request = baseRequest(url: url, method: method, token: token, contentType: contentType, timeout: timeout)
        if let body { request.httpBody = body }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ASUAdminAPI.APIError.transport("Не удалось подключиться к Auto Sale Umar Control System.")
        }
        try validate(response: response, data: data)
        return data
    }

    private func baseRequest(
        url: URL,
        method: String,
        token: String,
        contentType: String?,
        timeout: TimeInterval
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = timeout
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("AutoSaleUmar-iOS-ControlSystem/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let contentType { request.setValue(contentType, forHTTPHeaderField: "Content-Type") }
        return request
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw ASUAdminAPI.APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode(ErrorEnvelope.self, from: data))?.error
            switch http.statusCode {
            case 401:
                throw ASUAdminAPI.APIError.unauthorized(message)
            case 403:
                throw ASUAdminAPI.APIError.forbidden(message)
            default:
                throw ASUAdminAPI.APIError.server(http.statusCode, message)
            }
        }
    }

    private func appendField(name: String, value: String, boundary: String, to body: inout Data) {
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".utf8))
        body.append(Data("\(value)\r\n".utf8))
    }

    private func writeField(name: String, value: String, boundary: String, to output: FileHandle) throws {
        try output.write(contentsOf: Data("--\(boundary)\r\n".utf8))
        try output.write(contentsOf: Data("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".utf8))
        try output.write(contentsOf: Data("\(value)\r\n".utf8))
    }

    private func streamFile(_ sourceURL: URL, to output: FileHandle) throws {
        guard let input = InputStream(url: sourceURL) else {
            throw ASUAdminAPI.APIError.server(400, "Не удалось прочитать видеофайл.")
        }
        input.open()
        defer { input.close() }

        let bufferSize = 1024 * 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while input.hasBytesAvailable {
            let count = input.read(buffer, maxLength: bufferSize)
            if count < 0 {
                throw input.streamError ?? ASUAdminAPI.APIError.server(400, "Не удалось прочитать видеофайл.")
            }
            if count == 0 { break }
            try output.write(contentsOf: Data(bytes: buffer, count: count))
        }
    }

    private func sanitizeFilename(_ value: String) -> String {
        let clean = value
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? "media.bin" : String(clean.prefix(160))
    }

    private func mimeTypeForVideoExtension(_ ext: String) -> String {
        switch ext.lowercased() {
        case "mov": return "video/quicktime"
        case "webm": return "video/webm"
        default: return "video/mp4"
        }
    }
}
