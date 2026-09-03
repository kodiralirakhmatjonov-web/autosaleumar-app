import SwiftUI

struct CarImage: View {
    let url: URL?
    let height: CGFloat

    var body: some View {
        ZStack {
            Color.primary.opacity(0.025)
            if let url {
                AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.24))) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFit().padding(7)
                    case .failure:
                        placeholder
                    case .empty:
                        ProgressView().controlSize(.small)
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
    }

    private var placeholder: some View {
        Image(systemName: "car.side")
            .font(.system(size: 48, weight: .light))
            .foregroundStyle(.tertiary)
    }
}

struct StatusPill: View {
    let status: CarStatus
    let language: AppLanguage
    var compact = false

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(status == .inStock || status == .inShowroom ? ASUDesign.orange : Color.secondary.opacity(0.65))
                .frame(width: 6, height: 6)
            Text(status.title(language))
                .font(.system(size: compact ? 10.5 : 12, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, compact ? 9 : 11)
        .frame(height: compact ? 26 : 30)
        .background(.thinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 0.55))
    }
}

struct CarCard: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: AppStore
    let car: Car

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                CarImage(url: car.coverURL, height: 126)
                ASUGlassIconButton(
                    symbol: store.isFavorite(car) ? "heart.fill" : "heart",
                    size: 36,
                    fontSize: 15,
                    accessibilityLabel: L10n.t("Избранное", "Saqlangan", settings.language)
                ) {
                    store.toggleFavorite(car)
                }
                .foregroundStyle(store.isFavorite(car) ? ASUDesign.orange : Color.primary)
                .padding(9)
            }

            VStack(alignment: .leading, spacing: 7) {
                StatusPill(status: car.status, language: settings.language, compact: true)
                Text(car.displayName)
                    .font(.system(size: 15.5, weight: .bold, design: .rounded))
                    .lineLimit(2)
                HStack(spacing: 4) {
                    if let year = car.year { Text(String(year)) }
                    if let fuel = car.fuelType, !fuel.isEmpty { Text("·"); Text(fuel) }
                    if let seats = car.seats { Text("·"); Text("\(seats) \(L10n.t("мест", "o‘rin", settings.language))") }
                }
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                Text(Format.price(car, language: settings.language))
                    .font(.system(size: 15.5, weight: .bold, design: .rounded))
            }
            .padding(12)
        }
        .background(ASUDesign.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 23, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))
        .shadow(color: .black.opacity(0.045), radius: 14, y: 7)
    }
}

enum Format {
    static func price(_ car: Car, language: AppLanguage) -> String {
        guard !car.priceOnRequest, let value = car.price else {
            return L10n.t("Цена по запросу", "Narx so‘rov bo‘yicha", language)
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0
        let number = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        let symbol: String
        switch car.currency.uppercased() {
        case "USD": symbol = "$"
        case "EUR": symbol = "€"
        case "UZS": symbol = "сум"
        default: symbol = car.currency
        }
        return "\(number) \(symbol)"
    }
}
