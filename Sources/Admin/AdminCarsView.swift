import SwiftUI

struct ASUAdminCarsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject var session: ASUAdminSessionStore

    @State private var cars: [ASUAdminCarRecord] = []
    @State private var availableBrands: [String] = []
    @State private var total = 0
    @State private var query = ""
    @State private var brand: String?
    @State private var status: ASUAdminCarStatusFilter = .all
    @State private var country: ASUAdminCarCountryFilter = .all
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var reloadToken = 0
    @State private var showFilters = false
    @State private var selectedCar: ASUAdminCarRecord?
    @State private var quickEditCar: ASUAdminCarRecord?

    private let api = ASUAdminAPI()

    private var loadKey: String {
        "\(query)|\(brand ?? "")|\(status.rawValue)|\(country.rawValue)|\(reloadToken)"
    }

    private var activeFilterCount: Int {
        (brand == nil ? 0 : 1) + (status == .all ? 0 : 1) + (country == .all ? 0 : 1)
    }

    private var metricColumns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 22) {
                hero
                searchAndFilters
                statusRail

                if isLoading && cars.isEmpty {
                    loadingState
                } else if let errorMessage, cars.isEmpty {
                    errorState(errorMessage)
                } else {
                    overview
                    carsSection
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 36)
        }
        .scrollIndicators(.hidden)
        .background(ASUDesign.page)
        .navigationTitle(L10n.t("Автомобили", "Avtomobillar", settings.language))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .refreshable { await loadCars(silent: true, debounce: false) }
        .task(id: loadKey) {
            await loadCars(silent: !cars.isEmpty, debounce: !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .sheet(isPresented: $showFilters) {
            ASUAdminCarsFilterView(
                brand: $brand,
                status: $status,
                country: $country,
                brands: availableBrands
            )
            .environmentObject(settings)
        }
        .sheet(item: $quickEditCar) { car in
            ASUAdminCarQuickEditor(session: session, car: car) { updated in
                applyUpdated(updated)
            }
            .environmentObject(settings)
        }
        .sheet(item: $selectedCar) { car in
            NavigationStack {
                ASUAdminCarDetailView(session: session, car: currentCar(for: car.id) ?? car) { carToEdit in
                    selectedCar = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        quickEditCar = currentCar(for: carToEdit.id) ?? carToEdit
                    }
                }
                .environmentObject(settings)
            }
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.black, Color(red: 0.065, green: 0.065, blue: 0.075)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(ASUDesign.success.opacity(0.20))
                .frame(width: 190, height: 190)
                .blur(radius: 42)
                .offset(x: 170, y: -100)

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Text("CONTROL SYSTEM")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .tracking(1.2)
                    Spacer()
                    HStack(spacing: 6) {
                        Circle().fill(ASUDesign.success).frame(width: 7, height: 7)
                        Text("D1 LIVE")
                    }
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .tracking(0.8)
                }
                .foregroundStyle(.white.opacity(0.58))

                VStack(alignment: .leading, spacing: 7) {
                    Text(L10n.t("Автомобили", "Avtomobillar", settings.language))
                        .font(.system(size: 37, weight: .bold, design: .rounded))
                        .tracking(-1.2)
                        .foregroundStyle(.white)
                    Text(L10n.t(
                        "Единая рабочая база: статус, цена, публикация, VIN и фотографии конкретных автомобилей.",
                        "Yagona ishchi baza: aniq avtomobillarning statusi, narxi, e’loni, VIN va suratlari.",
                        settings.language
                    ))
                    .font(.system(size: 14.5))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineSpacing(4)
                }

                HStack(spacing: 10) {
                    heroMetric(value: total, title: L10n.t("в базе", "bazada", settings.language))
                    heroMetric(value: cars.count, title: L10n.t("показано", "ko‘rsatildi", settings.language))
                    heroMetric(value: activeFilterCount, title: L10n.t("фильтра", "filtr", settings.language))
                }
            }
            .padding(21)
        }
        .frame(minHeight: 278)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 0.7))
    }

    private func heroMetric(value: Int, title: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("\(value)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
            Text(title)
                .font(.system(size: 9.5, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.50))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .padding(.horizontal, 12)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var searchAndFilters: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                ASUGlassSearchField(text: $query, placeholder: L10n.t("Марка, модель, VIN", "Marka, model, VIN", settings.language))
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

            ScrollView(.horizontal) {
                HStack(spacing: 9) {
                    adminBrandChip(title: L10n.t("Все марки", "Barcha markalar", settings.language), selected: brand == nil) {
                        withAnimation(reduceMotion ? nil : ASUDesign.spring) { brand = nil }
                    }
                    ForEach(availableBrands, id: \.self) { item in
                        adminBrandChip(title: item, selected: brand == item) {
                            withAnimation(reduceMotion ? nil : ASUDesign.spring) {
                                brand = brand == item ? nil : item
                            }
                        }
                    }
                }
                .padding(.vertical, 3)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func adminBrandChip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let asset = brandAsset(title) {
                    Image(asset)
                        .resizable()
                        .scaledToFit()
                        .grayscale(1)
                        .frame(width: 30, height: 22)
                }
                Text(title)
                    .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundStyle(selected ? Color(uiColor: .systemBackground) : Color.primary)
            .padding(.horizontal, 15)
            .frame(height: 48)
            .modifier(ASUAdminCarsCapsule(selected: selected))
        }
        .buttonStyle(.plain)
    }

    private var statusRail: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(ASUAdminCarStatusFilter.allCases) { item in
                    Button {
                        withAnimation(reduceMotion ? nil : ASUDesign.spring) { status = item }
                    } label: {
                        HStack(spacing: 7) {
                            if let carStatus = item.carStatus {
                                Circle().fill(statusColor(carStatus)).frame(width: 8, height: 8)
                            }
                            Text(item.title(settings.language))
                                .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(status == item ? Color(uiColor: .systemBackground) : Color.primary)
                        .padding(.horizontal, 15)
                        .frame(height: 44)
                        .modifier(ASUAdminCarsCapsule(selected: status == item))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private var overview: some View {
        LazyVGrid(columns: metricColumns, spacing: 10) {
            metricCard(
                title: L10n.t("Опубликованы", "E’lon qilingan", settings.language),
                value: cars.filter { $0.isPublic }.count,
                symbol: "eye",
                detail: L10n.t("видны клиентам", "mijozlarga ko‘rinadi", settings.language)
            )
            metricCard(
                title: L10n.t("В шоуруме", "Shourumda", settings.language),
                value: cars.filter { $0.status == .inShowroom }.count,
                symbol: "building.2",
                detail: L10n.t("доступны сегодня", "bugun mavjud", settings.language)
            )
            metricCard(
                title: L10n.t("В пути", "Yo‘lda", settings.language),
                value: cars.filter { $0.status == .inTransit }.count,
                symbol: "shippingbox",
                detail: L10n.t("ожидают прибытия", "yetib kelmoqda", settings.language)
            )
            metricCard(
                title: L10n.t("Резерв / проданы", "Rezerv / sotilgan", settings.language),
                value: cars.filter { $0.status == .reserved || $0.status == .sold }.count,
                symbol: "checkmark.seal",
                detail: L10n.t("закрытые позиции", "yopilgan pozitsiyalar", settings.language)
            )
        }
    }

    private func metricCard(title: String, value: Int, symbol: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(value)")
                    .font(.system(size: 29, weight: .bold, design: .rounded))
                    .tracking(-0.8)
            }
            Text(title)
                .font(.system(size: 14.5, weight: .bold, design: .rounded))
            Text(detail)
                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 126, alignment: .topLeading)
        .padding(15)
        .asuCard(radius: 24, shadow: false)
    }

    private var carsSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.t("БАЗА АВТОМОБИЛЕЙ", "AVTOMOBILLAR BAZASI", settings.language))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.15)
                        .foregroundStyle(.secondary)
                    Text(countText)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isLoading { ProgressView().controlSize(.small) }
            }

            if let errorMessage, !cars.isEmpty {
                HStack(spacing: 9) {
                    Image(systemName: "wifi.exclamationmark")
                    Text(errorMessage).lineLimit(2)
                    Spacer(minLength: 8)
                    Button(L10n.t("Повторить", "Qayta", settings.language)) { reloadToken += 1 }
                }
                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(12)
                .asuCard(radius: 20, shadow: false)
            }

            if cars.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 13) {
                    ForEach(cars) { car in
                        ASUAdminCarCard(
                            car: car,
                            language: settings.language,
                            statusColor: statusColor,
                            mediaURL: mediaURL,
                            brandAsset: brandAsset(car.brand),
                            open: { selectedCar = car },
                            quickEdit: { quickEditCar = car }
                        )
                    }
                }
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(ASUDesign.elevated)
                    .frame(height: 306)
                    .overlay { ProgressView().controlSize(.small) }
            }
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(L10n.t("Не удалось загрузить автомобили", "Avtomobillarni yuklab bo‘lmadi", settings.language), systemImage: "exclamationmark.triangle")
                .font(.system(size: 18, weight: .bold, design: .rounded))
            Text(message)
                .font(.system(size: 13.5))
                .foregroundStyle(.secondary)
            Button(L10n.t("Повторить", "Qayta urinish", settings.language)) { reloadToken += 1 }
                .buttonStyle(ASUPrimaryButtonStyle(prominent: false))
        }
        .padding(18)
        .asuCard(radius: 28)
    }

    private var emptyState: some View {
        VStack(spacing: 13) {
            ASUGlassCircleSurface(size: 78) {
                Image(systemName: "car.side")
                    .font(.system(size: 28, weight: .light))
            }
            Text(L10n.t("Ничего не найдено", "Hech narsa topilmadi", settings.language))
                .font(.system(size: 21, weight: .bold, design: .rounded))
            Text(L10n.t("Измените поиск или фильтры каталога.", "Qidiruv yoki katalog filtrlarini o‘zgartiring.", settings.language))
                .font(.system(size: 13.5))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(L10n.t("Сбросить фильтры", "Filtrlarni tozalash", settings.language)) { resetFilters() }
                .buttonStyle(ASUPrimaryButtonStyle(prominent: false))
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .asuCard(radius: 28)
    }

    private var countText: String {
        if settings.language == .uz { return "\(cars.count) ta avtomobil" }
        let value = cars.count
        let mod10 = value % 10
        let mod100 = value % 100
        if mod10 == 1 && mod100 != 11 { return "\(value) автомобиль" }
        if (2...4).contains(mod10) && !(12...14).contains(mod100) { return "\(value) автомобиля" }
        return "\(value) автомобилей"
    }

    @MainActor
    private func loadCars(silent: Bool, debounce: Bool) async {
        if debounce {
            do {
                try await Task.sleep(nanoseconds: 280_000_000)
                try Task.checkCancellation()
            } catch {
                return
            }
        }

        guard let token = session.bearerToken else {
            session.invalidateSession()
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let snapshot = try await api.cars(
                query: query,
                brand: brand,
                status: status,
                country: country,
                token: token
            )
            try Task.checkCancellation()
            cars = snapshot.cars
            total = snapshot.total
            availableBrands = snapshot.brands
        } catch is CancellationError {
            return
        } catch let error as ASUAdminAPI.APIError {
            if error.shouldDiscardSession {
                session.invalidateSession(notice: error.localizedDescription)
            } else {
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyUpdated(_ updated: ASUAdminCarRecord) {
        if let index = cars.firstIndex(where: { $0.id == updated.id }) {
            cars[index] = updated
        }
        if selectedCar?.id == updated.id { selectedCar = updated }
        quickEditCar = nil
    }

    private func currentCar(for id: Int) -> ASUAdminCarRecord? {
        cars.first(where: { $0.id == id })
    }

    private func resetFilters() {
        withAnimation(reduceMotion ? nil : ASUDesign.spring) {
            query = ""
            brand = nil
            status = .all
            country = .all
        }
    }

    private func mediaURL(_ value: String?) -> URL? {
        guard let raw = value?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
        if let absolute = URL(string: raw), absolute.scheme != nil { return absolute }
        if raw.hasPrefix("/") { return AppConfig.website.appending(path: String(raw.dropFirst())) }
        return AppConfig.website.appending(path: raw)
    }

    private func brandAsset(_ brand: String) -> String? {
        ASUHomeContent.brands.first { $0.name.caseInsensitiveCompare(brand) == .orderedSame }?.assetName
    }

    private func statusColor(_ status: CarStatus) -> Color {
        switch status {
        case .inStock, .inShowroom: return ASUDesign.success
        case .reserved: return ASUDesign.orange
        case .sold, .hidden: return Color.secondary.opacity(0.85)
        case .inTransit, .madeToOrder: return Color.secondary.opacity(0.68)
        case .unknown: return Color.secondary.opacity(0.55)
        }
    }
}

private struct ASUAdminCarCard: View {
    let car: ASUAdminCarRecord
    let language: AppLanguage
    let statusColor: (CarStatus) -> Color
    let mediaURL: (String?) -> URL?
    let brandAsset: String?
    let open: () -> Void
    let quickEdit: () -> Void

    @State private var photoIndex = 0

    private var photos: [String] { Array(car.allExteriorPhotoValues.prefix(6)) }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: open) {
                VStack(spacing: 0) {
                    media
                    copy
                }
                .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            }
            .buttonStyle(.plain)

            Divider().padding(.horizontal, 16)

            HStack(spacing: 10) {
                Button(action: open) {
                    Label(L10n.t("Открыть", "Ochish", language), systemImage: "rectangle.expand.vertical")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ASUPrimaryButtonStyle(prominent: false))

                Button(action: quickEdit) {
                    Label(L10n.t("Статус и цена", "Status va narx", language), systemImage: "slider.horizontal.3")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ASUPrimaryButtonStyle())
            }
            .padding(14)
        }
        .asuCard(radius: 28)
    }

    private var media: some View {
        ZStack(alignment: .bottom) {
            if photos.count > 1 {
                TabView(selection: $photoIndex) {
                    ForEach(photos.indices, id: \.self) { index in
                        ASURemoteImage(url: mediaURL(photos[index]), contentMode: .fit, background: ASUDesign.gallery, padding: 10)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            } else {
                ASURemoteImage(url: mediaURL(photos.first ?? car.coverUrl), contentMode: .fit, background: ASUDesign.gallery, padding: 10)
            }

            if photos.count > 1 {
                HStack(spacing: 5) {
                    ForEach(photos.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == photoIndex ? Color.primary.opacity(0.82) : Color.secondary.opacity(0.25))
                            .frame(width: index == photoIndex ? 18 : 5, height: 5)
                    }
                }
                .padding(.horizontal, 8)
                .frame(height: 20)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.bottom, 9)
            }
        }
        .frame(height: 210)
        .clipped()
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                if let brandAsset {
                    Image(brandAsset)
                        .resizable()
                        .scaledToFit()
                        .grayscale(1)
                        .frame(width: 38, height: 30)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(car.brand.uppercased())
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(.secondary)
                    Text(car.model)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .tracking(-0.55)
                        .lineLimit(2)
                }
                Spacer(minLength: 8)
                Text("ID \(car.id)")
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            if let trim = car.trim, !trim.isEmpty {
                Text(trim)
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                adminPill(statusTitle, dot: statusColor(car.status))
                adminPill(car.isPublic ? L10n.t("Опубликован", "E’lon qilingan", language) : L10n.t("Черновик", "Qoralama", language), dot: car.isPublic ? ASUDesign.success : Color.secondary.opacity(0.7))
                if car.isFeatured { adminPill(L10n.t("Избранный", "Tavsiya", language), dot: ASUDesign.orange) }
            }

            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.t("ЦЕНА", "NARX", language))
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(.tertiary)
                    Text(priceText)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .tracking(-0.4)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(L10n.t("VIN / STOCK", "VIN / STOCK", language))
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(.tertiary)
                    Text(car.vin ?? car.stockNumber ?? "—")
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(16)
    }

    private var statusTitle: String { car.status.adminTitle(language) }

    private var priceText: String {
        if car.priceOnRequest || car.price == nil { return L10n.t("Цена по запросу", "Narx so‘rov bo‘yicha", language) }
        return "\(formatNumber(car.price ?? 0)) \(currencySymbol(car.currency))"
    }

    private func adminPill(_ text: String, dot: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(dot).frame(width: 7, height: 7)
            Text(text)
                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .frame(height: 29)
        .background(ASUDesign.soft, in: Capsule())
        .overlay(Capsule().stroke(ASUDesign.line, lineWidth: 0.6))
    }
}

private struct ASUAdminCarsFilterView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @Binding var brand: String?
    @Binding var status: ASUAdminCarStatusFilter
    @Binding var country: ASUAdminCarCountryFilter
    let brands: [String]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    filterSection(L10n.t("Статус", "Holat", settings.language)) {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
                            ForEach(ASUAdminCarStatusFilter.allCases) { item in
                                selectionButton(item.title(settings.language), selected: status == item) { status = item }
                            }
                        }
                    }

                    filterSection(L10n.t("Страна", "Davlat", settings.language)) {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
                            ForEach(ASUAdminCarCountryFilter.allCases) { item in
                                selectionButton(item.title(settings.language), selected: country == item) { country = item }
                            }
                        }
                    }

                    filterSection(L10n.t("Марка", "Marka", settings.language)) {
                        selectionButton(L10n.t("Все марки", "Barcha markalar", settings.language), selected: brand == nil) { brand = nil }
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
                            ForEach(brands, id: \.self) { item in
                                selectionButton(item, selected: brand == item) { brand = item }
                            }
                        }
                    }

                    Button(L10n.t("Показать автомобили", "Avtomobillarni ko‘rsatish", settings.language)) { dismiss() }
                        .buttonStyle(ASUPrimaryButtonStyle())

                    Button(L10n.t("Сбросить", "Tozalash", settings.language)) {
                        brand = nil
                        status = .all
                        country = .all
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 18)
                }
                .padding(20)
            }
            .background(ASUDesign.page)
            .navigationTitle(L10n.t("Фильтры", "Filtrlar", settings.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.t("Готово", "Tayyor", settings.language)) { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationCornerRadius(34)
    }

    private func filterSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func selectionButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title).lineLimit(1).minimumScaleFactor(0.72)
                Spacer(minLength: 4)
                if selected { Image(systemName: "checkmark.circle.fill") }
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(selected ? Color(uiColor: .systemBackground) : Color.primary)
            .padding(.horizontal, 13)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .modifier(ASUAdminCarsRounded(selected: selected))
        }
        .buttonStyle(.plain)
    }
}

private struct ASUAdminCarQuickEditor: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var session: ASUAdminSessionStore

    let car: ASUAdminCarRecord
    let onSaved: (ASUAdminCarRecord) -> Void

    @State private var status: CarStatus
    @State private var priceText: String
    @State private var currency: String
    @State private var priceOnRequest: Bool
    @State private var isPublic: Bool
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let api = ASUAdminAPI()
    private let editableStatuses: [CarStatus] = [.inStock, .inShowroom, .inTransit, .madeToOrder, .reserved, .sold, .hidden]

    init(session: ASUAdminSessionStore, car: ASUAdminCarRecord, onSaved: @escaping (ASUAdminCarRecord) -> Void) {
        self.session = session
        self.car = car
        self.onSaved = onSaved
        _status = State(initialValue: car.status)
        _priceText = State(initialValue: car.price.map { String($0) } ?? "")
        _currency = State(initialValue: car.currency)
        _priceOnRequest = State(initialValue: car.priceOnRequest)
        _isPublic = State(initialValue: car.isPublic)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    headerCard
                    statusSection
                    priceSection
                    publicationSection

                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .font(.system(size: 13.5, weight: .medium, design: .rounded))
                            .foregroundStyle(.red)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }

                    Button {
                        Task { await save() }
                    } label: {
                        HStack {
                            if isSaving { ProgressView().tint(Color(uiColor: .systemBackground)) }
                            Text(isSaving ? L10n.t("Сохранение…", "Saqlanmoqda…", settings.language) : L10n.t("Сохранить изменения", "O‘zgarishlarni saqlash", settings.language))
                        }
                    }
                    .buttonStyle(ASUPrimaryButtonStyle())
                    .disabled(isSaving)
                }
                .padding(20)
            }
            .background(ASUDesign.page)
            .navigationTitle(L10n.t("Статус и цена", "Status va narx", settings.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.t("Закрыть", "Yopish", settings.language)) { dismiss() }
                        .disabled(isSaving)
                }
            }
        }
        .interactiveDismissDisabled(isSaving)
        .presentationDetents([.large])
        .presentationCornerRadius(34)
    }

    private var headerCard: some View {
        HStack(spacing: 14) {
            ASUGlassCircleSurface(size: 58) {
                Image(systemName: "car.side")
                    .font(.system(size: 21, weight: .semibold))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("ID \(car.id) · \(car.brand.uppercased())")
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.secondary)
                Text(car.model)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .tracking(-0.45)
                if let trim = car.trim, !trim.isEmpty {
                    Text(trim).font(.system(size: 12.5)).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(16)
        .asuCard(radius: 26)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(L10n.t("СТАТУС", "STATUS", settings.language))
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.15)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
                ForEach(editableStatuses, id: \.rawValue) { item in
                    Button { status = item } label: {
                        HStack(spacing: 7) {
                            Circle().fill(statusColor(item)).frame(width: 8, height: 8)
                            Text(item.adminTitle(settings.language)).lineLimit(1).minimumScaleFactor(0.72)
                            Spacer(minLength: 4)
                            if status == item { Image(systemName: "checkmark") }
                        }
                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(status == item ? Color(uiColor: .systemBackground) : Color.primary)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .modifier(ASUAdminCarsRounded(selected: status == item))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.t("ЦЕНА", "NARX", settings.language))
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.15)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                TextField("258000", text: $priceText)
                    .keyboardType(.numberPad)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .disabled(priceOnRequest)
                    .padding(.horizontal, 14)
                    .frame(height: 54)
                    .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))

                Picker("Currency", selection: $currency) {
                    Text("USD").tag("USD")
                    Text("UZS").tag("UZS")
                    Text("EUR").tag("EUR")
                }
                .pickerStyle(.menu)
                .frame(width: 92, height: 54)
                .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .disabled(priceOnRequest)
            }
            .opacity(priceOnRequest ? 0.48 : 1)

            Toggle(isOn: $priceOnRequest) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.t("Цена по запросу", "Narx so‘rov bo‘yicha", settings.language))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    Text(L10n.t("Числовая цена будет скрыта", "Raqamli narx yashiriladi", settings.language))
                        .font(.system(size: 11.5)).foregroundStyle(.secondary)
                }
            }
            .tint(ASUDesign.success)
        }
        .padding(16)
        .asuCard(radius: 26, shadow: false)
    }

    private var publicationSection: some View {
        Toggle(isOn: $isPublic) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.t("Опубликован", "E’lon qilingan", settings.language))
                    .font(.system(size: 15.5, weight: .bold, design: .rounded))
                Text(L10n.t(
                    "Опубликованный автомобиль виден клиентам. Для публикации на сервере должна быть фотография кузова.",
                    "E’lon qilingan avtomobil mijozlarga ko‘rinadi. E’lon qilish uchun serverda kuzov surati bo‘lishi kerak.",
                    settings.language
                ))
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
                .lineSpacing(3)
            }
        }
        .tint(ASUDesign.success)
        .padding(16)
        .asuCard(radius: 26, shadow: false)
    }

    @MainActor
    private func save() async {
        guard let token = session.bearerToken else {
            session.invalidateSession()
            return
        }

        let parsedPrice: Int64?
        if priceOnRequest {
            parsedPrice = nil
        } else {
            let clean = priceText.filter { $0.isNumber }
            guard let value = Int64(clean), value >= 0 else {
                errorMessage = L10n.t("Проверьте цену автомобиля.", "Avtomobil narxini tekshiring.", settings.language)
                return
            }
            parsedPrice = value
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            let patch = try await api.updateCar(
                id: car.id,
                update: ASUAdminCarQuickUpdate(
                    status: status,
                    price: parsedPrice,
                    currency: currency,
                    priceOnRequest: priceOnRequest,
                    isPublic: isPublic
                ),
                token: token
            )
            let updated = car.applying(patch)
            onSaved(updated)
            dismiss()
        } catch let error as ASUAdminAPI.APIError {
            if error.shouldDiscardSession {
                session.invalidateSession(notice: error.localizedDescription)
                dismiss()
            } else {
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func statusColor(_ status: CarStatus) -> Color {
        switch status {
        case .inStock, .inShowroom: return ASUDesign.success
        case .reserved: return ASUDesign.orange
        case .sold, .hidden: return Color.secondary.opacity(0.82)
        case .inTransit, .madeToOrder: return Color.secondary.opacity(0.68)
        case .unknown: return Color.secondary.opacity(0.55)
        }
    }
}

private struct ASUAdminCarDetailView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var session: ASUAdminSessionStore
    let car: ASUAdminCarRecord
    let quickEdit: (ASUAdminCarRecord) -> Void

    @State private var photoIndex = 0
    @State private var variantIndex = 0

    private var variants: [ASUAdminCarVariant] { car.variants }
    private var activeVariant: ASUAdminCarVariant? {
        guard !variants.isEmpty else { return nil }
        return variants[min(variantIndex, variants.count - 1)]
    }
    private var photos: [ASUAdminCarPhoto] { activeVariant?.exteriorPhotos ?? [] }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                detailHero
                adminFacts
                variantsSection
                descriptions
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 34)
        }
        .scrollIndicators(.hidden)
        .background(ASUDesign.page)
        .navigationTitle(car.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(L10n.t("Закрыть", "Yopish", settings.language)) { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    quickEdit(car)
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel(L10n.t("Статус и цена", "Status va narx", settings.language))
            }
        }
    }

    private var detailHero: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                if !photos.isEmpty {
                    TabView(selection: $photoIndex) {
                        ForEach(photos.indices, id: \.self) { index in
                            ASURemoteImage(url: mediaURL(photos[index].url), contentMode: .fit, background: ASUDesign.gallery, padding: 10)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                } else {
                    ASURemoteImage(url: mediaURL(car.coverUrl), contentMode: .fit, background: ASUDesign.gallery, padding: 10)
                }

                if photos.count > 1 {
                    Text("\(photoIndex + 1) / \(photos.count)")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .padding(.horizontal, 11)
                        .frame(height: 30)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 10)
                }
            }
            .frame(height: 248)

            VStack(alignment: .leading, spacing: 13) {
                Text("ID \(car.id) · \(car.brand.uppercased())")
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(.secondary)
                Text(car.model)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .tracking(-0.9)
                if let trim = car.trim, !trim.isEmpty {
                    Text(trim).font(.system(size: 13.5)).foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    statusPill
                    publishedPill
                }

                HStack(alignment: .lastTextBaseline) {
                    Text(priceText)
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .tracking(-0.55)
                    Spacer()
                    Button(L10n.t("Изменить", "O‘zgartirish", settings.language)) { quickEdit(car) }
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
            }
            .padding(17)
        }
        .asuCard(radius: 30)
    }

    private var adminFacts: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.t("ДАННЫЕ ПОЗИЦИИ", "POZITSIYA MA’LUMOTLARI", settings.language))
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.1)
                .foregroundStyle(.secondary)

            factRow(L10n.t("VIN", "VIN", settings.language), car.vin ?? activeVariant?.vin ?? "—")
            factRow(L10n.t("Внутренний номер", "Ichki raqam", settings.language), car.stockNumber ?? activeVariant?.stockNumber ?? "—")
            factRow(L10n.t("Год", "Yil", settings.language), car.year.map { String($0) } ?? "—")
            factRow(L10n.t("Страна", "Davlat", settings.language), countryTitle(car.countryCode))
            factRow(L10n.t("Прибытие", "Yetib kelish", settings.language), car.arrivalDate ?? "—")
            factRow(L10n.t("Пробег", "Yurgan masofa", settings.language), "\(car.mileageKm) km")
            factRow(L10n.t("Двигатель", "Dvigatel", settings.language), car.engineText ?? "—")
            factRow(L10n.t("Привод", "Yuritma", settings.language), car.driveType ?? "—")
            factRow(L10n.t("Трансмиссия", "Transmissiya", settings.language), car.transmission ?? "—")
            factRow(L10n.t("Обновлено", "Yangilandi", settings.language), compactDate(car.updatedAt))
        }
        .padding(17)
        .asuCard(radius: 28)
    }

    @ViewBuilder
    private var variantsSection: some View {
        if !variants.isEmpty {
            VStack(alignment: .leading, spacing: 13) {
                Text(L10n.t("ВАРИАНТЫ", "VARIANTLAR", settings.language))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal) {
                    HStack(spacing: 9) {
                        ForEach(variants.indices, id: \.self) { index in
                            let variant = variants[index]
                            Button {
                                variantIndex = index
                                photoIndex = 0
                            } label: {
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(Color(asuHex: variant.exteriorSwatch, fallback: .primary))
                                        .frame(width: 32, height: 32)
                                        .overlay(Circle().stroke(ASUDesign.lineStrong, lineWidth: 0.7))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(variant.exteriorColorName ?? L10n.t("Цвет", "Rang", settings.language))
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        Text("VIN: \(variant.vin ?? "—")")
                                            .font(.system(size: 9.5, design: .rounded))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .foregroundStyle(variantIndex == index ? Color(uiColor: .systemBackground) : Color.primary)
                                .padding(.horizontal, 12)
                                .frame(height: 58)
                                .modifier(ASUAdminCarsRounded(selected: variantIndex == index))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            .padding(17)
            .asuCard(radius: 28)
        }
    }

    @ViewBuilder
    private var descriptions: some View {
        let text = settings.language == .ru ? car.descriptionRu : (car.descriptionUz ?? car.descriptionRu)
        if let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.t("ОПИСАНИЕ", "TAVSIF", settings.language))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(.secondary)
                Text(text)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            }
            .padding(17)
            .asuCard(radius: 28)
        }
    }

    private var statusPill: some View {
        HStack(spacing: 6) {
            Circle().fill(statusColor(car.status)).frame(width: 7, height: 7)
            Text(car.status.adminTitle(settings.language))
        }
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(ASUDesign.soft, in: Capsule())
    }

    private var publishedPill: some View {
        HStack(spacing: 6) {
            Circle().fill(car.isPublic ? ASUDesign.success : Color.secondary.opacity(0.7)).frame(width: 7, height: 7)
            Text(car.isPublic ? L10n.t("Опубликован", "E’lon qilingan", settings.language) : L10n.t("Черновик", "Qoralama", settings.language))
        }
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(ASUDesign.soft, in: Capsule())
    }

    private var priceText: String {
        if car.priceOnRequest || car.price == nil { return L10n.t("Цена по запросу", "Narx so‘rov bo‘yicha", settings.language) }
        return "\(formatNumber(car.price ?? 0)) \(currencySymbol(car.currency))"
    }

    private func factRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.system(size: 12.5, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
        .padding(.vertical, 4)
    }

    private func mediaURL(_ value: String?) -> URL? {
        guard let raw = value?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
        if let absolute = URL(string: raw), absolute.scheme != nil { return absolute }
        if raw.hasPrefix("/") { return AppConfig.website.appending(path: String(raw.dropFirst())) }
        return AppConfig.website.appending(path: raw)
    }

    private func countryTitle(_ code: String?) -> String {
        guard let code, let filter = ASUAdminCarCountryFilter(rawValue: code) else { return code ?? "—" }
        return filter.title(settings.language)
    }

    private func compactDate(_ raw: String) -> String {
        let value = raw.replacingOccurrences(of: "T", with: " ")
        return String(value.prefix(16))
    }

    private func statusColor(_ status: CarStatus) -> Color {
        switch status {
        case .inStock, .inShowroom: return ASUDesign.success
        case .reserved: return ASUDesign.orange
        case .sold, .hidden: return Color.secondary.opacity(0.82)
        case .inTransit, .madeToOrder: return Color.secondary.opacity(0.68)
        case .unknown: return Color.secondary.opacity(0.55)
        }
    }
}

private struct ASUAdminCarsCapsule: ViewModifier {
    let selected: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if selected {
                content.glassEffect(.regular.tint(Color.primary).interactive(), in: Capsule())
            } else {
                content.glassEffect(.regular.interactive(), in: Capsule())
            }
        } else {
            if selected {
                content.background(Color.primary, in: Capsule())
            } else {
                content
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.20), lineWidth: 0.7))
            }
        }
    }
}

private struct ASUAdminCarsRounded: ViewModifier {
    let selected: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        if #available(iOS 26.0, *) {
            if selected {
                content.glassEffect(.regular.tint(Color.primary).interactive(), in: shape)
            } else {
                content.glassEffect(.regular.interactive(), in: shape)
            }
        } else {
            if selected {
                content.background(Color.primary, in: shape)
            } else {
                content
                    .background(.ultraThinMaterial, in: shape)
                    .overlay(shape.stroke(Color.white.opacity(0.20), lineWidth: 0.7))
            }
        }
    }
}

private func formatNumber(_ value: Int64) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.groupingSeparator = " "
    formatter.maximumFractionDigits = 0
    return formatter.string(from: NSNumber(value: value)) ?? String(value)
}

private func currencySymbol(_ currency: String) -> String {
    switch currency.uppercased() {
    case "USD": return "$"
    case "EUR": return "€"
    case "UZS": return "сум"
    default: return currency
    }
}
