import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: AppStore
    @State private var showCompare = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    BrandHeader()
                    HStack {
                        Text(L10n.t("Избранное", "Saqlangan", settings.language)).asuPageTitle()
                        Spacer()
                        ASUGlassIconButton(symbol: "arrow.left.arrow.right", size: 46, accessibilityLabel: L10n.t("Сравнение", "Solishtirish", settings.language)) {
                            showCompare = true
                        }
                        .overlay(alignment: .topTrailing) {
                            if !store.compareCars.isEmpty {
                                Text("\(store.compareCars.count)")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(width: 18, height: 18)
                                    .background(.black, in: Circle())
                                    .offset(x: 4, y: -4)
                            }
                        }
                    }
                    .padding(.horizontal, ASUDesign.pagePadding)

                    comparePanel

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
                        .padding(.top, 50)
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
        .sheet(isPresented: $showCompare) { CompareView() }
    }

    private var comparePanel: some View {
        Button { showCompare = true } label: {
            HStack(spacing: 14) {
                ASUGlassCircleSurface(size: 54) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 19, weight: .semibold))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.t("Сравнить автомобили", "Avtomobillarni solishtirish", settings.language))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text(store.compareCars.isEmpty
                         ? L10n.t("Выберите 2–3 конкретных автомобиля", "2–3 aniq avtomobil tanlang", settings.language)
                         : L10n.t("Выбрано: \(store.compareCars.count) из 3", "Tanlandi: \(store.compareCars.count) / 3", settings.language))
                        .font(.system(size: 12.5, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundStyle(.tertiary)
            }
            .padding(14)
            .asuCard(radius: 24, shadow: false)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, ASUDesign.pagePadding)
    }
}
