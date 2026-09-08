import SwiftUI
import UIKit

struct ASUAdminStaffView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ObservedObject var session: ASUAdminSessionStore

    @State private var staff: [ASUAdminStaffMember] = []
    @State private var summary: ASUAdminStaffSummary = .empty
    @State private var viewerRole: ASUAdminRole?
    @State private var scope: ASUAdminStaffScope?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showCreate = false
    @State private var selectedMember: ASUAdminStaffMember?

    private let api = ASUAdminAPI()

    private var metricColumns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 22) {
                hero

                if isLoading && staff.isEmpty {
                    loadingState
                } else if let errorMessage, staff.isEmpty {
                    errorState(errorMessage)
                } else {
                    dashboard
                    staffSection
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 36)
        }
        .scrollIndicators(.hidden)
        .background(ASUDesign.page)
        .navigationTitle(L10n.t("Команда", "Jamoa", settings.language))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreate = true
                } label: {
                    Image(systemName: "person.badge.plus")
                }
                .disabled(viewerRole == nil)
                .accessibilityLabel(L10n.t("Добавить сотрудника", "Xodim qo‘shish", settings.language))
            }
        }
        .refreshable { await loadStaff(silent: true) }
        .task { await loadStaff() }
        .sheet(isPresented: $showCreate) {
            if let viewerRole {
                ASUAdminCreateStaffView(session: session, viewerRole: viewerRole) { created in
                    applyCreated(created)
                }
            }
        }
        .sheet(item: $selectedMember) { member in
            ASUAdminStaffMemberView(
                session: session,
                viewerRole: viewerRole ?? session.user?.role ?? .admin,
                member: member
            ) { updated in
                applyUpdated(updated)
            }
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.black, Color(red: 0.07, green: 0.07, blue: 0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(ASUDesign.orange.opacity(0.20))
                .frame(width: 180, height: 180)
                .blur(radius: 38)
                .offset(x: 165, y: -92)

            VStack(alignment: .leading, spacing: 15) {
                HStack(spacing: 8) {
                    Text("CONTROL SYSTEM")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .tracking(1.2)
                    Spacer()
                    HStack(spacing: 6) {
                        Circle().fill(ASUDesign.success).frame(width: 7, height: 7)
                        Text("D1 LIVE")
                    }
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .tracking(0.8)
                }
                .foregroundStyle(.white.opacity(0.58))

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.t("Команда", "Jamoa", settings.language))
                        .font(.system(size: 37, weight: .bold, design: .rounded))
                        .tracking(-1.2)
                        .foregroundStyle(.white)
                    Text(scopeSubtitle)
                        .font(.system(size: 14.5, weight: .regular))
                        .foregroundStyle(.white.opacity(0.62))
                        .lineSpacing(4)
                }

                Button {
                    showCreate = true
                } label: {
                    Label(L10n.t("Добавить сотрудника", "Xodim qo‘shish", settings.language), systemImage: "plus")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 16)
                        .frame(height: 46)
                        .background(.white, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(viewerRole == nil)
            }
            .padding(21)
        }
        .frame(minHeight: 252)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 0.7))
    }

    private var scopeSubtitle: String {
        if scope == .salesManagers || viewerRole == .admin {
            return L10n.t(
                "Управление менеджерами и их доступом к экосистеме Auto Sale Umar.",
                "Menejerlar va ularning Auto Sale Umar tizimiga kirishini boshqarish.",
                settings.language
            )
        }
        return L10n.t(
            "Управление всей командой Auto Sale Umar, ролями и доступом к системе.",
            "Auto Sale Umar jamoasi, rollar va tizimga kirishni boshqarish.",
            settings.language
        )
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: metricColumns, spacing: 10) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(ASUDesign.elevated)
                        .frame(height: 126)
                        .overlay { ProgressView().controlSize(.small) }
                }
            }

            HStack(spacing: 10) {
                ProgressView()
                Text(L10n.t("Загрузка сотрудников…", "Xodimlar yuklanmoqda…", settings.language))
                    .font(.system(size: 13.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(ASUDesign.orange)
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.t("Не удалось загрузить данные", "Ma’lumotlarni yuklab bo‘lmadi", settings.language))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text(message)
                        .font(.system(size: 13.5))
                        .foregroundStyle(.secondary)
                }
            }

            Button(L10n.t("Повторить", "Qayta urinish", settings.language)) {
                Task { await loadStaff() }
            }
            .buttonStyle(ASUPrimaryButtonStyle(prominent: false))
        }
        .padding(18)
        .asuCard(radius: 28)
    }

    private var dashboard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.t("ОБЗОР ДОСТУПА", "KIRISH NAZORATI", settings.language))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.15)
                        .foregroundStyle(.secondary)
                    Text(L10n.t("Обновляется из D1", "D1 orqali yangilanadi", settings.language))
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                if isLoading {
                    ProgressView().controlSize(.small)
                }
            }

            LazyVGrid(columns: metricColumns, spacing: 10) {
                metricCard(
                    title: L10n.t("Всего", "Jami", settings.language),
                    value: summary.total,
                    detail: "\(summary.active) \(L10n.t("активных", "faol", settings.language))",
                    symbol: "person.2"
                )
                metricCard(
                    title: L10n.t("Администраторы", "Administratorlar", settings.language),
                    value: summary.admins,
                    detail: L10n.t("доступ к управлению", "boshqaruv huquqi", settings.language),
                    symbol: "person.badge.key"
                )
                metricCard(
                    title: L10n.t("Менеджеры", "Menejerlar", settings.language),
                    value: summary.managers,
                    detail: L10n.t("работа с клиентами", "mijozlar bilan ishlaydi", settings.language),
                    symbol: "person.crop.circle.badge.checkmark"
                )
                metricCard(
                    title: L10n.t("Заблокированы", "Bloklangan", settings.language),
                    value: summary.blocked,
                    detail: L10n.t("без доступа", "kirish huquqisiz", settings.language),
                    symbol: "lock.slash"
                )
            }
        }
    }

    private func metricCard(title: String, value: Int, detail: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(value))
                    .font(.system(size: 31, weight: .bold, design: .rounded))
                    .tracking(-1)
            }
            Text(title)
                .font(.system(size: 14.5, weight: .bold, design: .rounded))
                .lineLimit(2)
            Text(detail)
                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 126, alignment: .topLeading)
        .padding(15)
        .asuCard(radius: 24)
    }

    private var staffSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.t("СОТРУДНИКИ", "XODIMLAR", settings.language))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.15)
                        .foregroundStyle(.secondary)
                    Text(staffCountText)
                        .font(.system(size: 12.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(ASUDesign.success).frame(width: 7, height: 7)
                    Text("D1 LIVE")
                }
                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                .tracking(0.7)
                .foregroundStyle(.secondary)
            }

            if let errorMessage, !staff.isEmpty {
                HStack(spacing: 9) {
                    Image(systemName: "wifi.exclamationmark")
                    Text(errorMessage)
                        .lineLimit(2)
                    Spacer(minLength: 6)
                    Button(L10n.t("Повторить", "Qayta", settings.language)) {
                        Task { await loadStaff(silent: true) }
                    }
                }
                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(12)
                .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            if staff.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "person.2")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(.tertiary)
                    Text(L10n.t("Сотрудников пока нет", "Hozircha xodimlar yo‘q", settings.language))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text(L10n.t(
                        "После создания они появятся здесь автоматически.",
                        "Yaratilgandan keyin ular bu yerda avtomatik ko‘rinadi.",
                        settings.language
                    ))
                    .font(.system(size: 13.5))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 190)
                .padding(18)
                .asuCard(radius: 26)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(staff) { member in
                        Button {
                            selectedMember = member
                        } label: {
                            memberCard(member)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var staffCountText: String {
        if settings.language == .uz { return "\(summary.total) profil" }
        let noun = summary.total == 1 ? "профиль" : "профилей"
        return "\(summary.total) \(noun)"
    }

    private func memberCard(_ member: ASUAdminStaffMember) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(member.initials())
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .frame(width: 50, height: 50)
                .background(ASUDesign.soft, in: Circle())
                .overlay(Circle().stroke(ASUDesign.line, lineWidth: 0.7))

            VStack(alignment: .leading, spacing: 11) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 7) {
                            Text(member.fullName)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .lineLimit(2)
                            if member.isCurrentUser {
                                Text(L10n.t("Вы", "Siz", settings.language))
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .padding(.horizontal, 7)
                                    .frame(height: 22)
                                    .background(ASUDesign.soft, in: Capsule())
                            }
                        }
                        Text(member.email)
                            .font(.system(size: 11.5, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }

                    Spacer(minLength: 6)

                    Image(systemName: member.role == .superAdmin ? "lock.fill" : "ellipsis")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 34, height: 34)
                        .background(ASUDesign.soft, in: Circle())
                }

                HStack(spacing: 7) {
                    Text(member.role.title(settings.language))
                        .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 9)
                        .frame(height: 28)
                        .background(ASUDesign.soft, in: Capsule())

                    HStack(spacing: 6) {
                        Circle()
                            .fill(member.isActive ? ASUDesign.success : Color.red.opacity(0.72))
                            .frame(width: 7, height: 7)
                        Text(member.isActive
                             ? L10n.t("Активен", "Faol", settings.language)
                             : L10n.t("Заблокирован", "Bloklangan", settings.language))
                    }
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 9)
                    .frame(height: 28)
                    .background(ASUDesign.soft, in: Capsule())
                }

                HStack(alignment: .top, spacing: 18) {
                    memberFact(
                        L10n.t("Телефон", "Telefon", settings.language),
                        member.phone?.isEmpty == false ? member.phone! : L10n.t("Не указан", "Ko‘rsatilmagan", settings.language)
                    )
                    memberFact(
                        L10n.t("Последний вход", "Oxirgi kirish", settings.language),
                        ASUAdminStaffDateText.lastLogin(member.lastLoginAt, language: settings.language)
                    )
                }
            }
        }
        .foregroundStyle(.primary)
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .asuCard(radius: 26)
    }

    private func memberFact(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                .tracking(0.75)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @MainActor
    private func loadStaff(silent: Bool = false) async {
        guard let token = session.bearerToken else {
            session.invalidateSession()
            return
        }

        if !silent { isLoading = true }
        errorMessage = nil
        defer { isLoading = false }

        do {
            let snapshot = try await api.staff(token: token)
            staff = snapshot.staff
            summary = snapshot.summary
            viewerRole = snapshot.viewer.role
            scope = snapshot.scope
        } catch let error as ASUAdminAPI.APIError {
            if error.shouldDiscardSession {
                session.invalidateSession(notice: error.localizedDescription)
                return
            }
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = L10n.t(
                "Не удалось загрузить сотрудников. Попробуйте ещё раз.",
                "Xodimlarni yuklab bo‘lmadi. Qayta urinib ko‘ring.",
                settings.language
            )
        }
    }

    private func applyCreated(_ created: ASUAdminCreatedStaff) {
        if !staff.contains(where: { $0.id == created.member.id }) {
            staff.append(created.member)
        }
        Task { await loadStaff(silent: true) }
    }

    private func applyUpdated(_ updated: ASUAdminStaffMember) {
        if let index = staff.firstIndex(where: { $0.id == updated.id }) {
            staff[index] = updated
        }
        selectedMember = updated
        Task { await loadStaff(silent: true) }
    }
}

private struct ASUAdminCreateStaffView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var session: ASUAdminSessionStore
    let viewerRole: ASUAdminRole
    let onCreated: (ASUAdminCreatedStaff) -> Void

    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var role: ASUAdminRole
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var created: ASUAdminCreatedStaff?
    @State private var copied = false

    private let api = ASUAdminAPI()

    init(
        session: ASUAdminSessionStore,
        viewerRole: ASUAdminRole,
        onCreated: @escaping (ASUAdminCreatedStaff) -> Void
    ) {
        self.session = session
        self.viewerRole = viewerRole
        self.onCreated = onCreated
        _role = State(initialValue: viewerRole == .admin ? .salesManager : .salesManager)
    }

    private var roleOptions: [ASUAdminRole] {
        viewerRole == .superAdmin ? [.salesManager, .admin] : [.salesManager]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                Group {
                    if let created {
                        successContent(created)
                    } else {
                        formContent
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 34)
            }
            .scrollIndicators(.hidden)
            .background(ASUDesign.page)
            .navigationTitle(created == nil
                             ? L10n.t("Новый сотрудник", "Yangi xodim", settings.language)
                             : L10n.t("Доступ создан", "Kirish yaratildi", settings.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.t("Закрыть", "Yopish", settings.language)) { dismiss() }
                        .disabled(isCreating)
                }
            }
        }
        .interactiveDismissDisabled(isCreating)
    }

    private var formContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 9) {
                Text("CONTROL SYSTEM · NEW ACCESS")
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .tracking(1.15)
                    .foregroundStyle(.secondary)
                Text(L10n.t("Добавить сотрудника", "Xodim qo‘shish", settings.language))
                    .font(.system(size: 31, weight: .bold, design: .rounded))
                    .tracking(-0.9)
                Text(L10n.t(
                    "Создайте защищённый профиль для команды Auto Sale Umar.",
                    "Auto Sale Umar jamoasi uchun himoyalangan profil yarating.",
                    settings.language
                ))
                .font(.system(size: 14.5))
                .foregroundStyle(.secondary)
                .lineSpacing(4)
            }

            VStack(spacing: 14) {
                staffField(title: L10n.t("Имя и фамилия", "Ism va familiya", settings.language)) {
                    TextField(L10n.t("Например, Akmal Karimov", "Masalan, Akmal Karimov", settings.language), text: $fullName)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                        .disabled(isCreating)
                }

                staffField(title: L10n.t("Электронная почта", "Elektron pochta", settings.language)) {
                    TextField("name@example.com", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .disabled(isCreating)
                }

                staffField(title: L10n.t("Телефон", "Telefon", settings.language)) {
                    TextField("+998 90 123 45 67", text: $phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                        .disabled(isCreating)
                }
            }
            .padding(16)
            .asuCard(radius: 28)

            VStack(alignment: .leading, spacing: 11) {
                Text(L10n.t("РОЛЬ В СИСТЕМЕ", "TIZIMDAGI ROL", settings.language))
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .tracking(1.05)
                    .foregroundStyle(.secondary)

                ForEach(roleOptions, id: \.self) { option in
                    roleOption(option)
                }
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.red)
                    .padding(13)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.07), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            Button {
                Task { await createStaff() }
            } label: {
                HStack(spacing: 9) {
                    if isCreating { ProgressView().tint(Color(uiColor: .systemBackground)) }
                    Text(isCreating
                         ? L10n.t("Создаём профиль…", "Profil yaratilmoqda…", settings.language)
                         : L10n.t("Создать сотрудника", "Xodim yaratish", settings.language))
                }
            }
            .buttonStyle(ASUPrimaryButtonStyle())
            .disabled(isCreating)
        }
    }

    private func staffField<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title.uppercased())
                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                .tracking(0.85)
                .foregroundStyle(.secondary)
            content()
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))
        }
    }

    private func roleOption(_ option: ASUAdminRole) -> some View {
        Button {
            role = option
        } label: {
            HStack(spacing: 13) {
                Image(systemName: option == .admin ? "person.badge.key" : "person.crop.circle.badge.checkmark")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 42, height: 42)
                    .background(ASUDesign.soft, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title(settings.language))
                        .font(.system(size: 15.5, weight: .bold, design: .rounded))
                    Text(option == .admin
                         ? L10n.t("Управление системой и менеджерами", "Tizim va menejerlarni boshqarish", settings.language)
                         : L10n.t("Автомобили, клиенты и визиты", "Avtomobillar, mijozlar va tashriflar", settings.language))
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)

                Image(systemName: role == option ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(role == option ? Color.primary : Color.secondary)
            }
            .foregroundStyle(.primary)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ASUDesign.elevated, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(role == option ? Color.primary.opacity(0.7) : ASUDesign.line, lineWidth: role == option ? 1.4 : 0.7)
            )
        }
        .buttonStyle(.plain)
        .disabled(isCreating)
    }

    private func successContent(_ created: ASUAdminCreatedStaff) -> some View {
        VStack(spacing: 18) {
            ASUGlassCircleSurface(size: 82) {
                Image(systemName: "checkmark")
                    .font(.system(size: 29, weight: .bold))
                    .foregroundStyle(ASUDesign.success)
            }

            VStack(spacing: 7) {
                Text(L10n.t("ДОСТУП СОЗДАН", "KIRISH YARATILDI", settings.language))
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .tracking(1.15)
                    .foregroundStyle(.secondary)
                Text(created.member.fullName)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .tracking(-0.9)
                    .multilineTextAlignment(.center)
                Text(L10n.t(
                    "Передайте сотруднику логин и временный пароль.",
                    "Xodimga login va vaqtinchalik parolni bering.",
                    settings.language
                ))
                .font(.system(size: 14.5))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }

            VStack(spacing: 0) {
                credentialRow(L10n.t("Логин", "Login", settings.language), created.member.email)
                Divider().padding(.leading, 16)
                credentialRow(L10n.t("Временный пароль", "Vaqtinchalik parol", settings.language), created.temporaryPassword)
            }
            .asuCard(radius: 26)

            Label(
                L10n.t(
                    "Пароль показывается только для передачи сотруднику. Не публикуйте его в общем чате.",
                    "Parol faqat xodimga berish uchun ko‘rsatiladi. Uni umumiy chatda e’lon qilmang.",
                    settings.language
                ),
                systemImage: "lock.shield"
            )
            .font(.system(size: 12.5, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

            Button {
                UIPasteboard.general.string = created.temporaryPassword
                copied = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { copied = false }
            } label: {
                Label(
                    copied
                        ? L10n.t("Скопировано", "Nusxalandi", settings.language)
                        : L10n.t("Скопировать пароль", "Parolni nusxalash", settings.language),
                    systemImage: copied ? "checkmark" : "doc.on.doc"
                )
            }
            .buttonStyle(ASUPrimaryButtonStyle(prominent: false))

            Button(L10n.t("Готово", "Tayyor", settings.language)) { dismiss() }
                .buttonStyle(ASUPrimaryButtonStyle())
        }
        .padding(.top, 18)
    }

    private func credentialRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 15.5, weight: .bold, design: .rounded))
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }

    @MainActor
    private func createStaff() async {
        guard !isCreating else { return }
        errorMessage = nil

        let cleanName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)

        guard (2...100).contains(cleanName.count) else {
            errorMessage = L10n.t("Введите имя сотрудника.", "Xodim ismini kiriting.", settings.language)
            return
        }
        guard isValidEmail(cleanEmail), cleanEmail.count <= 254 else {
            errorMessage = L10n.t("Введите корректную электронную почту.", "To‘g‘ri elektron pochta manzilini kiriting.", settings.language)
            return
        }
        guard cleanPhone.count <= 40 else {
            errorMessage = L10n.t("Номер телефона слишком длинный.", "Telefon raqami juda uzun.", settings.language)
            return
        }
        guard role == .admin || role == .salesManager else {
            errorMessage = L10n.t("Выберите допустимую роль.", "Ruxsat etilgan rolni tanlang.", settings.language)
            return
        }
        if viewerRole == .admin && role != .salesManager {
            role = .salesManager
        }
        guard let token = session.bearerToken else {
            session.invalidateSession()
            return
        }

        isCreating = true
        defer { isCreating = false }

        do {
            let result = try await api.createStaff(
                fullName: cleanName,
                email: cleanEmail,
                phone: cleanPhone,
                role: role,
                token: token
            )
            created = result
            onCreated(result)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch let error as ASUAdminAPI.APIError {
            if error.shouldDiscardSession {
                dismiss()
                session.invalidateSession(notice: error.localizedDescription)
                return
            }
            errorMessage = error.localizedDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } catch {
            errorMessage = L10n.t(
                "Не удалось создать сотрудника. Попробуйте ещё раз.",
                "Xodimni yaratib bo‘lmadi. Qayta urinib ko‘ring.",
                settings.language
            )
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    private func isValidEmail(_ value: String) -> Bool {
        let pieces = value.split(separator: "@", omittingEmptySubsequences: false)
        guard pieces.count == 2, !pieces[0].isEmpty, !pieces[1].isEmpty else { return false }
        return pieces[1].contains(".") && !value.contains(" ")
    }
}

private struct ASUAdminStaffMemberView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var session: ASUAdminSessionStore
    let viewerRole: ASUAdminRole
    let onUpdated: (ASUAdminStaffMember) -> Void

    @State private var member: ASUAdminStaffMember
    @State private var isUpdating = false
    @State private var errorMessage: String?
    @State private var confirmBlock = false

    private let api = ASUAdminAPI()

    init(
        session: ASUAdminSessionStore,
        viewerRole: ASUAdminRole,
        member: ASUAdminStaffMember,
        onUpdated: @escaping (ASUAdminStaffMember) -> Void
    ) {
        self.session = session
        self.viewerRole = viewerRole
        self.onUpdated = onUpdated
        _member = State(initialValue: member)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    identityCard
                    factsCard

                    if member.role == .superAdmin {
                        protectedCard
                    } else {
                        if viewerRole == .superAdmin {
                            roleCard
                        }
                        accessCard
                    }

                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 12.5, weight: .medium, design: .rounded))
                            .foregroundStyle(.red)
                            .padding(13)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.07), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 34)
            }
            .scrollIndicators(.hidden)
            .background(ASUDesign.page)
            .navigationTitle(L10n.t("Сотрудник", "Xodim", settings.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.t("Готово", "Tayyor", settings.language)) { dismiss() }
                        .disabled(isUpdating)
                }
            }
        }
        .interactiveDismissDisabled(isUpdating)
        .confirmationDialog(
            L10n.t("Заблокировать доступ?", "Kirishni bloklaysizmi?", settings.language),
            isPresented: $confirmBlock,
            titleVisibility: .visible
        ) {
            Button(L10n.t("Заблокировать доступ", "Kirishni bloklash", settings.language), role: .destructive) {
                Task { await update(status: "blocked") }
            }
            Button(L10n.t("Отмена", "Bekor qilish", settings.language), role: .cancel) {}
        } message: {
            Text(L10n.t(
                "Активные сессии сотрудника будут отозваны сервером.",
                "Xodimning faol sessiyalari server tomonidan bekor qilinadi.",
                settings.language
            ))
        }
    }

    private var identityCard: some View {
        HStack(spacing: 15) {
            Text(member.initials())
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .frame(width: 70, height: 70)
                .background(ASUDesign.soft, in: Circle())
                .overlay(Circle().stroke(ASUDesign.line, lineWidth: 0.7))

            VStack(alignment: .leading, spacing: 5) {
                Text(L10n.t("ПРОФИЛЬ СОТРУДНИКА", "XODIM PROFILI", settings.language))
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.secondary)
                Text(member.fullName)
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .tracking(-0.55)
                Text(member.email)
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(17)
        .asuCard(radius: 28)
    }

    private var factsCard: some View {
        VStack(spacing: 0) {
            factRow(L10n.t("Телефон", "Telefon", settings.language), member.phone?.isEmpty == false ? member.phone! : L10n.t("Не указан", "Ko‘rsatilmagan", settings.language))
            Divider().padding(.leading, 16)
            factRow(L10n.t("Последний вход", "Oxirgi kirish", settings.language), ASUAdminStaffDateText.lastLogin(member.lastLoginAt, language: settings.language))
            Divider().padding(.leading, 16)
            factRow(L10n.t("Роль", "Rol", settings.language), member.role.title(settings.language))
            Divider().padding(.leading, 16)
            factRow(
                L10n.t("Доступ", "Kirish", settings.language),
                member.isActive ? L10n.t("Активен", "Faol", settings.language) : L10n.t("Заблокирован", "Bloklangan", settings.language)
            )
        }
        .asuCard(radius: 26)
    }

    private func factRow(_ title: String, _ value: String) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
    }

    private var protectedCard: some View {
        Label(
            L10n.t(
                "Профиль супер-администратора защищён от изменений.",
                "Super administrator profili o‘zgarishlardan himoyalangan.",
                settings.language
            ),
            systemImage: "lock.shield.fill"
        )
        .font(.system(size: 13.5, weight: .medium, design: .rounded))
        .foregroundStyle(.secondary)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .asuCard(radius: 24)
    }

    private var roleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.t("РОЛЬ В СИСТЕМЕ", "TIZIMDAGI ROL", settings.language))
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.secondary)
                Text(L10n.t("Изменение применяется сразу", "O‘zgarish darhol qo‘llanadi", settings.language))
                    .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
            }

            roleButton(.salesManager)
            roleButton(.admin)
        }
        .padding(16)
        .asuCard(radius: 28)
    }

    private func roleButton(_ role: ASUAdminRole) -> some View {
        Button {
            guard member.role != role else { return }
            Task { await update(role: role) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: role == .admin ? "person.badge.key" : "person.crop.circle.badge.checkmark")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(ASUDesign.soft, in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(role.title(settings.language))
                        .font(.system(size: 14.5, weight: .bold, design: .rounded))
                    Text(role == .admin
                         ? L10n.t("Управление системой и менеджерами", "Tizim va menejerlarni boshqarish", settings.language)
                         : L10n.t("Автомобили, клиенты и визиты", "Avtomobillar, mijozlar va tashriflar", settings.language))
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                if isUpdating && member.role != role {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: member.role == role ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 19, weight: .semibold))
                }
            }
            .foregroundStyle(.primary)
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(member.role == role ? Color.primary.opacity(0.55) : ASUDesign.line, lineWidth: member.role == role ? 1.2 : 0.7)
            )
        }
        .buttonStyle(.plain)
        .disabled(isUpdating || member.role == role)
    }

    private var accessCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.t("ДОСТУП", "KIRISH HUQUQI", settings.language))
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.secondary)
                Text(L10n.t(
                    "Блокировка прекращает доступ к Control System.",
                    "Bloklash Control System tizimiga kirishni to‘xtatadi.",
                    settings.language
                ))
                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                .foregroundStyle(.tertiary)
            }

            Button {
                if member.isActive {
                    confirmBlock = true
                } else {
                    Task { await update(status: "active") }
                }
            } label: {
                HStack(spacing: 9) {
                    if isUpdating { ProgressView().controlSize(.small) }
                    Image(systemName: member.isActive ? "lock.slash" : "lock.open")
                    Text(member.isActive
                         ? L10n.t("Заблокировать доступ", "Kirishni bloklash", settings.language)
                         : L10n.t("Восстановить доступ", "Kirishni tiklash", settings.language))
                }
                .font(.system(size: 14.5, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(.bordered)
            .tint(member.isActive ? .red : ASUDesign.success)
            .disabled(isUpdating)
        }
        .padding(16)
        .asuCard(radius: 28)
    }

    @MainActor
    private func update(role: ASUAdminRole? = nil, status: String? = nil) async {
        guard !isUpdating else { return }
        guard let token = session.bearerToken else {
            dismiss()
            session.invalidateSession()
            return
        }

        isUpdating = true
        errorMessage = nil
        defer { isUpdating = false }

        do {
            let updated = try await api.updateStaff(
                id: member.id,
                role: role,
                status: status,
                token: token
            )
            member = updated
            onUpdated(updated)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch let error as ASUAdminAPI.APIError {
            if error.shouldDiscardSession {
                dismiss()
                session.invalidateSession(notice: error.localizedDescription)
                return
            }
            errorMessage = error.localizedDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } catch {
            errorMessage = L10n.t(
                "Не удалось обновить сотрудника. Попробуйте ещё раз.",
                "Xodimni yangilab bo‘lmadi. Qayta urinib ko‘ring.",
                settings.language
            )
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

private enum ASUAdminStaffDateText {
    static func lastLogin(_ rawValue: String?, language: AppLanguage) -> String {
        guard let rawValue, let date = parse(rawValue) else {
            return L10n.t("Ещё не входил", "Hali tizimga kirmagan", language)
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language == .ru ? "ru_RU" : "uz_UZ")
        formatter.dateFormat = "dd MMM, HH:mm"
        return formatter.string(from: date)
    }

    private static func parse(_ value: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: value) { return date }

        let standard = ISO8601DateFormatter()
        standard.formatOptions = [.withInternetDateTime]
        return standard.date(from: value)
    }
}
