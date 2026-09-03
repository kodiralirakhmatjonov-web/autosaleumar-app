import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    BrandHeader()
                    HStack {
                        Text(L10n.t("Избранное", "Saqlangan", settings.language)).asuPageTitle()
                        Spacer()
                    }
                    .padding(.horizontal, ASUDesign.pagePadding)

                    if store.favorites.isEmpty {
                        VStack(spacing: 15) {
                            ASUGlassSurface(radius: 28) {
                                Image(systemName: "heart")
                                    .font(.system(size: 38, weight: .light))
                                    .frame(width: 92, height: 92)
                            }
                            Text(L10n.t("Сохранённых автомобилей пока нет", "Saqlangan avtomobillar yo‘q", settings.language))
                                .font(.system(size: 23, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                            Text(L10n.t("Нажмите на сердце в карточке автомобиля, чтобы быстро вернуться к нему.", "Avtomobil kartasidagi yurakni bosing — keyin unga tez qaytasiz.", settings.language))
                                .font(.system(size: 14.5))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 74)
                        .padding(.horizontal, 30)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            ForEach(store.favorites) { car in
                                NavigationLink(value: car.id) { CarCard(car: car) }.buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, ASUDesign.pagePadding)
                    }
                }
                .padding(.bottom, 28)
            }
            .navigationDestination(for: Int.self) { id in
                if let car = store.cars.first(where: { $0.id == id }) { CarDetailView(car: car) }
            }
        }
    }
}
