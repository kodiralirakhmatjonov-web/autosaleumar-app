import SwiftUI

struct CompareView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    let cars: [Car]
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if cars.count == 2 {
                    HStack(alignment: .top, spacing: 10) { ForEach(cars) { car in VStack(alignment: .leading, spacing: 8) { CarImage(url: car.coverURL, height: 125).clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous)); Text(car.displayName).font(.system(size: 16, weight: .bold, design: .rounded)); Text(Format.price(car, language: settings.language)).font(.system(size: 13, weight: .semibold)) }.frame(maxWidth: .infinity) } }
                    compareRow(L10n.t("Год", "Yil", settings.language), cars[0].year.map(String.init), cars[1].year.map(String.init))
                    compareRow(L10n.t("Двигатель", "Dvigatel", settings.language), cars[0].engineText, cars[1].engineText)
                    compareRow(L10n.t("Привод", "Privod", settings.language), cars[0].driveType, cars[1].driveType)
                    compareRow(L10n.t("Коробка", "Uzatma", settings.language), cars[0].transmission, cars[1].transmission)
                    compareRow(L10n.t("Мест", "O‘rin", settings.language), cars[0].seats.map(String.init), cars[1].seats.map(String.init))
                    compareRow(L10n.t("Статус", "Holat", settings.language), cars[0].status.title(settings.language), cars[1].status.title(settings.language))
                } else { Text(L10n.t("Выберите два автомобиля для сравнения.", "Taqqoslash uchun ikki avtomobil tanlang.", settings.language)).foregroundStyle(.secondary).padding(.top, 80) }
            }.padding(18)
        }
        .navigationTitle(L10n.t("Сравнение", "Taqqoslash", settings.language)).navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(L10n.t("Готово", "Tayyor", settings.language)) { dismiss() } } }
    }
    private func compareRow(_ title: String, _ a: String?, _ b: String?) -> some View {
        VStack(spacing: 10) { Text(title.uppercased()).font(.system(size: 10, weight: .bold, design: .rounded)).tracking(0.8).foregroundStyle(.secondary); HStack(alignment: .top) { Text(a ?? "—").frame(maxWidth: .infinity); Divider(); Text(b ?? "—").frame(maxWidth: .infinity) }.font(.system(size: 14, weight: .semibold, design: .rounded)) }.padding(15).asuCard(radius: 20, shadow: false)
    }
}
