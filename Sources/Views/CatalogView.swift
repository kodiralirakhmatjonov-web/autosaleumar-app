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
            let matchesStatus: Bool
            if status == .inStock {
                matchesStatus = car.status == .inStock || car.status == .inShowroom
            } else {
                matchesStatus = status == nil || car.status == status
            }
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

                    HStack {
                        Text(L10n.t("Автомобили", "Avtomobillar", settings.language)).asuPageTitle()
                        Spacer()
                    }
                    .padding(.horizontal, ASUDesign.pagePadding)

                    HStack(spacing: 10) {
                        ASUGlassSearchField(text: $search, placeholder: L10n.t("Марка, модель", "Marka, model", settings.language))
                        ASUGlassIconButton(
                            symbol: "slider.horizontal.3",
                            size: 52,
                            accessibilityLabel: L10n.t("Фильтры", "Filtrlar", settings.language)
                        ) { showFilters = true }
                    }
                    .padding(.horizontal, ASUDesign.pagePadding)

                    statusRail
                    content
                }
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .refreshable { await store.loadIfNeeded(force: true) }
            .navigationDestination(for: Int.self) { id in
                if let car = store.cars.first(where: { $0.id == id }) { CarDetailView(car: car) }
            }
        }
        .sheet(isPresented: $showFilters) {
            FilterSheet(status: $status, brand: $brand, brands: brands)
        }
    }

    private var statusRail: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                chip(L10n.t("Все", "Barchasi", settings.language), selected: status == nil) { status = nil }
                chip(L10n.t("В наличии", "Mavjud", settings.language), selected: status == .inStock) { status = .inStock }
                chip(L10n.t("В пути", "Yo‘lda", settings.language), selected: status == .inTransit) { status = .inTransit }
                chip(L10n.t("Под заказ", "Buyurtma", settings.language), selected: status == .madeToOrder) { status = .madeToOrder }
            }
            .padding(.horizontal, ASUDesign.pagePadding)
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Group {
            if selected {
                Button(action: action) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(uiColor: .systemBackground))
                        .padding(.horizontal, 18)
                        .frame(height: 40)
                        .background(Color.primary, in: Capsule())
                }
                .buttonStyle(.plain)
            } else {
                ASUGlassActionTile(action: action) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.primary)
                        .padding(.horizontal, 18)
                        .frame(height: 40)
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.catalogState == .loading && store.cars.isEmpty {
            VStack(spacing: 14) {
                ProgressView()
                Text(L10n.t("Загружаем каталог…", "Katalog yuklanmoqda…", settings.language)).foregroundStyle(.secondary)
            }
            .padding(.top, 70)
        } else if case .unavailable(let message) = store.catalogState, store.cars.isEmpty {
            ConnectionStateView(message: message) { Task { await store.loadIfNeeded(force: true) } }
        } else if filtered.isEmpty {
            EmptyCatalogView(hasFilters: !search.isEmpty || status != nil || brand != nil) {
                search = ""; status = nil; brand = nil
            }
        } else {
            if case .unavailable = store.catalogState {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.exclamationmark")
                    Text(L10n.t("Показан сохранённый каталог", "Saqlangan katalog ko‘rsatilmoqda", settings.language))
                    Spacer()
                    Button(L10n.t("Обновить", "Yangilash", settings.language)) { Task { await store.loadIfNeeded(force: true) } }
                }
                .font(.system(size: 12.5, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.horizontal, ASUDesign.pagePadding)
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(filtered) { car in
                    NavigationLink(value: car.id) { CarCard(car: car) }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, ASUDesign.pagePadding)
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
            List {
                Section(L10n.t("Статус", "Holat", settings.language)) {
                    filterRow(L10n.t("Все", "Barchasi", settings.language), selected: status == nil) { status = nil }
                    filterRow(L10n.t("В наличии", "Mavjud", settings.language), selected: status == .inStock) { status = .inStock }
                    filterRow(L10n.t("В пути", "Yo‘lda", settings.language), selected: status == .inTransit) { status = .inTransit }
                    filterRow(L10n.t("Под заказ", "Buyurtma", settings.language), selected: status == .madeToOrder) { status = .madeToOrder }
                }
                Section(L10n.t("Марка", "Marka", settings.language)) {
                    filterRow(L10n.t("Все марки", "Barcha markalar", settings.language), selected: brand == nil) { brand = nil }
                    ForEach(brands, id: \.self) { item in
                        filterRow(item, selected: brand == item) { brand = item }
                    }
                }
            }
            .navigationTitle(L10n.t("Фильтры", "Filtrlar", settings.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.t("Готово", "Tayyor", settings.language)) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(34)
    }

    private func filterRow(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack { Text(title); Spacer(); if selected { Image(systemName: "checkmark") } }
        }
        .foregroundStyle(.primary)
    }
}

private struct ConnectionStateView: View {
    @EnvironmentObject private var settings: AppSettings
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ASUGlassSurface(radius: 26) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(.secondary)
                    .frame(width: 86, height: 86)
            }
            Text(L10n.t("Каталог недоступен", "Katalog mavjud emas", settings.language))
                .font(.system(size: 24, weight: .bold, design: .rounded))
            Text(message)
                .font(.system(size: 14.5))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button(L10n.t("Повторить", "Qayta urinish", settings.language), action: retry)
                .buttonStyle(.borderedProminent)
                .tint(.primary)
        }
        .padding(.top, 62)
    }
}

private struct EmptyCatalogView: View {
    @EnvironmentObject private var settings: AppSettings
    let hasFilters: Bool
    let reset: () -> Void

    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "car.side")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(.tertiary)
            Text(hasFilters ? L10n.t("Ничего не найдено", "Hech narsa topilmadi", settings.language) : L10n.t("Нет опубликованных автомобилей", "E’lon qilingan avtomobillar yo‘q", settings.language))
                .font(.system(size: 23, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
            Text(hasFilters ? L10n.t("Измените поиск или фильтры.", "Qidiruv yoki filtrlarni o‘zgartiring.", settings.language) : L10n.t("Как только автомобиль будет опубликован в общей базе Auto Sale Umar, он появится здесь автоматически.", "Avtomobil Auto Sale Umar umumiy bazasida e’lon qilinishi bilan shu yerda avtomatik ko‘rinadi.", settings.language))
                .font(.system(size: 14.5))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 22)
            if hasFilters {
                Button(L10n.t("Сбросить фильтры", "Filtrlarni tozalash", settings.language), action: reset)
                    .buttonStyle(.borderedProminent)
                    .tint(.primary)
            }
        }
        .padding(.top, 58)
        .padding(.horizontal, 20)
    }
}
