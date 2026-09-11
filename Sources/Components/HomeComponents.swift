import SwiftUI

struct ASUFloatingHeader: View {
    @Environment(\.colorScheme) private var scheme
    let onMenu: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(scheme == .dark ? "WordmarkWhite" : "WordmarkBlack")
                .resizable()
                .scaledToFit()
                .frame(width: 154, alignment: .leading)
                .accessibilityLabel("Auto Sale Umar")

            Spacer()

            ASUGlassIconButton(
                symbol: "line.3.horizontal",
                size: 46,
                fontSize: 18,
                accessibilityLabel: "Menu",
                action: onMenu
            )
        }
        .padding(.leading, 17)
        .padding(.trailing, 8)
        .frame(height: 62)
        .modifier(ASUHeaderGlass())
    }
}

private struct ASUHeaderGlass: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: Capsule())
        } else {
            content
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.22), lineWidth: 0.7))
                .shadow(color: .black.opacity(0.09), radius: 18, y: 8)
        }
    }
}

struct ASUHomeSectionHeader: View {
    let kicker: String
    let title: String
    let text: String?
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(kicker)
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .tracking(1.35)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 12)
                if let actionTitle, let action {
                    Button(actionTitle, action: action)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .buttonStyle(.plain)
                }
            }

            Text(title)
                .asuSectionTitle(size: 34)

            if let text, !text.isEmpty {
                Text(text)
                    .font(.system(size: 15.5, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            }
        }
        .padding(.horizontal, ASUDesign.pagePadding)
    }
}

struct ASUHomeCarCard: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme
    let car: Car

    private var descriptor: String? {
        let candidates = [car.trim, car.engineText, car.fuelType]
        return candidates.compactMap { value in
            let clean = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return clean.isEmpty ? nil : clean
        }.first
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                ASUCarCardGallery(car: car, height: 188)

                HStack(alignment: .top) {
                    StatusPill(status: car.status, language: settings.language, compact: true)
                    Spacer()
                    ASUGlassIconButton(
                        symbol: store.isFavorite(car) ? "heart.fill" : "heart",
                        size: 38,
                        fontSize: 15,
                        accessibilityLabel: store.isFavorite(car) ? L10n.t("Удалить из избранного", "Saqlanganlardan olib tashlash", settings.language) : L10n.t("Добавить в избранное", "Saqlanganlarga qo‘shish", settings.language)
                    ) {
                        store.toggleFavorite(car)
                    }
                    .foregroundStyle(store.isFavorite(car) ? ASUDesign.orange : Color.primary)
                }
                .padding(12)
            }

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Text(car.brand.uppercased())
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .tracking(1.15)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer(minLength: 6)

                    if let year = car.year {
                        Text(String(year))
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 9)
                            .frame(height: 26)
                            .background(Color.primary.opacity(0.045), in: Capsule())
                            .overlay(Capsule().stroke(ASUDesign.line, lineWidth: 0.6))
                    }
                }

                Text(car.model)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .tracking(-0.7)
                    .lineSpacing(-2)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, minHeight: 54, alignment: .topLeading)
                    .padding(.top, 9)

                if let descriptor {
                    Text(descriptor)
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(ASUDesign.gallery, in: Capsule())
                        .padding(.top, 2)
                } else {
                    Color.clear.frame(height: 30)
                }

                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    Text(L10n.t("ЦЕНА", "NARX", settings.language))
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(1.25)
                        .foregroundStyle(.tertiary)
                    Spacer(minLength: 6)
                    Text(Format.price(car, language: settings.language))
                        .font(.system(size: 19.5, weight: .bold, design: .rounded))
                        .tracking(-0.35)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .padding(.top, 13)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(ASUDesign.line)
                        .frame(height: 0.7)
                }
            }
            .padding(16)
        }
        .frame(width: 286)
        .background(ASUDesign.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(ASUDesign.line, lineWidth: 0.7)
        )
        .shadow(color: colorScheme == .light ? .black.opacity(0.055) : .clear, radius: 20, y: 10)
    }
}

struct ASUShowroomStoryCard: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.colorScheme) private var colorScheme
    let story: ASUShowroomStory

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(story.assetName)
                .resizable()
                .scaledToFill()
                .frame(width: 300, height: 360)
                .clipped()

            VStack(alignment: .leading, spacing: 9) {
                Text(story.title(settings.language))
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .tracking(-0.35)
                Text(story.text(settings.language))
                    .font(.system(size: 14.5))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
            }
            .padding(17)
            .frame(width: 300, alignment: .topLeading)
            .frame(minHeight: 154, alignment: .topLeading)
        }
        .background(ASUDesign.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))
        .shadow(color: colorScheme == .light ? .black.opacity(0.05) : .clear, radius: 20, y: 9)
    }
}

struct ASUDigitalStoryCard: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.colorScheme) private var colorScheme
    let story: ASUDigitalStory

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                Image(story.assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 248)
                    .clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.36)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                Text("AUTO SALE UMAR · DIGITAL")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.78))
                    .padding(15)
            }
            .background(ASUDesign.gallery)

            VStack(alignment: .leading, spacing: 9) {
                Text(story.title(settings.language))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .tracking(-0.45)
                Text(story.text(settings.language))
                    .font(.system(size: 14.5))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, minHeight: 354, alignment: .topLeading)
        .background(ASUDesign.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))
        .shadow(color: colorScheme == .light ? .black.opacity(0.045) : .clear, radius: 16, y: 8)
        .padding(.bottom, 1)
    }
}

struct ASUContactTile: View {
    let symbol: String
    let title: String
    let detail: String
    let action: () -> Void

    var body: some View {
        ASUGlassActionTile(action: action) {
            VStack(alignment: .leading, spacing: 11) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 38, height: 38)
                    .background(Color.primary.opacity(0.06), in: Circle())
                Text(title)
                    .font(.system(size: 15.5, weight: .bold, design: .rounded))
                Text(detail)
                    .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
            .padding(15)
        }
    }
}

struct ASUHomeSideMenu: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding var isPresented: Bool
    let openCatalog: () -> Void
    let openShowroom: () -> Void
    let openContacts: () -> Void
    let openBooking: () -> Void
    let switchToStaff: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Color.black.opacity(isPresented ? 0.18 : 0)
                    .ignoresSafeArea()
                    .onTapGesture { close() }

                HStack(spacing: 0) {
                    sidePanel(width: min(proxy.size.width * 0.90, 420))
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func sidePanel(width: CGFloat) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L10n.t("Добро пожаловать", "Xush kelibsiz", settings.language))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.15)
                            .foregroundStyle(.secondary)
                        Text(L10n.t("в шоу-рум Auto Sale Umar", "Auto Sale Umar shourumiga", settings.language))
                            .font(.system(size: 31, weight: .bold, design: .rounded))
                            .tracking(-1)
                        Text(L10n.t(
                            "Все основные разделы, контакты и настройки собраны в одной боковой панели.",
                            "Asosiy bo‘limlar, kontaktlar va sozlamalar bitta yon panelga jamlandi.",
                            settings.language
                        ))
                        .font(.system(size: 14.5))
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                    }

                    Spacer(minLength: 10)

                    ASUGlassIconButton(symbol: "xmark", size: 42, fontSize: 15, accessibilityLabel: L10n.t("Закрыть", "Yopish", settings.language)) {
                        close()
                    }
                }

                ASUExperienceSwitcher(mode: .client) { mode in
                    guard mode == .staff else { return }
                    closeThen(switchToStaff)
                }
                .padding(18)
                .asuCard(radius: 28)

                VStack(spacing: 0) {
                    sideMenuRow("car.side", L10n.t("Автомобили", "Avtomobillar", settings.language), action: openCatalog)
                    Divider().padding(.leading, 56)
                    sideMenuRow("building.2", L10n.t("Шоурум", "Shourum", settings.language), action: openShowroom)
                    Divider().padding(.leading, 56)
                    sideMenuRow("message", L10n.t("Контакты", "Kontaktlar", settings.language), action: openContacts)
                    Divider().padding(.leading, 56)
                    sideMenuRow("calendar", L10n.t("Забронировать визит", "Tashrifni band qilish", settings.language), action: openBooking)
                }
                .asuCard(radius: 28)

                VStack(alignment: .leading, spacing: 14) {
                    Text(L10n.t("ЯЗЫК", "TIL", settings.language))
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(.secondary)
                    Picker("Language", selection: $settings.language) {
                        ForEach(AppLanguage.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    Text(L10n.t("ТЕМА", "MAVZU", settings.language))
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                    Picker("Theme", selection: $settings.theme) {
                        ForEach(AppTheme.allCases) { Text($0.title(settings.language)).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(18)
                .asuCard(radius: 28)
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

    private func sideMenuRow(_ symbol: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button {
            closeThen(action)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 34, height: 34)
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .frame(minHeight: 62)
        }
        .buttonStyle(.plain)
    }

    private func closeThen(_ action: @escaping () -> Void) {
        close()
        let delay = reduceMotion ? 0.0 : 0.16
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: action)
    }

    private func close() {
        withAnimation(reduceMotion ? nil : ASUDesign.softSpring) {
            isPresented = false
        }
    }
}
