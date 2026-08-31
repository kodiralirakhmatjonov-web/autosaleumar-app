import SwiftUI

struct CatalogView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: AppStore
    @State private var search = ""
    @State private var status: CarStatus? = nil
    @State private var brand: String? = nil
    @State private var showFilters = false

    private var filtered: [Car] {
        store.cars.filter { car in
            let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let matchesText = q.isEmpty || car.displayName.lowercased().contains(q) || (car.trim?.lowercased().contains(q) ?? false)
            let matchesStatus = status == nil || car.status == status
            let matchesBrand = brand == nil || car.brand == brand
            return matchesText && matchesStatus && matchesBrand
        }
    }
    private var brands: [String] { Array(Set(store.cars.map(\.brand))).sorted() }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    BrandHeader()
                    HStack { Text(L10n.t("Автомобили", "Avtomobillar", settings.language)).asuPageTitle(); Spacer() }.padding(.horizontal, ASUDesign.pagePadding)
                    HStack(spacing: 10) {
                        HStack(spacing: 9) { Image(systemName: "magnifyingglass").foregroundStyle(.secondary); TextField(L10n.t("Марка, модель", "Marka, model", settings.language), text: $search).textInputAutocapitalization(.never) }.padding(.horizontal, 14).frame(height: 48).background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        Button { showFilters = true } label: { Image(systemName: "slider.horizontal.3").font(.system(size: 17, weight: .semibold)).frame(width: 48, height: 48).background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 16, style: .continuous)) }.buttonStyle(.plain)
                    }.padding(.horizontal, ASUDesign.pagePadding)
                    statusRail
                    content
                }.padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .refreshable { await store.loadIfNeeded(force: true) }
            .navigationDestination(for: Int.self) { id in if let car = store.cars.first(where: { $0.id == id }) { CarDetailView(car: car) } }
        }
        .sheet(isPresented: $showFilters) { FilterSheet(status: $status, brand: $brand, brands: brands) }
    }

    private var statusRail: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                filterChip(L10n.t("Все", "Barchasi", settings.language), selected: status == nil) { status = nil }
                filterChip(L10n.t("В наличии", "Mavjud", settings.language), selected: status == .inStock || status == .inShowroom) { status = .inStock }
                filterChip(L10n.t("В пути", "Yo‘lda", settings.language), selected: status == .inTransit) { status = .inTransit }
                filterChip(L10n.t("Под заказ", "Buyurtma", settings.language), selected: status == .madeToOrder) { status = .madeToOrder }
            }.padding(.horizontal, ASUDesign.pagePadding)
        }.scrollIndicators(.hidden)
    }
    private func filterChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) { Text(title).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(selected ? Color(uiColor: .systemBackground) : Color.primary).padding(.horizontal, 17).frame(height: 40).background(selected ? Color.primary : ASUDesign.soft, in: Capsule()) }.buttonStyle(.plain)
    }

    @ViewBuilder private var content: some View {
        if store.catalogState == .loading && store.cars.isEmpty { VStack(spacing: 14) { ProgressView(); Text(L10n.t("Загружаем каталог…", "Katalog yuklanmoqda…", settings.language)).foregroundStyle(.secondary) }.padding(.top, 70) }
        else if filtered.isEmpty { EmptyCatalogView(hasFilters: !search.isEmpty || status != nil || brand != nil, reset: { search = ""; status = nil; brand = nil }) }
        else {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(filtered) { car in NavigationLink(value: car.id) { CarCard(car: car, compact: true) }.buttonStyle(.plain) }
            }.padding(.horizontal, ASUDesign.pagePadding)
        }
    }
}

private struct FilterSheet: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Binding var status: CarStatus?
    @Binding var brand: String?
    let brands: [String]
    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.t("Статус", "Holat", settings.language)) { Picker(L10n.t("Статус", "Holat", settings.language), selection: $status) { Text(L10n.t("Все", "Barchasi", settings.language)).tag(CarStatus?.none); ForEach([CarStatus.inStock, .inShowroom, .inTransit, .madeToOrder, .reserved, .sold]) { s in Text(s.title(settings.language)).tag(Optional(s)) } } }
                Section(L10n.t("Марка", "Marka", settings.language)) { Picker(L10n.t("Марка", "Marka", settings.language), selection: $brand) { Text(L10n.t("Все марки", "Barcha markalar", settings.language)).tag(String?.none); ForEach(brands, id: \.self) { Text($0).tag(Optional($0)) } } }
                Section { Button(role: .destructive) { status = nil; brand = nil } label: { Text(L10n.t("Сбросить фильтры", "Filtrlarni tozalash", settings.language)) } }
            }
            .navigationTitle(L10n.t("Фильтры", "Filtrlar", settings.language)).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(L10n.t("Готово", "Tayyor", settings.language)) { dismiss() } } }
        }.presentationDetents([.medium, .large])
    }
}

private struct EmptyCatalogView: View {
    @EnvironmentObject private var settings: AppSettings
    let hasFilters: Bool
    let reset: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: hasFilters ? "line.3.horizontal.decrease.circle" : "car.side").font(.system(size: 42, weight: .light)).foregroundStyle(.secondary)
            Text(hasFilters ? L10n.t("Ничего не найдено", "Hech narsa topilmadi", settings.language) : L10n.t("Коллекция обновляется", "Kolleksiya yangilanmoqda", settings.language)).font(.system(size: 22, weight: .bold, design: .rounded))
            Text(hasFilters ? L10n.t("Измените фильтры или поисковый запрос.", "Filtr yoki qidiruvni o‘zgartiring.", settings.language) : L10n.t("Опубликованные автомобили появятся здесь автоматически из каталога Auto Sale Umar.", "E’lon qilingan avtomobillar Auto Sale Umar katalogidan avtomatik paydo bo‘ladi.", settings.language)).font(.system(size: 14)).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 34)
            if hasFilters { Button(L10n.t("Сбросить", "Tozalash", settings.language), action: reset).buttonStyle(.borderedProminent).tint(.primary) }
        }.padding(.top, 54).padding(.horizontal, 18)
    }
}
