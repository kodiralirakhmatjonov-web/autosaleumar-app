import SwiftUI

struct ASUAdminControlSystemView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var session: ASUAdminSessionStore
    let close: () -> Void

    @State private var path: [ASUAdminSection] = []

    private var sections: [ASUAdminSection] {
        guard let role = session.user?.role else { return [] }
        return ASUAdminSection.allCases.filter { $0.isVisible(for: role) }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(spacing: 24) {
                    welcomeCard
                    sectionGrid
                    accountCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 34)
            }
            .scrollIndicators(.hidden)
            .background(ASUDesign.page)
            .safeAreaInset(edge: .top, spacing: 0) {
                adminHeader
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: ASUAdminSection.self) { section in
                switch section {
                case .staff:
                    ASUAdminStaffView(session: session)
                case .cars:
                    ASUAdminCarsView(session: session)
                default:
                    ASUAdminSectionPlaceholder(section: section)
                }
            }
        }
    }

    private var adminHeader: some View {
        HStack(spacing: 12) {
            Image(colorScheme == .dark ? "WordmarkWhite" : "WordmarkBlack")
                .resizable()
                .scaledToFit()
                .frame(width: 146, alignment: .leading)
            Spacer()
            ASUGlassIconButton(
                symbol: "xmark",
                size: 44,
                fontSize: 15,
                accessibilityLabel: L10n.t("Закрыть", "Yopish", settings.language),
                action: close
            )
        }
        .padding(.leading, 17)
        .padding(.trailing, 8)
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
                        Circle()
                            .fill(ASUDesign.success)
                            .frame(width: 7, height: 7)
                        Text(L10n.t("ЗАЩИЩЁННАЯ СЕССИЯ", "HIMOYALANGAN SESSIYA", settings.language))
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
                    Text("AUTO SALE UMAR")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.45)
                        .foregroundStyle(.white.opacity(0.52))
                    Text("Control System")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .tracking(-1.35)
                        .foregroundStyle(.white)
                    if let user = session.user {
                        Text(user.fullName)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.92))
                        Text(user.email)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.50))
                    }
                }

                Text(L10n.t(
                    "Мобильная система управления подключена к той же учётной записи и тем же данным, что веб-панель Auto Sale Umar.",
                    "Mobil boshqaruv tizimi Auto Sale Umar veb panelidagi ayni akkaunt va ayni ma’lumotlarga ulangan.",
                    settings.language
                ))
                .font(.system(size: 13.5))
                .foregroundStyle(.white.opacity(0.60))
                .lineSpacing(3)
            }
            .padding(22)
        }
        .frame(minHeight: 310)
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 34, style: .continuous).stroke(Color.white.opacity(0.10), lineWidth: 0.7))
        .shadow(color: .black.opacity(0.13), radius: 22, y: 12)
    }

    private var sectionGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.t("СИСТЕМА УПРАВЛЕНИЯ", "BOSHQARUV TIZIMI", settings.language))
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.25)
                .foregroundStyle(.secondary)
                .padding(.leading, 2)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(sections) { section in
                    Button {
                        path.append(section)
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
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.t("УЧЁТНАЯ ЗАПИСЬ", "AKKAUNT", settings.language))
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .tracking(1.15)
                        .foregroundStyle(.secondary)
                    if let role = session.user?.role {
                        Text(role.title(settings.language))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                    }
                }
                Spacer()
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(ASUDesign.success)
            }

            Divider()

            HStack(spacing: 10) {
                Picker("Language", selection: $settings.language) {
                    ForEach(AppLanguage.allCases) { Text($0.rawValue.uppercased()).tag($0) }
                }
                .pickerStyle(.segmented)

                Picker("Theme", selection: $settings.theme) {
                    Text(L10n.t("Система", "Tizim", settings.language)).tag(AppTheme.system)
                    Text(L10n.t("Свет", "Yorug‘", settings.language)).tag(AppTheme.light)
                    Text(L10n.t("Тёмн.", "Tungi", settings.language)).tag(AppTheme.dark)
                }
                .pickerStyle(.menu)
            }

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
        .padding(18)
        .asuCard(radius: 28)
    }
}

private struct ASUAdminSectionPlaceholder: View {
    @EnvironmentObject private var settings: AppSettings
    let section: ASUAdminSection

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(spacing: 14) {
                    ASUGlassCircleSurface(size: 62) {
                        Image(systemName: section.symbol)
                            .font(.system(size: 23, weight: .semibold))
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text("CONTROL SYSTEM")
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                            .tracking(1.2)
                            .foregroundStyle(.secondary)
                        Text(section.title(settings.language))
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .tracking(-0.9)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.t("Мобильный модуль подготовлен", "Mobil modul tayyorlandi", settings.language))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text(L10n.t(
                        "Авторизация, роли и защищённая сессия уже работают через действующую систему Auto Sale Umar. Функции этого раздела будут подключаться поэтапно без изменения работающего сайта.",
                        "Avtorizatsiya, rollar va himoyalangan sessiya mavjud Auto Sale Umar tizimi orqali ishlaydi. Ushbu bo‘lim funksiyalari ishlayotgan saytni o‘zgartirmasdan bosqichma-bosqich ulanadi.",
                        settings.language
                    ))
                    .font(.system(size: 14.5))
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
                }
                .padding(18)
                .asuCard(radius: 28)
            }
            .padding(18)
        }
        .background(ASUDesign.page)
        .navigationTitle(section.title(settings.language))
        .navigationBarTitleDisplayMode(.inline)
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
