import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: AppStore
    let selectTab: (AppTab) -> Void
    @State private var showRequest = false
    @State private var showBooking = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 22) {
                    BrandHeader(trailingSymbol: "bell") {}
                    hero
                    quickActions
                    latest
                    selectionCard
                    showroomCard
                    deliveryCard
                }
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .refreshable { await store.loadIfNeeded(force: true) }
            .background(ASUDesign.page)
            .navigationDestination(for: Int.self) { id in
                if let car = store.cars.first(where: { $0.id == id }) { CarDetailView(car: car) }
            }
        }
        .sheet(isPresented: $showRequest) { NavigationStack { RequestCarView() } }
        .sheet(isPresented: $showBooking) { NavigationStack { BookingView() } }
    }

    @ViewBuilder
    private var hero: some View {
        if let car = store.featuredCar {
            NavigationLink(value: car.id) {
                VStack(spacing: 0) {
                    ZStack(alignment: .topLeading) {
                        CarImage(url: car.primaryImageURL, height: 272)
                        StatusPill(status: car.status, language: settings.language)
                            .padding(16)
                    }
                    HStack(alignment: .bottom, spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(car.displayName)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .tracking(-0.75)
                                .lineLimit(2)
                            Text(Format.price(car, language: settings.language))
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        ASUGlassSurface(radius: 20) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 17, weight: .bold))
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(17)
                }
                .asuCard(radius: 32)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, ASUDesign.pagePadding)
        } else {
            VStack(alignment: .leading, spacing: 17) {
                Text(L10n.t("АВТОМОБИЛЬНЫЙ ШОУРУМ", "AVTOMOBIL SHOURUMI", settings.language))
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .tracking(1.25)
                    .foregroundStyle(.secondary)
                Text(L10n.t("Автомобиль,\nвыбранный точно.", "Aniq tanlangan\navtomobil.", settings.language))
                    .font(.system(size: 39, weight: .bold, design: .rounded))
                    .tracking(-1.35)
                Text(L10n.t("Премиальные автомобили, прозрачный статус и персональное сопровождение.", "Premium avtomobillar, aniq holat va shaxsiy hamrohlik.", settings.language))
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                Button { selectTab(.catalog) } label: {
                    Label(L10n.t("Открыть каталог", "Katalogni ochish", settings.language), systemImage: "car.side")
                }
                .buttonStyle(ASUPrimaryButtonStyle())
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Color.primary.opacity(0.02), Color.primary.opacity(0.075)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .asuCard(radius: 32)
            .padding(.horizontal, ASUDesign.pagePadding)
        }
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            quick("car.fill", L10n.t("В наличии", "Mavjud", settings.language)) { selectTab(.catalog) }
            quick("shippingbox.fill", L10n.t("В пути", "Yo‘lda", settings.language)) { selectTab(.catalog) }
            quick("sparkles", L10n.t("Подбор", "Tanlov", settings.language)) { showRequest = true }
            quick("calendar", L10n.t("Визит", "Tashrif", settings.language)) { showBooking = true }
        }
        .padding(.horizontal, ASUDesign.pagePadding)
    }

    private func quick(_ symbol: String, _ title: String, action: @escaping () -> Void) -> some View {
        ASUGlassActionTile(action: action) {
            VStack(spacing: 8) {
                Image(systemName: symbol).font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 74)
        }
    }

    @ViewBuilder
    private var latest: some View {
        if !store.cars.isEmpty {
            VStack(spacing: 12) {
                HStack {
                    Text(L10n.t("Последние поступления", "So‘nggi avtomobillar", settings.language))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Spacer()
                    Button(L10n.t("Все", "Barchasi", settings.language)) { selectTab(.catalog) }
                        .font(.system(size: 13, weight: .semibold))
                }
                .padding(.horizontal, ASUDesign.pagePadding)

                ScrollView(.horizontal) {
                    LazyHStack(spacing: 12) {
                        ForEach(Array(store.cars.prefix(6))) { car in
                            NavigationLink(value: car.id) {
                                CarCard(car: car)
                                    .frame(width: 220)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, ASUDesign.pagePadding)
                    .padding(.bottom, 8)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private var selectionCard: some View {
        editorialCard(
            eyebrow: L10n.t("ПЕРСОНАЛЬНЫЙ ПОДБОР", "SHAXSIY TANLOV", settings.language),
            title: L10n.t("Не нашли нужный автомобиль?", "Kerakli avtomobil topilmadimi?", settings.language),
            text: L10n.t("Укажите модель, бюджет и срок. Команда Auto Sale Umar начнёт поиск под ваш запрос.", "Model, budjet va muddatni ko‘rsating. Auto Sale Umar jamoasi siz uchun qidirishni boshlaydi.", settings.language),
            symbol: "sparkles",
            button: L10n.t("Найти автомобиль", "Avtomobil topish", settings.language)
        ) { showRequest = true }
    }

    private var showroomCard: some View {
        editorialCard(
            eyebrow: L10n.t("ШОУРУМ · ТАШКЕНТ", "SHOURUM · TOSHKENT", settings.language),
            title: L10n.t("Пространство для спокойного выбора.", "Xotirjam tanlov uchun makon.", settings.language),
            text: L10n.t("Посмотрите автомобиль вживую и забронируйте удобное время визита.", "Avtomobilni jonli ko‘ring va tashrif vaqtini band qiling.", settings.language),
            symbol: "building.2",
            button: L10n.t("Забронировать визит", "Tashrifni band qilish", settings.language)
        ) { showBooking = true }
    }

    private var deliveryCard: some View {
        editorialCard(
            eyebrow: L10n.t("МЕЖДУНАРОДНАЯ ПОСТАВКА", "XALQARO YETKAZIB BERISH", settings.language),
            title: L10n.t("Ищем автомобиль там, где он есть.", "Avtomobilni bor joyidan topamiz.", settings.language),
            text: L10n.t("США · Канада · Корея · ОАЭ · Европа · Великобритания · Австралия", "AQSH · Kanada · Koreya · BAA · Yevropa · Buyuk Britaniya · Avstraliya", settings.language),
            symbol: "globe",
            button: L10n.t("Оставить запрос", "So‘rov qoldirish", settings.language)
        ) { showRequest = true }
    }

    private func editorialCard(eyebrow: String, title: String, text: String, symbol: String, button: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(eyebrow)
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.secondary)
                Spacer()
                ASUGlassSurface(radius: 18) {
                    Image(systemName: symbol)
                        .font(.system(size: 20, weight: .medium))
                        .frame(width: 42, height: 42)
                }
            }
            Text(title).font(.system(size: 26, weight: .bold, design: .rounded)).tracking(-0.65)
            Text(text).font(.system(size: 15)).foregroundStyle(.secondary).lineSpacing(3)
            Button(button, action: action).buttonStyle(ASUPrimaryButtonStyle())
        }
        .padding(22)
        .asuCard()
        .padding(.horizontal, ASUDesign.pagePadding)
    }
}
