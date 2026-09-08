import Foundation
import SwiftUI

@MainActor
final class ASUAdminSessionStore: ObservableObject {
    @Published private(set) var user: ASUAdminUser?
    @Published private(set) var isRestoring = true
    @Published private(set) var isAuthenticating = false
    @Published private(set) var sessionNotice: String?
    @Published var loginError: String?

    private let api = ASUAdminAPI()
    private var session: ASUAdminSession?
    private var didRestore = false

    var isSignedIn: Bool { user != nil && session != nil }
    var bearerToken: String? { session?.token }

    func restoreIfNeeded(force: Bool = false) async {
        if didRestore && !force { return }
        didRestore = true
        isRestoring = true
        defer { isRestoring = false }

        guard let stored = ASUAdminKeychain.load() else {
            user = nil
            session = nil
            return
        }

        guard !stored.session.isExpired else {
            ASUAdminKeychain.clear()
            user = nil
            session = nil
            sessionNotice = "Срок защищённой сессии истёк. Войдите снова."
            return
        }

        do {
            let verifiedUser = try await api.me(token: stored.session.token)
            session = stored.session
            user = verifiedUser
            sessionNotice = nil
            try? ASUAdminKeychain.save(ASUStoredAdminSession(session: stored.session, user: verifiedUser))
        } catch let error as ASUAdminAPI.APIError {
            if error.shouldDiscardSession {
                ASUAdminKeychain.clear()
            }
            user = nil
            session = nil
            sessionNotice = error.localizedDescription
        } catch {
            user = nil
            session = nil
            sessionNotice = "Не удалось проверить защищённую сессию."
        }
    }

    @discardableResult
    func login(email: String, password: String) async -> Bool {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanEmail.isEmpty, !password.isEmpty else {
            loginError = "Введите почту и пароль."
            return false
        }

        isAuthenticating = true
        loginError = nil
        sessionNotice = nil
        defer { isAuthenticating = false }

        do {
            let stored = try await api.login(email: cleanEmail, password: password)
            do {
                try ASUAdminKeychain.save(stored)
            } catch {
                await api.logout(token: stored.session.token)
                loginError = "Не удалось сохранить защищённую сессию на этом iPhone."
                return false
            }
            session = stored.session
            user = stored.user
            return true
        } catch {
            loginError = error.localizedDescription
            return false
        }
    }

    func signOut() async {
        let token = session?.token
        user = nil
        session = nil
        loginError = nil
        sessionNotice = nil
        ASUAdminKeychain.clear()

        if let token {
            await api.logout(token: token)
        }
    }

    func clearLoginError() {
        loginError = nil
    }
}
