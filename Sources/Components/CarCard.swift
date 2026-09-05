import SwiftUI

enum CatalogCardLayout: String, CaseIterable, Hashable {
    case grid
    case wide
}

struct CarImage: View {
    let url: URL?
    let height: CGFloat
    var fill = false

    var body: some View {
        ASURemoteImage(
            url: url,
            contentMode: fill ? .fill : .fit,
            background: ASUDesign.gallery,
            padding: fill ? 0 : 10
        )
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
    }
}

struct StatusPill: View {
    let status: CarStatus
    let language: AppLanguage
    var compact = false

    private var dot: Color {
        switch status {
        case .inStock, .inShowroom: ASUDesign.orange
        case .inTransit: Color.secondary
        case .sold, .reserved: Color.primary.opacity(0.55)
        default: Color.secondary.opacity(0.55)
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(dot).frame(width: 6, height: 6)
            Text(status.title(language))
                .font(.system(size: compact ? 10.5 : 12, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .padding(.horizontal, compact ? 9 : 11)
        .frame(height: compact ? 26 : 30)
        .modifier(ASUStatusGlass())
    }
}


private struct ASUStatusGlass: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: Capsule())
        } else {
            content
                .background(.thinMaterial, in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.22), lineWidth: 0.55))
        }
    }
}

struct CarCard: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let car: Car
    var layout: CatalogCardLayout = .grid

    var body: some View {
        Group {
            switch layout {
            case .grid: gridCard
            case .wide: wideCard
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: layout == .grid ? 24 : 30, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(car.displayName), \(car.status.title(settings.language)), \(Format.price(car, language: settings.language))")
    }

    private var gridCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .top) {
                CarImage(url: car.primaryImageURL, height: 156)

                HStack(alignment: .top) {
                    StatusPill(status: car.status, language: settings.language, compact: true)
                    Spacer()
                    favoriteButton(size: 36)
                }
                .padding(10)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(car.brand.uppercased())
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .tracking(0.65)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    if let year = car.year {
                        Text(String(year))
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }

                Text(car.model)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .tracking(-0.3)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, minHeight: 42, alignment: .topLeading)

                if let trim = car.trim, !trim.isEmpty {
                    Text(trim)
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text(car.engineText ?? " ")
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                colorLine

                Spacer(minLength: 0)

                Text(Format.price(car, language: settings.language))
                    .font(.system(size: 16.5, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 154, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, minHeight: 310, maxHeight: 310, alignment: .top)
        .background(ASUDesign.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))
        .shadow(color: colorScheme == .light ? .black.opacity(0.045) : .clear, radius: 14, y: 7)
    }

    private var wideCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .top) {
                CarImage(url: car.primaryImageURL, height: 248)
                HStack {
                    StatusPill(status: car.status, language: settings.language)
                    Spacer()
                    HStack(spacing: 8) {
                        ShareLink(item: AppConfig.carShareURL(car)) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 15, weight: .semibold))
                                .frame(width: 42, height: 42)
                                .modifier(ASUCardGlassCircle())
                        }
                        .buttonStyle(.plain)
                        favoriteButton(size: 42)
                    }
                }
                .padding(14)
            }

            HStack(alignment: .bottom, spacing: 16) {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 7) {
                        Text(car.brand.uppercased())
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .tracking(0.9)
                            .foregroundStyle(.secondary)
                        if let year = car.year {
                            Text("· \(year)")
                                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(car.model)
                        .font(.system(size: 27, weight: .bold, design: .rounded))
                        .tracking(-0.75)
                        .lineLimit(2)
                    if let trim = car.trim, !trim.isEmpty {
                        Text(trim).font(.system(size: 13.5, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                    }
                    colorLine
                }
                Spacer(minLength: 8)
                Text(Format.price(car, language: settings.language))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
                    .minimumScaleFactor(0.78)
            }
            .padding(18)
        }
        .background(ASUDesign.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))
        .shadow(color: colorScheme == .light ? .black.opacity(0.055) : .clear, radius: 18, y: 9)
    }

    @ViewBuilder
    private var colorLine: some View {
        if let color = car.exteriorColor, !color.isEmpty {
            HStack(spacing: 7) {
                Circle()
                    .fill(Color(asuHex: car.exteriorSwatch, fallback: Color.primary.opacity(0.82)))
                    .frame(width: 9, height: 9)
                    .overlay(Circle().stroke(ASUDesign.lineStrong, lineWidth: 0.5))
                Text(color)
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        } else if let engine = car.engineText, !engine.isEmpty {
            Text(engine)
                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private func favoriteButton(size: CGFloat) -> some View {
        Button {
            withAnimation(reduceMotion ? nil : ASUDesign.spring) { store.toggleFavorite(car) }
        } label: {
            Image(systemName: store.isFavorite(car) ? "heart.fill" : "heart")
                .font(.system(size: 15.5, weight: .semibold))
                .symbolEffect(.bounce, value: store.isFavorite(car))
                .foregroundStyle(store.isFavorite(car) ? ASUDesign.orange : Color.primary)
                .frame(width: size, height: size)
                .modifier(ASUCardGlassCircle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(store.isFavorite(car)
            ? L10n.t("Удалить из избранного", "Saqlanganlardan olib tashlash", settings.language)
            : L10n.t("Добавить в избранное", "Saqlanganlarga qo‘shish", settings.language))
    }
}

private struct ASUCardGlassCircle: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: Circle())
        } else {
            content
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.22), lineWidth: 0.6))
                .shadow(color: .black.opacity(0.06), radius: 10, y: 5)
        }
    }
}

enum Format {
    static func price(_ car: Car, language: AppLanguage) -> String {
        price(value: car.price, currency: car.currency, onRequest: car.priceOnRequest, language: language)
    }

    static func price(_ detail: CarDetail, language: AppLanguage) -> String {
        price(value: detail.price, currency: detail.currency, onRequest: detail.priceOnRequest, language: language)
    }

    static func number(_ value: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private static func price(value: Int64?, currency: String, onRequest: Bool, language: AppLanguage) -> String {
        guard !onRequest, let value else {
            return L10n.t("Цена по запросу", "Narx so‘rov bo‘yicha", language)
        }
        let symbol: String
        switch currency.uppercased() {
        case "USD": symbol = "$"
        case "EUR": symbol = "€"
        case "UZS": symbol = "сум"
        default: symbol = currency
        }
        return "\(number(value)) \(symbol)"
    }
}
