import SwiftUI

struct CatalogView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: AppStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var search = UserDefaults.standard.string(forKey: "ASUCatalogSearchV1") ?? ""
    @State private var status = CatalogFilterStatus(
        rawValue: UserDefaults.standard.string(forKey: "ASUCatalogStatusV1") ?? ""
    ) ?? .all
    @State private var brand: String? = UserDefaults.standard.string(forKey: "ASUCatalogBrandV1")
    @State private var layout = CatalogCardLayout(
        rawValue: UserDefaults.standard.string(forKey: "ASUCatalogLayoutV1") ?? ""
    ) ?? .grid
    @State private var showFilters = false
    @State private var path = NavigationPath()
    @State private var deepLinkFailure = false
    @Namespace private var carTransitionNamespace


    private var effectiveLayout: CatalogCardLayout {
        dynamicTypeSize.isAccessibilitySize ? .wide : layout
    }

    private var filtered: [Car] {
        store.cars.filter { car in
            let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let matchesText = q.isEmpty || car.displayName.lowercased().contains(q) || (car.trim?.lowercased().contains(q) ?? false)
            let matchesStatus = status.matches(car.status)
            let matchesBrand = brand == nil || car.brand.caseInsensitiveCompare(brand ?? "") == .orderedSame
            return matchesText && matchesStatus && matchesBrand
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(spacing: 18) {
                    BrandHeader()
                    heading
                    searchRow
                    brandRail
                    statusRail
                    resultsHeader
                    content
                }
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .refreshable { await store.loadIfNeeded(force: true) }
            .navigationDestination(for: Int.self) { id in
                if let car = store.cars.first(where: { $0.id == id }) {
                    CarDetailView(car: car)
                        .modifier(CatalogNavigationZoom(id: id, namespace: carTransitionNamespace, enabled: !reduceMotion))
                }
            }
        }
        .sheet(isPresented: $showFilters) {
            CatalogFilterSheet(status: $status, brand: $brand, layout: $layout)
                .environmentObject(settings)
                .presentationDetents([.large])
                .presentationCornerRadius(34)
        }
        .onAppear {
            applyCatalogIntent()
            Task { await openRequestedCarIfNeeded() }
        }
        .onChange(of: store.catalogIntent?.id) { _, _ in applyCatalogIntent() }
        .onChange(of: store.requestedCarSlug) { _, _ in
            Task { await openRequestedCarIfNeeded() }
        }
        .onChange(of: search) { _, value in UserDefaults.standard.set(value, forKey: "ASUCatalogSearchV1") }
        .onChange(of: status) { _, value in UserDefaults.standard.set(value.rawValue, forKey: "ASUCatalogStatusV1") }
        .onChange(of: brand) { _, value in
            if let value, !value.isEmpty { UserDefaults.standard.set(value, forKey: "ASUCatalogBrandV1") }
            else { UserDefaults.standard.removeObject(forKey: "ASUCatalogBrandV1") }
        }
        .onChange(of: layout) { _, value in UserDefaults.standard.set(value.rawValue, forKey: "ASUCatalogLayoutV1") }
        .alert(L10n.t("Автомобиль не найден", "Avtomobil topilmadi", settings.language), isPresented: $deepLinkFailure) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(L10n.t("Ссылка ведёт на автомобиль, которого больше нет в публичном каталоге.", "Havoladagi avtomobil endi ochiq katalogda mavjud emas.", settings.language))
        }
        .sensoryFeedback(.selection, trigger: status)
        .sensoryFeedback(.selection, trigger: brand)
        .sensoryFeedback(.selection, trigger: layout)
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.t("АВТОМОБИЛЬНЫЙ КАТАЛОГ", "AVTOMOBILLAR KATALOGI", settings.language))
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                .tracking(1.35)
                .foregroundStyle(.secondary)
            Text(L10n.t("Выберите автомобиль.", "Avtomobilni tanlang.", settings.language))
                .asuPageTitle()
            Text(L10n.t(
                "Все опубликованные автомобили Auto Sale Umar в одном месте. Фильтруйте по марке и статусу — без лишних шагов.",
                "Auto Sale Umar’dagi barcha e’lon qilingan avtomobillar bir joyda. Marka va status bo‘yicha tez filtrlang.",
                settings.language
            ))
            .font(.system(size: 14.5))
            .foregroundStyle(.secondary)
            .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, ASUDesign.pagePadding)
    }

    private var searchRow: some View {
        HStack(spacing: 10) {
            ASUGlassSearchField(text: $search, placeholder: L10n.t("Марка, модель", "Marka, model", settings.language))
            ASUGlassIconButton(
                symbol: "slider.horizontal.3",
                size: 52,
                accessibilityLabel: L10n.t("Фильтры", "Filtrlar", settings.language)
            ) { showFilters = true }
            .overlay(alignment: .topTrailing) {
                if activeFilterCount > 0 {
                    Text("\(activeFilterCount)")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 19, height: 19)
                        .background(Color.black, in: Circle())
                        .offset(x: 3, y: -3)
                }
            }
        }
        .padding(.horizontal, ASUDesign.pagePadding)
    }

    private var brandRail: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 9) {
                ASUGlassPillButton(isSelected: brand == nil) { brand = nil } label: {
                    Text(L10n.t("Все марки", "Barcha markalar", settings.language))
                }

                ForEach(ASUHomeContent.brands) { item in
                    ASUGlassPillButton(isSelected: brand == item.name) {
                        withAnimation(reduceMotion ? nil : ASUDesign.spring) { brand = brand == item.name ? nil : item.name }
                    } label: {
                        HStack(spacing: 8) {
                            Image(item.assetName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 25, height: 18)
                                .grayscale(1)
                            Text(item.name)
                                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(.horizontal, ASUDesign.pagePadding)
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private var statusRail: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(CatalogFilterStatus.allCases) { item in
                    ASUGlassPillButton(isSelected: status == item) {
                        withAnimation(reduceMotion ? nil : ASUDesign.spring) { status = item }
                    } label: {
                        HStack(spacing: 6) {
                            if item != .all {
                                Circle()
                                    .fill(item == .available || item == .inShowroom || item == .inStock ? ASUDesign.orange : Color.secondary.opacity(0.65))
                                    .frame(width: 6, height: 6)
                            }
                            Text(item.title(settings.language))
                        }
                    }
                }
            }
            .padding(.horizontal, ASUDesign.pagePadding)
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private var resultsHeader: some View {
        HStack(spacing: 12) {
            Text(countText)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer()
            if dynamicTypeSize.isAccessibilitySize {
                ASUGlassSurface(radius: 16) {
                    Label(L10n.t("Крупный вид", "Katta ko‘rinish", settings.language), systemImage: "textformat.size.larger")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 12)
                        .frame(height: 38)
                }
            } else {
                ASUGlassContainer(spacing: 8) {
                    HStack(spacing: 8) {
                        layoutButton(.grid, symbol: "square.grid.2x2")
                        layoutButton(.wide, symbol: "rectangle.grid.1x2")
                    }
                }
            }
        }
        .padding(.horizontal, ASUDesign.pagePadding)
    }

    private func layoutButton(_ value: CatalogCardLayout, symbol: String) -> some View {
        Button {
            withAnimation(reduceMotion ? nil : ASUDesign.spring) { layout = value }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(layout == value ? Color(uiColor: .systemBackground) : Color.primary)
                .frame(width: 38, height: 38)
                .modifier(CatalogGlassCircle(selected: layout == value))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var content: some View {
        if store.catalogState == .loading && store.cars.isEmpty {
            CatalogSkeleton(layout: effectiveLayout)
                .padding(.horizontal, ASUDesign.pagePadding)
        } else if case .unavailable(let message) = store.catalogState, store.cars.isEmpty {
            ConnectionStateView(message: message) { Task { await store.loadIfNeeded(force: true) } }
        } else if filtered.isEmpty {
            EmptyCatalogView(hasFilters: activeFilterCount > 0 || !search.isEmpty) { resetFilters() }
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

            if effectiveLayout == .grid {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(filtered) { car in
                        NavigationLink(value: car.id) {
                            CarCard(car: car, layout: .grid)
                                .modifier(CatalogMatchedSource(id: car.id, namespace: carTransitionNamespace, enabled: !reduceMotion))
                        }
                        .buttonStyle(.plain)
                        .asuStoryTransition()
                    }
                }
                .padding(.horizontal, ASUDesign.pagePadding)
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(filtered) { car in
                        NavigationLink(value: car.id) {
                            CarCard(car: car, layout: .wide)
                                .modifier(CatalogMatchedSource(id: car.id, namespace: carTransitionNamespace, enabled: !reduceMotion))
                        }
                        .buttonStyle(.plain)
                        .asuStoryTransition()
                    }
                }
                .padding(.horizontal, ASUDesign.pagePadding)
            }
        }
    }

    private var activeFilterCount: Int {
        (status == .all ? 0 : 1) + (brand == nil ? 0 : 1)
    }

    private var countText: String {
        let count = filtered.count
        if settings.language == .uz { return "\(count) ta avtomobil" }
        let mod10 = count % 10
        let mod100 = count % 100
        let noun: String
        if mod10 == 1 && mod100 != 11 { noun = "автомобиль" }
        else if (2...4).contains(mod10) && !(12...14).contains(mod100) { noun = "автомобиля" }
        else { noun = "автомобилей" }
        return "\(count) \(noun)"
    }

    private func resetFilters() {
        withAnimation(reduceMotion ? nil : ASUDesign.spring) {
            search = ""
            status = .all
            brand = nil
        }
    }

    private func applyCatalogIntent() {
        guard let intent = store.catalogIntent else { return }
        brand = intent.brand
        if let target = intent.status {
            status = target == .inStock ? .available : CatalogFilterStatus(carStatus: target)
        } else {
            status = .all
        }
        search = ""
        store.clearCatalogIntent()
    }

    @MainActor
    private func openRequestedCarIfNeeded() async {
        guard let requestedSlug = store.requestedCarSlug else { return }
        if store.cars.isEmpty { await store.loadIfNeeded() }

        let target = store.cars.first { car in
            guard let slug = car.slug else { return false }
            return slug.caseInsensitiveCompare(requestedSlug) == .orderedSame
        }

        store.consumeRequestedCar()
        guard let target else {
            deepLinkFailure = true
            return
        }

        path = NavigationPath()
        path.append(target.id)
    }
}

private struct CatalogMatchedSource: ViewModifier {
    let id: Int
    let namespace: Namespace.ID
    let enabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *), enabled {
            content.matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
    }
}

private struct CatalogNavigationZoom: ViewModifier {
    let id: Int
    let namespace: Namespace.ID
    let enabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *), enabled {
            content.navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            content
        }
    }
}

enum CatalogFilterStatus: String, CaseIterable, Identifiable, Hashable {
    case all
    case available
    case inShowroom = "in_showroom"
    case inStock = "in_stock"
    case inTransit = "in_transit"
    case madeToOrder = "made_to_order"
    case reserved
    case sold

    var id: String { rawValue }

    init(carStatus: CarStatus) {
        switch carStatus {
        case .inShowroom: self = .inShowroom
        case .inStock: self = .inStock
        case .inTransit: self = .inTransit
        case .madeToOrder: self = .madeToOrder
        case .reserved: self = .reserved
        case .sold: self = .sold
        default: self = .all
        }
    }

    func matches(_ value: CarStatus) -> Bool {
        switch self {
        case .all: value != .hidden
        case .available: value == .inShowroom || value == .inStock
        case .inShowroom: value == .inShowroom
        case .inStock: value == .inStock
        case .inTransit: value == .inTransit
        case .madeToOrder: value == .madeToOrder
        case .reserved: value == .reserved
        case .sold: value == .sold
        }
    }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .all: return L10n.t("Все", "Barchasi", language)
        case .available: return L10n.t("Доступны", "Mavjud", language)
        case .inShowroom: return L10n.t("В шоуруме", "Shourumda", language)
        case .inStock: return L10n.t("В наличии", "Omborda", language)
        case .inTransit: return L10n.t("В пути", "Yo‘lda", language)
        case .madeToOrder: return L10n.t("Под заказ", "Buyurtma", language)
        case .reserved: return L10n.t("Резерв", "Rezerv", language)
        case .sold: return L10n.t("Проданы", "Sotilgan", language)
        }
    }
}

private struct CatalogFilterSheet: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @Binding var status: CatalogFilterStatus
    @Binding var brand: String?
    @Binding var layout: CatalogCardLayout

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text(L10n.t("Фильтры", "Filtrlar", settings.language))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .tracking(-0.8)
                    Spacer()
                    ASUGlassIconButton(symbol: "xmark", size: 44, accessibilityLabel: L10n.t("Закрыть", "Yopish", settings.language)) { dismiss() }
                }

                filterSection(L10n.t("Статус", "Holat", settings.language)) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
                        ForEach(CatalogFilterStatus.allCases) { item in
                            selectionButton(item.title(settings.language), selected: status == item) { status = item }
                        }
                    }
                }

                filterSection(L10n.t("Марка", "Marka", settings.language)) {
                    selectionButton(L10n.t("Все марки", "Barcha markalar", settings.language), selected: brand == nil) { brand = nil }
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
                        ForEach(ASUHomeContent.brands) { item in
                            selectionButton(item.name, selected: brand == item.name) { brand = item.name }
                        }
                    }
                }

                filterSection(L10n.t("Вид каталога", "Katalog ko‘rinishi", settings.language)) {
                    HStack(spacing: 9) {
                        selectionButton(L10n.t("Две карточки", "Ikki karta", settings.language), selected: layout == .grid) { layout = .grid }
                        selectionButton(L10n.t("Одна карточка", "Bitta karta", settings.language), selected: layout == .wide) { layout = .wide }
                    }
                }

                Button(L10n.t("Показать автомобили", "Avtomobillarni ko‘rsatish", settings.language)) { dismiss() }
                    .buttonStyle(ASUPrimaryButtonStyle())

                Button(L10n.t("Сбросить", "Tozalash", settings.language)) {
                    status = .all; brand = nil; layout = .grid
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.bottom, 20)
            }
            .padding(20)
        }
    }

    private func filterSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(title).font(.system(size: 12.5, weight: .semibold, design: .rounded)).foregroundStyle(.secondary)
            content()
        }
    }

    private func selectionButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).lineLimit(1).minimumScaleFactor(0.78)
                Spacer(minLength: 6)
                if selected { Image(systemName: "checkmark.circle.fill") }
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(selected ? Color(uiColor: .systemBackground) : Color.primary)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .modifier(CatalogGlassRounded(selected: selected))
        }
        .buttonStyle(.plain)
    }
}

private struct CatalogSkeleton: View {
    let layout: CatalogCardLayout

    var body: some View {
        Group {
            if layout == .grid {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(0..<6, id: \.self) { _ in skeleton(height: 310) }
                }
            } else {
                VStack(spacing: 14) {
                    ForEach(0..<3, id: \.self) { _ in skeleton(height: 390) }
                }
            }
        }
    }

    private func skeleton(height: CGFloat) -> some View {
        ASUImageSkeleton()
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: layout == .grid ? 24 : 30, style: .continuous))
    }
}

private struct CatalogGlassCircle: ViewModifier {
    let selected: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if selected { content.glassEffect(.regular.tint(Color.primary).interactive(), in: Circle()) }
            else { content.glassEffect(.regular.interactive(), in: Circle()) }
        } else {
            if selected { content.background(Color.primary, in: Circle()) }
            else { content.background(.ultraThinMaterial, in: Circle()).overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.6)) }
        }
    }
}

private struct CatalogGlassRounded: ViewModifier {
    let selected: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 17, style: .continuous)
        if #available(iOS 26.0, *) {
            if selected { content.glassEffect(.regular.tint(Color.primary).interactive(), in: shape) }
            else { content.glassEffect(.regular.interactive(), in: shape) }
        } else {
            if selected { content.background(Color.primary, in: shape) }
            else { content.background(.ultraThinMaterial, in: shape).overlay(shape.stroke(Color.white.opacity(0.2), lineWidth: 0.6)) }
        }
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
            Text(settings.language == .ru ? message : "Auto Sale Umar katalogiga ulanish imkoni bo‘lmadi. Internet aloqasini tekshirib, qayta urinib ko‘ring.")
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
