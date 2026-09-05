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
    let car: Car

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                CarImage(url: car.primaryImageURL, height: 188)

                HStack(alignment: .top) {
                    StatusPill(status: car.status, language: settings.language, compact: true)
                    Spacer()
                    ASUGlassIconButton(
                        symbol: store.isFavorite(car) ? "heart.fill" : "heart",
                        size: 38,
                        fontSize: 15,
                        accessibilityLabel: L10n.t("Избранное", "Saqlangan", settings.language)
                    ) {
                        store.toggleFavorite(car)
                    }
                    .foregroundStyle(store.isFavorite(car) ? ASUDesign.orange : Color.primary)
                }
                .padding(12)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(car.displayName)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .tracking(-0.35)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, minHeight: 50, alignment: .topLeading)

                HStack(spacing: 5) {
                    if let year = car.year { Text(String(year)) }
                    if let fuel = car.fuelType, !fuel.isEmpty { Text("·"); Text(fuel) }
                    if let seats = car.seats { Text("·"); Text("\(seats) \(L10n.t("мест", "o‘rin", settings.language))") }
                }
                .font(.system(size: 12.5, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

                Text(Format.price(car, language: settings.language))
                    .font(.system(size: 18.5, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .padding(16)
        }
        .frame(width: 274)
        .background(ASUDesign.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(ASUDesign.line, lineWidth: 0.7)
        )
        .shadow(color: .black.opacity(0.055), radius: 20, y: 10)
    }
}

struct ASUShowroomStoryCard: View {
    @EnvironmentObject private var settings: AppSettings
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
        .shadow(color: .black.opacity(0.05), radius: 20, y: 9)
    }
}

struct ASUDigitalStoryCard: View {
    @EnvironmentObject private var settings: AppSettings
    let story: ASUDigitalStory

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(story.assetName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 260)

            VStack(alignment: .leading, spacing: 7) {
                Text(story.title(settings.language))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text(story.text(settings.language))
                    .font(.system(size: 14.5))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
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

struct ASUHomeMenuSheet: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    let openCatalog: () -> Void
    let openShowroom: () -> Void
    let openContacts: () -> Void
    let openBooking: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 0) {
                        menuRow("car.side", L10n.t("Автомобили", "Avtomobillar", settings.language), action: openCatalog)
                        Divider().padding(.leading, 56)
                        menuRow("building.2", L10n.t("Шоурум", "Shourum", settings.language), action: openShowroom)
                        Divider().padding(.leading, 56)
                        menuRow("message", L10n.t("Контакты", "Kontaktlar", settings.language), action: openContacts)
                        Divider().padding(.leading, 56)
                        menuRow("calendar", L10n.t("Забронировать визит", "Tashrifni band qilish", settings.language), action: openBooking)
                    }
                    .asuCard(radius: 26)

                    VStack(alignment: .leading, spacing: 13) {
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
                            ForEach(AppTheme.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(16)
                    .asuCard(radius: 26)
                }
                .padding(18)
            }
            .navigationTitle("Auto Sale Umar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(34)
    }

    private func menuRow(_ symbol: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16, execute: action)
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
}
