import SwiftUI

struct CarCard: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: AppStore
    let car: Car
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                CarImage(url: car.coverURL, height: compact ? 125 : 175)
                Button { store.toggleFavorite(car) } label: {
                    Image(systemName: store.isFavorite(car) ? "heart.fill" : "heart")
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(store.isFavorite(car) ? ASUDesign.orange : .primary)
                        .frame(width: 36, height: 36).background(.ultraThinMaterial, in: Circle())
                }.buttonStyle(.plain).padding(9)
            }
            VStack(alignment: .leading, spacing: 8) {
                StatusPill(status: car.status, language: settings.language, compact: true)
                Text(car.displayName).font(.system(size: compact ? 16 : 19, weight: .bold, design: .rounded)).lineLimit(2)
                HStack(spacing: 5) {
                    if let year = car.year { Text(String(year)) }
                    if let fuel = car.fuelType, !fuel.isEmpty { Text("·"); Text(fuel) }
                    if let seats = car.seats { Text("·"); Text("\(seats) \(L10n.t("мест", "o‘rin", settings.language))") }
                }.font(.system(size: 12.5)).foregroundStyle(.secondary).lineLimit(1)
                Text(Format.price(car, language: settings.language)).font(.system(size: compact ? 16 : 20, weight: .bold, design: .rounded))
            }.padding(compact ? 12 : 15)
        }
        .background(ASUDesign.elevated)
        .clipShape(RoundedRectangle(cornerRadius: compact ? 22 : 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: compact ? 22 : 26, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))
        .shadow(color: .black.opacity(0.045), radius: 14, y: 7)
    }
}

enum Format {
    static func price(_ car: Car, language: AppLanguage) -> String {
        if car.priceOnRequest || car.price == nil { return L10n.t("Цена по запросу", "Narx so‘rov bo‘yicha", language) }
        let f = NumberFormatter(); f.numberStyle = .decimal; f.groupingSeparator = " "; f.maximumFractionDigits = 0
        let n = f.string(from: NSNumber(value: car.price!)) ?? "\(car.price!)"
        let symbol: String
        switch car.currency.uppercased() { case "USD": symbol = "$"; case "EUR": symbol = "€"; case "UZS": symbol = "сум"; default: symbol = car.currency }
        return "\(n) \(symbol)"
    }
}
