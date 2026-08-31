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
                    HStack { Text(L10n.t("Избранное", "Saqlangan", settings.language)).asuPageTitle(); Spacer(); if store.compareCars.count == 2 { Button { showCompare = true } label: { Image(systemName: "rectangle.split.2x1").frame(width: 42, height: 42).background(ASUDesign.soft, in: Circle()) }.buttonStyle(.plain) } }.padding(.horizontal, ASUDesign.pagePadding)
                    if store.favorites.isEmpty {
                        VStack(spacing: 14) { Image(systemName: "heart").font(.system(size: 44, weight: .light)).foregroundStyle(.secondary); Text(L10n.t("Сохраняйте автомобили", "Avtomobillarni saqlang", settings.language)).font(.system(size: 22, weight: .bold, design: .rounded)); Text(L10n.t("Нажмите на сердце в карточке — автомобиль останется здесь.", "Kartadagi yurakni bosing — avtomobil shu yerda qoladi.", settings.language)).multilineTextAlignment(.center).foregroundStyle(.secondary) }.padding(.top, 80).padding(.horizontal, 30)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(store.favorites) { car in NavigationLink(value: car.id) { HStack(spacing: 12) { CarImage(url: car.coverURL, height: 108).frame(width: 145).clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous)); VStack(alignment: .leading, spacing: 7) { StatusPill(status: car.status, language: settings.language, compact: true); Text(car.displayName).font(.system(size: 17, weight: .bold, design: .rounded)); Text(Format.price(car, language: settings.language)).font(.system(size: 14, weight: .semibold)); Button { store.toggleCompare(car) } label: { Label(store.isCompared(car) ? L10n.t("В сравнении", "Taqqoslanmoqda", settings.language) : L10n.t("Сравнить", "Taqqoslash", settings.language), systemImage: store.isCompared(car) ? "checkmark.circle.fill" : "rectangle.split.2x1") }.font(.system(size: 12, weight: .semibold)).buttonStyle(.plain).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading) }.padding(10).asuCard(radius: 24) }.buttonStyle(.plain) }
                        }.padding(.horizontal, ASUDesign.pagePadding)
                    }
                }.padding(.bottom, 28)
            }
            .navigationDestination(for: Int.self) { id in if let car = store.cars.first(where: { $0.id == id }) { CarDetailView(car: car) } }
        }
        .sheet(isPresented: $showCompare) { NavigationStack { CompareView(cars: store.compareCars) } }
    }
}
