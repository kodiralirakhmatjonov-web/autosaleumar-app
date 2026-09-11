import SwiftUI

private enum ASUAdminAppTab: String, Hashable {
    case home
    case cars
    case staff
    case work
    case more

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .home: return L10n.t("Главная", "Asosiy", language)
        case .cars: return L10n.t("Авто", "Avto", language)
        case .staff: return L10n.t("Команда", "Jamoa", language)
        case .work: return L10n.t("Работа", "Ish", language)
        case .more: return L10n.t("Ещё", "Yana", language)
        }
    }

    var symbol: String {
        switch self {
        case .home: return "house"
        case .cars: return "car.2"
        case .staff: return "person.2"
        case .work: return "tray.full"
        case .more: return "ellipsis.circle"
        }
    }
}

struct ASUAdminControlSystemView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject var session: ASUAdminSessionStore
    let close: () -> Void

    @State private var selection: ASUAdminAppTab = .home
    @State private var showMenu = false
    @State private var homePath: [ASUAdminSection] = []

    private var canSeeStaff: Bool {
        guard let role = session.user?.role else { return false }
        return ASUAdminSection.staff.isVisible(for: role)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            TabView(selection: $selection) {
                NavigationStack(path: $homePath) {
                    dashboard
                        .navigationDestination(for: ASUAdminSection.self) { section in
                            adminSectionView(section)
                        }
                }
                .tag(ASUAdminAppTab.home)
                .tabItem { Label(ASUAdminAppTab.home.title(settings.language), systemImage: ASUAdminAppTab.home.symbol) }

                NavigationStack {
                    ASUAdminCarsView(session: session)
                }
                .tag(ASUAdminAppTab.cars)
                .tabItem { Label(ASUAdminAppTab.cars.title(settings.language), systemImage: ASUAdminAppTab.cars.symbol) }

                if canSeeStaff {
                    NavigationStack {
                        ASUAdminStaffView(session: session)
                    }
                    .tag(ASUAdminAppTab.staff)
                    .tabItem { Label(ASUAdminAppTab.staff.title(settings.language), systemImage: ASUAdminAppTab.staff.symbol) }
                }

                NavigationStack {
                    ASUAdminWorkHubView(session: session)
                }
                .tag(ASUAdminAppTab.work)
                .tabItem { Label(ASUAdminAppTab.work.title(settings.language), systemImage: ASUAdminAppTab.work.symbol) }

                NavigationStack {
                    ASUAdminMoreView(session: session, switchToClient: close)
                }
                .tag(ASUAdminAppTab.more)
                .tabItem { Label(ASUAdminAppTab.more.title(settings.language), systemImage: ASUAdminAppTab.more.symbol) }
            }
            .tint(.primary)
            .disabled(showMenu)
            .blur(radius: showMenu ? 1.6 : 0)

            if showMenu {
                ASUAdminSideMenu(
                    isPresented: $showMenu,
                    currentTab: selection,
                    canSeeStaff: canSeeStaff,
                    selectTab: { selection = $0 },
                    switchToClient: close,
                    session: session
                )
                .zIndex(20)
            }
        }
        .background(ASUDesign.page)
        .animation(reduceMotion ? nil : ASUDesign.softSpring, value: showMenu)
        .sensoryFeedback(.selection, trigger: selection)
        .onChange(of: canSeeStaff) { _, visible in
            if !visible && selection == .staff { selection = .home }
        }
    }

    private var dashboard: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                welcomeCard
                quickAccess
                accountCard
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 36)
        }
        .scrollIndicators(.hidden)
        .background(ASUDesign.page)
        .safeAreaInset(edge: .top, spacing: 0) {
            adminHeader
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var adminHeader: some View {
        HStack(spacing: 12) {
            ASUGlassIconButton(
                symbol: "line.3.horizontal",
                size: 44,
                fontSize: 16,
                accessibilityLabel: L10n.t("Меню", "Menyu", settings.language)
            ) {
                withAnimation(reduceMotion ? nil : ASUDesign.softSpring) {
                    showMenu = true
                }
            }

            Spacer()

            VStack(spacing: 1) {
                Text("CONTROL SYSTEM")
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .tracking(1.05)
                    .foregroundStyle(.secondary)
                Text(L10n.t("Главная", "Asosiy", settings.language))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }

            Spacer()

            ASUGlassCircleSurface(size: 44) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(ASUDesign.success)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 62)
        .modifier(ASUAdminHeaderGlass())
    }

    private var welcomeCard: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.black, Color(red: 0.08, green: 0.08, blue: 0.09)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(ASUDesign.orange.opacity(0.22))
                .frame(width: 220, height: 220)
                .blur(radius: 46)
                .offset(x: 160, y: -120)

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    HStack(spacing: 7) {
                        Circle().fill(ASUDesign.success).frame(width: 7, height: 7)
                        Text("D1 LIVE")
                    }
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(.white.opacity(0.62))

                    Spacer()

                    if let role = session.user?.role {
                        Text(role.shortTitle(settings.language))
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .tracking(0.9)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .frame(height: 30)
                            .background(.white.opacity(0.10), in: Capsule())
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.t("Добро пожаловать", "Xush kelibsiz", settings.language))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.35)
                        .foregroundStyle(.white.opacity(0.52))
                    Text(session.user?.fullName ?? "Auto Sale Umar")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .tracking(-1.25)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text(L10n.t(
                        "Полноценный рабочий режим приложения: автомобили, команда, визиты, запросы и медиаконтент в одной системе.",
                        "Ilovaning to‘liq ish rejimi: avtomobillar, jamoa, tashriflar, so‘rovlar va media bitta tizimda.",
                        settings.language
                    ))
                    .font(.system(size: 13.5))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineSpacing(3)
                }
            }
            .padding(22)
        }
        .frame(minHeight: 300)
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 34, style: .continuous).stroke(Color.white.opacity(0.10), lineWidth: 0.7))
        .shadow(color: .black.opacity(0.13), radius: 22, y: 12)
    }

    private var quickAccess: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.t("БЫСТРЫЙ ДОСТУП", "TEZKOR KIRISH", settings.language))
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.25)
                .foregroundStyle(.secondary)
                .padding(.leading, 2)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(visibleSections) { section in
                    Button {
                        open(section)
                    } label: {
                        VStack(alignment: .leading, spacing: 13) {
                            HStack {
                                Image(systemName: section.symbol)
                                    .font(.system(size: 19, weight: .semibold))
                                    .frame(width: 42, height: 42)
                                    .background(Color.primary.opacity(0.055), in: Circle())
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.tertiary)
                            }
                            Text(section.title(settings.language))
                                .font(.system(size: 16.5, weight: .bold, design: .rounded))
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                            Text(section.subtitle(settings.language))
                                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, minHeight: 142, alignment: .topLeading)
                        .padding(15)
                        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .asuCard(radius: 24)
                }
            }
        }
    }

    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ASUGlassCircleSurface(size: 48) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 19, weight: .semibold))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(session.user?.role.title(settings.language) ?? "Control System")
                        .font(.system(size: 15.5, weight: .bold, design: .rounded))
                    Text(session.user?.email ?? "")
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ASUDesign.success)
            }

            Text(L10n.t(
                "Переключение между клиентским и рабочим интерфейсом теперь находится в боковом меню.",
                "Mijoz va ishchi interfeys o‘rtasida almashish endi yon menyuda.",
                settings.language
            ))
            .font(.system(size: 12.5))
            .foregroundStyle(.secondary)
            .lineSpacing(3)
        }
        .padding(16)
        .asuCard(radius: 26)
    }

    private var visibleSections: [ASUAdminSection] {
        guard let role = session.user?.role else { return [] }
        return ASUAdminSection.allCases.filter { $0.isVisible(for: role) }
    }

    private func open(_ section: ASUAdminSection) {
        switch section {
        case .cars:
            selection = .cars
        case .staff where canSeeStaff:
            selection = .staff
        default:
            homePath.append(section)
        }
    }

    @ViewBuilder
    private func adminSectionView(_ section: ASUAdminSection) -> some View {
        switch section {
        case .staff:
            ASUAdminStaffView(session: session)
        case .cars:
            ASUAdminCarsView(session: session)
        case .brands:
            ASUAdminBrandMediaView(session: session)
        case .home:
            ASUAdminHomeMediaView(session: session)
        case .visits:
            ASUAdminVisitsView(session: session)
        case .requests:
            ASUAdminRequestsView(session: session)
        case .ramadan:
            ASUAdminRamadanGiftView(session: session)
        }
    }
}

private struct ASUAdminWorkHubView: View {
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject var session: ASUAdminSessionStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header(
                    kicker: "SHOWROOM OPERATIONS",
                    title: L10n.t("Работа с клиентами", "Mijozlar bilan ishlash", settings.language),
                    subtitle: L10n.t("Визиты в шоурум и запросы на подбор автомобиля.", "Shourum tashriflari va avtomobil tanlash so‘rovlari.", settings.language)
                )

                NavigationLink {
                    ASUAdminVisitsView(session: session)
                } label: {
                    hubCard(symbol: "calendar", title: L10n.t("Визиты", "Tashriflar", settings.language), subtitle: L10n.t("Записи, подтверждения и статусы", "Yozuvlar, tasdiqlar va statuslar", settings.language))
                }
                .buttonStyle(.plain)

                NavigationLink {
                    ASUAdminRequestsView(session: session)
                } label: {
                    hubCard(symbol: "text.page", title: L10n.t("Запросы клиентов", "Mijoz so‘rovlari", settings.language), subtitle: L10n.t("Подбор, бюджет и воронка продаж", "Tanlov, byudjet va savdo voronkasi", settings.language))
                }
                .buttonStyle(.plain)
            }
            .padding(18)
            .padding(.bottom, 24)
        }
        .background(ASUDesign.page)
        .navigationTitle(L10n.t("Работа", "Ish", settings.language))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func header(kicker: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(kicker)
                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.system(size: 31, weight: .bold, design: .rounded))
                .tracking(-0.9)
            Text(subtitle)
                .font(.system(size: 13.5))
                .foregroundStyle(.secondary)
        }
    }

    private func hubCard(symbol: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ASUGlassCircleSurface(size: 54) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .semibold))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 17, weight: .bold, design: .rounded))
                Text(subtitle).font(.system(size: 12.5, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.tertiary)
        }
        .foregroundStyle(.primary)
        .padding(16)
        .asuCard(radius: 26)
    }
}

private struct ASUAdminMoreView: View {
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject var session: ASUAdminSessionStore
    let switchToClient: () -> Void

    private var visibleSections: [ASUAdminSection] {
        guard let role = session.user?.role else { return [] }
        return [.brands, .home, .ramadan].filter { $0.isVisible(for: role) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("CONTROL SYSTEM")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(.secondary)
                    Text(L10n.t("Ещё", "Yana", settings.language))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .tracking(-0.9)
                    Text(L10n.t("Медиа, промо-материалы и настройки рабочего режима.", "Media, promo materiallar va ish rejimi sozlamalari.", settings.language))
                        .font(.system(size: 13.5))
                        .foregroundStyle(.secondary)
                }

                ForEach(visibleSections) { section in
                    NavigationLink {
                        destination(section)
                    } label: {
                        HStack(spacing: 14) {
                            ASUGlassCircleSurface(size: 50) {
                                Image(systemName: section.symbol)
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(section.title(settings.language))
                                    .font(.system(size: 16.5, weight: .bold, design: .rounded))
                                Text(section.subtitle(settings.language))
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.tertiary)
                        }
                        .foregroundStyle(.primary)
                        .padding(15)
                        .asuCard(radius: 24)
                    }
                    .buttonStyle(.plain)
                }

                settingsCard
            }
            .padding(18)
            .padding(.bottom, 28)
        }
        .background(ASUDesign.page)
        .navigationTitle(L10n.t("Ещё", "Yana", settings.language))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            ASUExperienceSwitcher(mode: .staff) { mode in
                if mode == .client { switchToClient() }
            }

            Divider()

            Picker("Language", selection: $settings.language) {
                ForEach(AppLanguage.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)

            Picker("Theme", selection: $settings.theme) {
                ForEach(AppTheme.allCases) { Text($0.title(settings.language)).tag($0) }
            }
            .pickerStyle(.segmented)

            Button(role: .destructive) {
                Task { await session.signOut() }
            } label: {
                Label(L10n.t("Выйти из Control System", "Control Systemdan chiqish", settings.language), systemImage: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .padding(16)
        .asuCard(radius: 26)
    }

    @ViewBuilder
    private func destination(_ section: ASUAdminSection) -> some View {
        switch section {
        case .brands: ASUAdminBrandMediaView(session: session)
        case .home: ASUAdminHomeMediaView(session: session)
        case .ramadan: ASUAdminRamadanGiftView(session: session)
        case .staff: ASUAdminStaffView(session: session)
        case .cars: ASUAdminCarsView(session: session)
        case .visits: ASUAdminVisitsView(session: session)
        case .requests: ASUAdminRequestsView(session: session)
        }
    }
}

private struct ASUAdminSideMenu: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding var isPresented: Bool
    let currentTab: ASUAdminAppTab
    let canSeeStaff: Bool
    let selectTab: (ASUAdminAppTab) -> Void
    let switchToClient: () -> Void
    @ObservedObject var session: ASUAdminSessionStore

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Color.black.opacity(isPresented ? 0.20 : 0)
                    .ignoresSafeArea()
                    .onTapGesture { close() }

                HStack(spacing: 0) {
                    panel(width: min(proxy.size.width * 0.90, 420))
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func panel(width: CGFloat) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("CONTROL SYSTEM")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(1.2)
                            .foregroundStyle(.secondary)
                        Text(session.user?.fullName ?? "Auto Sale Umar")
                            .font(.system(size: 27, weight: .bold, design: .rounded))
                            .tracking(-0.8)
                            .lineLimit(2)
                        if let role = session.user?.role {
                            Text(role.title(settings.language))
                                .font(.system(size: 12.5, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 8)
                    ASUGlassIconButton(symbol: "xmark", size: 42, fontSize: 15, accessibilityLabel: L10n.t("Закрыть", "Yopish", settings.language)) {
                        close()
                    }
                }

                ASUExperienceSwitcher(mode: .staff) { mode in
                    guard mode == .client else { return }
                    closeThen(switchToClient)
                }
                .padding(16)
                .asuCard(radius: 26)

                VStack(spacing: 0) {
                    tabRow(.home)
                    Divider().padding(.leading, 56)
                    tabRow(.cars)
                    if canSeeStaff {
                        Divider().padding(.leading, 56)
                        tabRow(.staff)
                    }
                    Divider().padding(.leading, 56)
                    tabRow(.work)
                    Divider().padding(.leading, 56)
                    tabRow(.more)
                }
                .asuCard(radius: 28)

                VStack(alignment: .leading, spacing: 13) {
                    Text(L10n.t("РАБОЧИЙ РЕЖИМ", "ISH REJIMI", settings.language))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.05)
                        .foregroundStyle(.secondary)
                    Label(L10n.t("Защищённая сессия активна", "Himoyalangan sessiya faol", settings.language), systemImage: "lock.shield.fill")
                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(ASUDesign.success)
                    Text(session.user?.email ?? "")
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .asuCard(radius: 24, shadow: false)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 30)
        }
        .frame(width: width)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(ASUDesign.page)
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(ASUDesign.line, lineWidth: 0.7)
        }
        .shadow(color: .black.opacity(0.16), radius: 26, y: 10)
        .ignoresSafeArea(edges: .vertical)
        .transition(.move(edge: .leading).combined(with: .opacity))
    }

    private func tabRow(_ tab: ASUAdminAppTab) -> some View {
        Button {
            closeThen { selectTab(tab) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 34, height: 34)
                Text(tab.title(settings.language))
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                Spacer()
                if currentTab == tab {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(ASUDesign.success)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.tertiary)
                }
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .frame(minHeight: 60)
        }
        .buttonStyle(.plain)
    }

    private func closeThen(_ action: @escaping () -> Void) {
        close()
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0 : 0.16), execute: action)
    }

    private func close() {
        withAnimation(reduceMotion ? nil : ASUDesign.softSpring) {
            isPresented = false
        }
    }
}

private struct ASUAdminHeaderGlass: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: Capsule())
        } else {
            content
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.20), lineWidth: 0.7))
                .shadow(color: .black.opacity(0.08), radius: 14, y: 6)
        }
    }
}
