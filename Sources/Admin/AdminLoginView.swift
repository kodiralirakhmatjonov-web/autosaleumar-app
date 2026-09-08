import SwiftUI
import UIKit

struct ASUAdminLoginView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var session: ASUAdminSessionStore
    let close: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var revealsPassword = false
    @FocusState private var focus: Field?

    private enum Field: Hashable {
        case email
        case password
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                topBar
                    .padding(.bottom, 30)

                identity
                    .padding(.bottom, 34)

                loginCard

                securityNote
                    .padding(.top, 18)

                Text("AUTO SALE UMAR · CONTROL SYSTEM")
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .tracking(1.3)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 30)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(ASUDesign.page)
        .onChange(of: email) { _, _ in session.clearLoginError() }
        .onChange(of: password) { _, _ in session.clearLoginError() }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Image(colorScheme == .dark ? "WordmarkWhite" : "WordmarkBlack")
                .resizable()
                .scaledToFit()
                .frame(width: 154, alignment: .leading)
            Spacer()
            ASUGlassIconButton(
                symbol: "xmark",
                size: 44,
                fontSize: 15,
                accessibilityLabel: L10n.t("Закрыть", "Yopish", settings.language),
                action: close
            )
        }
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "lock.shield")
                Text("CONTROL SYSTEM")
            }
            .font(.system(size: 10.5, weight: .bold, design: .rounded))
            .tracking(1.25)
            .foregroundStyle(.secondary)

            Text(L10n.t("Войти как\nсотрудник.", "Xodim sifatida\nkiring.", settings.language))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .tracking(-1.6)
                .lineSpacing(-4)

            Text(L10n.t(
                "Используйте ту же почту и тот же пароль, что в веб-панели Auto Sale Umar. После входа откроется ваша роль и доступные разделы системы управления.",
                "Auto Sale Umar veb boshqaruv panelidagi ayni email va paroldan foydalaning. Kirgandan so‘ng rolingiz va ruxsat berilgan bo‘limlar ochiladi.",
                settings.language
            ))
            .font(.system(size: 15))
            .foregroundStyle(.secondary)
            .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var loginCard: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                fieldLabel(L10n.t("Почта сотрудника", "Xodim emaili", settings.language))
                emailField
            }

            VStack(alignment: .leading, spacing: 8) {
                fieldLabel(L10n.t("Пароль", "Parol", settings.language))
                passwordField
            }

            if let message = session.loginError ?? session.sessionNotice, !message.isEmpty {
                VStack(alignment: .leading, spacing: 9) {
                    HStack(alignment: .top, spacing: 9) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text(message)
                            .font(.system(size: 12.5, weight: .medium, design: .rounded))
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    if session.loginError == nil, session.sessionNotice != nil {
                        Button(L10n.t("Проверить сессию снова", "Sessiyani qayta tekshirish", settings.language)) {
                            Task { await session.restoreIfNeeded(force: true) }
                        }
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .buttonStyle(.plain)
                    }
                }
                .foregroundStyle(.red)
                .padding(12)
                .background(Color.red.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Button {
                Task { await performLogin() }
            } label: {
                HStack(spacing: 10) {
                    if session.isAuthenticating {
                        ProgressView()
                            .controlSize(.small)
                            .tint(Color(uiColor: .systemBackground))
                    } else {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    Text(session.isAuthenticating
                         ? L10n.t("Проверяем доступ…", "Kirish tekshirilmoqda…", settings.language)
                         : L10n.t("Войти в Control System", "Control Systemga kirish", settings.language))
                }
            }
            .buttonStyle(ASUPrimaryButtonStyle())
            .disabled(session.isAuthenticating || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)
            .opacity(session.isAuthenticating || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty ? 0.62 : 1)
        }
        .padding(18)
        .asuCard(radius: 30)
    }

    private var emailField: some View {
        HStack(spacing: 11) {
            Image(systemName: "envelope")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
            TextField("name@autosaleumar.com", text: $email)
                .font(.system(size: 15.5, design: .rounded))
                .keyboardType(.emailAddress)
                .textContentType(.username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focus, equals: .email)
                .submitLabel(.next)
                .onSubmit { focus = .password }
        }
        .padding(.horizontal, 15)
        .frame(height: 54)
        .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))
    }

    private var passwordField: some View {
        HStack(spacing: 11) {
            Image(systemName: "key")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)

            Group {
                if revealsPassword {
                    TextField(L10n.t("Пароль", "Parol", settings.language), text: $password)
                } else {
                    SecureField(L10n.t("Пароль", "Parol", settings.language), text: $password)
                }
            }
            .font(.system(size: 15.5, design: .rounded))
            .textContentType(.password)
            .focused($focus, equals: .password)
            .submitLabel(.go)
            .onSubmit { Task { await performLogin() } }

            Button {
                revealsPassword.toggle()
            } label: {
                Image(systemName: revealsPassword ? "eye.slash" : "eye")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(revealsPassword ? L10n.t("Скрыть пароль", "Parolni yashirish", settings.language) : L10n.t("Показать пароль", "Parolni ko‘rsatish", settings.language))
        }
        .padding(.horizontal, 15)
        .frame(height: 54)
        .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))
    }

    private var securityNote: some View {
        HStack(alignment: .top, spacing: 12) {
            ASUGlassCircleSurface(size: 42) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 16, weight: .semibold))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.t("Защищённая мобильная сессия", "Himoyalangan mobil sessiya", settings.language))
                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                Text(L10n.t(
                    "Пароль не сохраняется. После входа токен сессии хранится только в защищённом Keychain этого iPhone.",
                    "Parol saqlanmaydi. Kirgandan keyin sessiya tokeni faqat ushbu iPhone Keychain himoyalangan xotirasida saqlanadi.",
                    settings.language
                ))
                .font(.system(size: 12.5))
                .foregroundStyle(.secondary)
                .lineSpacing(3)
            }
            Spacer(minLength: 0)
        }
        .padding(15)
        .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 9.5, weight: .bold, design: .rounded))
            .tracking(1.05)
            .foregroundStyle(.secondary)
    }

    @MainActor
    private func performLogin() async {
        guard !session.isAuthenticating else { return }
        focus = nil
        let success = await session.login(email: email, password: password)
        let feedback = UINotificationFeedbackGenerator()
        feedback.prepare()
        feedback.notificationOccurred(success ? .success : .error)
        if success { password = "" }
    }
}
