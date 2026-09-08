import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct ASUAdminAPI {
    enum APIError: LocalizedError {
        case invalidResponse
        case unauthorized(String?)
        case forbidden(String?)
        case server(Int, String?)
        case transport(String)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Сервер вернул некорректный ответ."
            case .unauthorized(let message):
                return message ?? "Неверная почта или пароль."
            case .forbidden(let message):
                return message ?? "Для этой учётной записи нет доступа."
            case .server(_, let message):
                return message ?? "Control System временно недоступна."
            case .transport(let message):
                return message
            }
        }

        var shouldDiscardSession: Bool {
            if case .unauthorized = self { return true }
            return false
        }
    }

    private struct ErrorEnvelope: Decodable {
        let success: Bool?
        let error: String?
    }

    private struct LoginPayload: Encodable {
        let email: String
        let password: String
        let client = "mobile"
    }

    private struct LoginEnvelope: Decodable {
        struct LoginUser: Decodable {
            let id: Int
            let email: String
            let fullName: String
            let role: ASUAdminRole
        }

        let success: Bool?
        let error: String?
        let user: LoginUser?
        let session: ASUAdminSession?
    }

    private struct MeEnvelope: Decodable {
        let success: Bool?
        let error: String?
        let user: ASUAdminUser?
    }

    private var website: URL { AppConfig.website }
    private var loginURL: URL { website.appending(path: "api/login") }
    private var meURL: URL { website.appending(path: "api/me") }
    private var logoutURL: URL { website.appending(path: "api/logout") }

    func login(email: String, password: String) async throws -> ASUStoredAdminSession {
        let payload = LoginPayload(email: email, password: password)
        let body = try JSONEncoder().encode(payload)
        let data = try await request(url: loginURL, method: "POST", token: nil, body: body)

        let envelope: LoginEnvelope
        do {
            envelope = try JSONDecoder().decode(LoginEnvelope.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }

        guard envelope.success == true,
              let user = envelope.user,
              let session = envelope.session,
              !session.token.isEmpty else {
            throw APIError.unauthorized(envelope.error)
        }

        return ASUStoredAdminSession(
            session: session,
            user: ASUAdminUser(
                id: user.id,
                email: user.email,
                fullName: user.fullName,
                phone: nil,
                role: user.role
            )
        )
    }

    func me(token: String) async throws -> ASUAdminUser {
        let data = try await request(url: meURL, method: "GET", token: token, body: nil)
        let envelope: MeEnvelope
        do {
            envelope = try JSONDecoder().decode(MeEnvelope.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
        guard envelope.success == true, let user = envelope.user else {
            throw APIError.unauthorized(envelope.error)
        }
        return user
    }

    func logout(token: String) async {
        _ = try? await request(url: logoutURL, method: "POST", token: token, body: nil)
    }

    func authorizedData(path: String, method: String = "GET", token: String, body: Data? = nil) async throws -> Data {
        let clean = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return try await request(url: website.appending(path: clean), method: method, token: token, body: body)
    }

    private func request(url: URL, method: String, token: String?, body: Data?) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("AutoSaleUmar-iOS-ControlSystem/1.0", forHTTPHeaderField: "User-Agent")

        if let body {
            request.httpBody = body
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
        if let token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.transport("Не удалось подключиться к Auto Sale Umar Control System.")
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode(ErrorEnvelope.self, from: data))?.error
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
