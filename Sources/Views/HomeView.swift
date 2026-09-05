import SwiftUI

private enum HomeAnchor: String {
    case top
    case cars
    case showroom
    case contacts
}

struct HomeView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: AppStore
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    let selectTab: (AppTab) -> Void

    @State private var showRequest = false
    @State private var showBooking = false
    @State private var showCompare = false
    @State private var showMenu = false
    @State private var heroMuted = true
    @State private var heroReveal = false
    @State private var scrollTarget: HomeAnchor?
    @State private var digitalIndex = 0
    @State private var homeBrand: String? = nil

    private var introURL: URL? {
        Bundle.main.url(forResource: "intro", withExtension: "mp4")
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        heroBlock
                            .id(HomeAnchor.top.rawValue)

                        brandSection
                            .id(HomeAnchor.cars.rawValue)

                        inventorySection(
                            kicker: L10n.t("В ШОУРУМЕ", "SHOURUMDA", settings.language),
                            title: L10n.t("Можно посмотреть сегодня.", "Bugun ko‘rish mumkin.", settings.language),
                            text: L10n.t(
                                "Автомобили, которые сейчас находятся в шоуруме и доступны для просмотра.",
                                "Hozir shourumda turgan va ko‘rish uchun mavjud avtomobillar.",
                                settings.language
                            ),
                            cars: homeFiltered(store.showroomCars),
                            status: .inShowroom
                        )

                        inventorySection(
                            kicker: L10n.t("В НАЛИЧИИ", "MAVJUD", settings.language),
                            title: L10n.t("Без ожидания поставки.", "Yetkazib berishni kutmasdan.", settings.language),
                            text: L10n.t(
                                "Автомобили в шоуруме и на складе, которые можно купить без ожидания приезда.",
                                "Shourum va ombordagi, kelishini kutmasdan xarid qilish mumkin bo‘lgan avtomobillar.",
                                settings.language
                            ),
                            cars: homeFiltered(store.stockCars),
                            status: .inStock
                        )

                        requestSection

                        inventorySection(
                            kicker: L10n.t("В ПУТИ", "YO‘LDA", settings.language),
                            title: L10n.t("Следующее поступление.", "Keyingi kelish.", settings.language),
                            text: L10n.t(
                                "Следите за автомобилями, которые уже направляются в шоурум.",
                                "Shourumga yo‘l olgan avtomobillarni kuzating.",
                                settings.language
                            ),
                            cars: homeFiltered(store.transitCars),
                            status: .inTransit
                        )

                        compareSection

                        showroomSection
                            .id(HomeAnchor.showroom.rawValue)

                        deliverySection

                        soldSection

                        digitalSection

                        contactsSection
                            .id(HomeAnchor.contacts.rawValue)

                        legacySection

                        closingSection

                        itTeamSection

                        footer
                    }
                    .padding(.bottom, 30)
                }
                .scrollIndicators(.hidden)
                .refreshable { await store.loadIfNeeded(force: true) }
                .background(ASUDesign.page)
                .onChange(of: scrollTarget) { _, target in
                    guard let target else { return }
                    withAnimation(ASUDesign.softSpring) {
                        proxy.scrollTo(target.rawValue, anchor: .top)
                    }
                    scrollTarget = nil
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                ASUFloatingHeader { showMenu = true }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
            }
            .navigationDestination(for: Int.self) { id in
                if let car = store.cars.first(where: { $0.id == id }) {
                    CarDetailView(car: car)
                }
            }
        }
        .sheet(isPresented: $showRequest) { NavigationStack { RequestCarView() } }
        .sheet(isPresented: $showBooking) { NavigationStack { BookingView() } }
        .sheet(isPresented: $showCompare) { CompareView() }
        .sheet(isPresented: $showMenu) {
            ASUHomeMenuSheet(
                openCatalog: { openCatalog() },
                openShowroom: { scrollTarget = .showroom },
                openContacts: { scrollTarget = .contacts },
                openBooking: { showBooking = true }
            )
        }
    }

    private var heroBlock: some View {
        VStack(spacing: 0) {
            heroMedia
                .padding(.horizontal, 14)
                .padding(.top, 4)

            heroStatement
                .padding(.top, 40)
        }
        .padding(.bottom, 50)
    }

    private var heroMedia: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                Image("IntroPoster")
                    .resizable()
                    .scaledToFill()

                if let introURL {
                    ASUVideoSurface(
                        url: introURL,
                        isMuted: heroMuted,
                        shouldPlay: true,
                        loops: true,
                        gravity: .resizeAspectFill
                    )
                }

                LinearGradient(
                    colors: [.black.opacity(0.42), .clear, .black.opacity(0.58)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(height: 350)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))

            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AUTO SALE UMAR")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.74))
                    Text("TASHKENT")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Spacer()

                Button {
                    withAnimation(.easeOut(duration: ASUDesign.microDuration)) {
                        heroMuted.toggle()
                    }
                } label: {
                    Image(systemName: heroMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(.black.opacity(0.28), in: Circle())
                        .overlay(Circle().stroke(.white.opacity(0.24), lineWidth: 0.7))
                }
                .buttonStyle(.plain)
            }
            .padding(18)
        }
        .shadow(color: .black.opacity(0.14), radius: 30, y: 16)
    }

    private var heroStatement: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text(L10n.t("AUTO SALE UMAR · TASHKENT", "AUTO SALE UMAR · TOSHKENT", settings.language))
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                .tracking(1.45)
                .foregroundStyle(.secondary)

            Text(L10n.t("Автомобиль,\nвыбранный точно.", "Aniq tanlangan\navtomobil.", settings.language))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .tracking(-2.1)
                .lineSpacing(-5)

            Text(L10n.t(
                "Новые автомобили в наличии и в пути. Международный подбор, прозрачный статус и персональное сопровождение.",
                "Mavjud va yo‘ldagi yangi avtomobillar. Xalqaro tanlov, shaffof status va shaxsiy kuzatuv.",
                settings.language
            ))
            .font(.system(size: 17))
            .foregroundStyle(.secondary)
            .lineSpacing(5)

            HStack(spacing: 10) {
                Button {
                    openCatalog()
                } label: {
                    Label(L10n.t("Смотреть автомобили", "Avtomobillarni ko‘rish", settings.language), systemImage: "car.side")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 16)
                        .frame(height: 48)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color(uiColor: .systemBackground))
                .background(Color.primary, in: Capsule())

                ASUGlassPillButton {
                    openURL(URL(string: "https://wa.me/\(AppConfig.whatsappPhone)")!)
                } label: {
                    Label(L10n.t("Связаться", "Bog‘lanish", settings.language), systemImage: "message")
                }
            }
        }
        .padding(.horizontal, 22)
        .opacity(heroReveal ? 1 : 0)
        .offset(y: heroReveal ? 0 : 18)
        .onAppear {
            guard !heroReveal else { return }
            if reduceMotion {
                heroReveal = true
            } else {
                withAnimation(.easeOut(duration: ASUDesign.storyDuration)) {
                    heroReveal = true
                }
            }
        }
    }

    private var brandSection: some View {
        VStack(spacing: 22) {
            ASUHomeSectionHeader(
                kicker: L10n.t("ВЫБЕРИТЕ МАРКУ", "MARKANI TANLANG", settings.language),
                title: L10n.t("Начните с характера.", "Xarakterdan boshlang.", settings.language),
                text: L10n.t(
                    "Коллекция формируется из автомобилей, которые действительно есть в базе Auto Sale Umar.",
                    "Kolleksiya Auto Sale Umar bazasida haqiqatan mavjud bo‘lgan avtomobillardan shakllanadi.",
                    settings.language
                )
            )

            ScrollView(.horizontal) {
                ASUGlassContainer(spacing: 14) {
                    LazyHStack(spacing: 12) {
                        ASUGlassActionTile {
                        withAnimation(ASUDesign.spring) { homeBrand = nil }
                    } label: {
                        VStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 28, weight: .light))
                            Text(L10n.t("Все", "Barchasi", settings.language))
                                .font(.system(size: 13.5, weight: .bold, design: .rounded))
                        }
                        .frame(width: 142, height: 132)
                    }
                    .overlay {
                        if homeBrand == nil {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(ASUDesign.orange.opacity(0.72), lineWidth: 1.2)
                        }
                    }

                    ForEach(ASUHomeContent.brands) { item in
                        ASUGlassActionTile {
                            withAnimation(ASUDesign.spring) {
                                homeBrand = homeBrand == item.name ? nil : item.name
                            }
                        } label: {
                            VStack(spacing: 10) {
                                Image(item.assetName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 102, height: 66)
                                Text(item.name)
                                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)
                            }
                            .frame(width: 142, height: 132)
                        }
                        .overlay {
                            if homeBrand == item.name {
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(ASUDesign.orange.opacity(0.72), lineWidth: 1.2)
                            }
                        }
                    }
                    }
                    .padding(.horizontal, ASUDesign.pagePadding)
                    .padding(.vertical, 4)
                }
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
        }
        .padding(.bottom, ASUDesign.sectionSpacing)
    }

    @ViewBuilder
    private func inventorySection(kicker: String, title: String, text: String, cars: [Car], status: CarStatus) -> some View {
        VStack(spacing: 20) {
            ASUHomeSectionHeader(
                kicker: kicker,
                title: title,
                text: text,
                actionTitle: L10n.t("Посмотреть все", "Barchasini ko‘rish", settings.language)
            ) {
                openCatalog(brand: homeBrand, status: status)
            }

            if cars.isEmpty {
                ASUGlassPanel(radius: 28, padding: 18) {
                    HStack(spacing: 14) {
                        Image(systemName: "car.side")
                            .font(.system(size: 28, weight: .light))
                            .foregroundStyle(.secondary)
                        Text(L10n.t(
                            "Опубликованные автомобили появятся здесь автоматически.",
                            "E’lon qilingan avtomobillar bu yerda avtomatik paydo bo‘ladi.",
                            settings.language
                        ))
                        .font(.system(size: 14.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, ASUDesign.pagePadding)
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 14) {
                        ForEach(cars.prefix(8)) { car in
                            NavigationLink(value: car.id) {
                                ASUHomeCarCard(car: car)
                            }
                            .buttonStyle(.plain)
                            .asuStoryTransition(axis: .horizontal)
                        }
                    }
                    .padding(.horizontal, ASUDesign.pagePadding)
                    .padding(.bottom, 10)
                }
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned)
            }
        }
        .padding(.bottom, ASUDesign.sectionSpacing)
    }

    private var requestSection: some View {
        ASUGlassPanel(radius: 32, padding: 22) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(L10n.t("ПЕРСОНАЛЬНЫЙ ПОДБОР", "SHAXSIY TANLOV", settings.language))
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.system(size: 26, weight: .light))
                }

                Text(L10n.t("Не нашли нужный автомобиль?", "Kerakli avtomobilni topmadingizmi?", settings.language))
                    .asuSectionTitle(size: 31)

                Text(L10n.t(
                    "Укажите марку, модель, бюджет и срок покупки. Команда Auto Sale Umar начнёт поиск под ваш запрос.",
                    "Marka, model, budjet va xarid muddatini kiriting. Auto Sale Umar jamoasi siz uchun qidiruvni boshlaydi.",
                    settings.language
                ))
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .lineSpacing(4)

                Button(L10n.t("Найти автомобиль", "Avtomobil topish", settings.language)) {
                    showRequest = true
                }
                .buttonStyle(ASUPrimaryButtonStyle())
            }
        }
        .padding(.horizontal, ASUDesign.pagePadding)
        .padding(.bottom, ASUDesign.sectionSpacing)
    }

    private var compareSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.black, Color(red: 0.08, green: 0.08, blue: 0.09)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(ASUDesign.orange.opacity(0.18))
                .frame(width: 190, height: 190)
                .blur(radius: 38)
                .offset(x: 115, y: -90)

            VStack(alignment: .leading, spacing: 14) {
                Label(L10n.t("СРАВНИТЕ ПЕРЕД ВЫБОРОМ", "TANLOVDAN OLDIN SOLISHTIRING", settings.language), systemImage: "arrow.left.arrow.right")
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .tracking(1.15)
                    .foregroundStyle(.white.opacity(0.66))

                Text(L10n.t("Два автомобиля.\nОдин понятный выбор.", "Ikki avtomobil.\nBitta tushunarli tanlov.", settings.language))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .tracking(-0.9)
                    .foregroundStyle(.white)

                Text(L10n.t(
                    "Сопоставьте цену, характеристики и комплектации реальных автомобилей Auto Sale Umar. Консультант поможет разобраться в деталях только по вашему запросу.",
                    "Auto Sale Umar’dagi real avtomobillarning narxi, xususiyatlari va komplektatsiyalarini solishtiring. Maslahatchi faqat sizning so‘rovingiz bo‘yicha tafsilotlarni tushuntiradi.",
                    settings.language
                ))
                .font(.system(size: 14.5))
                .foregroundStyle(.white.opacity(0.68))
                .lineSpacing(3)

                Button {
                    showCompare = true
                } label: {
                    HStack {
                        Text(L10n.t("Сравнить автомобили", "Avtomobillarni solishtirish", settings.language))
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 18)
                    .frame(height: 50)
                    .background(.white, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(22)
        }
        .frame(minHeight: 300)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .padding(.horizontal, ASUDesign.pagePadding)
        .padding(.bottom, ASUDesign.sectionSpacing)
    }

    private var showroomSection: some View {
        VStack(spacing: 22) {
            ASUHomeSectionHeader(
                kicker: L10n.t("О ШОУРУМЕ", "SHOURUM HAQIDA", settings.language),
                title: L10n.t("Пространство для спокойного выбора.", "Xotirjam tanlov uchun makon.", settings.language),
                text: L10n.t(
                    "Автомобиль остаётся в центре внимания, а атмосфера даёт время рассмотреть детали и принять решение без спешки.",
                    "Avtomobil markazda qoladi, muhit esa detallarni ko‘rish va shoshilmasdan qaror qilish uchun vaqt beradi.",
                    settings.language
                )
            )

            ScrollView(.horizontal) {
                LazyHStack(spacing: 14) {
                    ForEach(ASUHomeContent.showroomStories) { story in
                        ASUShowroomStoryCard(story: story)
                            .asuStoryTransition(axis: .horizontal)
                    }
                }
                .padding(.horizontal, ASUDesign.pagePadding)
                .padding(.bottom, 10)
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)

            ASUGlassPanel(radius: 30, padding: 20) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(L10n.t("МЕСТОПОЛОЖЕНИЕ", "MANZIL", settings.language))
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(.secondary)
                    Text(L10n.t("Забронируйте персональный просмотр.", "Shaxsiy ko‘rikni band qiling.", settings.language))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Text(L10n.t(
                        "Выберите дату и время — команда шоурума подготовит визит.",
                        "Sana va vaqtni tanlang — shourum jamoasi tashrifni tayyorlaydi.",
                        settings.language
                    ))
                    .font(.system(size: 14.5))
                    .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        Button {
                            showBooking = true
                        } label: {
                            Label(L10n.t("Визит", "Tashrif", settings.language), systemImage: "calendar")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(ASUPrimaryButtonStyle())

                        ASUGlassIconButton(symbol: "location.fill", size: 56, accessibilityLabel: L10n.t("Маршрут", "Yo‘l", settings.language)) {
                            openURL(AppConfig.yandexMaps)
                        }
                    }
                }
            }
            .padding(.horizontal, ASUDesign.pagePadding)
        }
        .padding(.bottom, ASUDesign.sectionSpacing)
    }

    private var deliverySection: some View {
        VStack(spacing: 22) {
            ASUHomeSectionHeader(
                kicker: L10n.t("МЕЖДУНАРОДНАЯ ПОСТАВКА", "XALQARO YETKAZIB BERISH", settings.language),
                title: L10n.t("Ищем автомобиль там, где он есть.", "Avtomobil qayerda bo‘lsa, o‘sha yerdan izlaymiz.", settings.language),
                text: L10n.t(
                    "Привозим новые автомобили под заказ из США, Канады, Кореи, ОАЭ, Европы, Великобритании и Австралии.",
                    "AQSH, Kanada, Koreya, BAA, Yevropa, Buyuk Britaniya va Avstraliyadan yangi avtomobillarni buyurtma asosida olib kelamiz.",
                    settings.language
                )
            )

            ASUGlassPanel(radius: 34, padding: 0) {
                VStack(spacing: 0) {
                    Image("WorldMap")
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal, 18)
                        .padding(.top, 18)

                    VStack(spacing: 12) {
                        deliveryStep("01", L10n.t("Подбор под задачу", "Vazifa bo‘yicha tanlov", settings.language), L10n.t("Ищем нужную модель, комплектацию и цвет на подходящем рынке.", "Kerakli model, komplektatsiya va rangni mos bozordan izlaymiz.", settings.language))
                        deliveryStep("02", L10n.t("Понятный путь", "Tushunarli yo‘l", settings.language), L10n.t("Фиксируем источник поставки и поддерживаем актуальный статус автомобиля.", "Yetkazib berish manbasini belgilaymiz va avtomobil statusini yangilab boramiz.", settings.language))
                        deliveryStep("03", L10n.t("До передачи ключей", "Kalit topshirilgunga qadar", settings.language), L10n.t("Сопровождаем логистику и держим клиента в курсе до прибытия.", "Logistikani kuzatamiz va avtomobil yetib kelguniga qadar xabardor qilamiz.", settings.language))
                    }
                    .padding(18)
                }
            }
            .padding(.horizontal, ASUDesign.pagePadding)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(ASUHomeContent.markets) { market in
                        ASUGlassSurface(radius: 18) {
                            HStack(spacing: 7) {
                                Text(market.flag)
                                Text(market.title(settings.language))
                                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                            }
                            .padding(.horizontal, 13)
                            .frame(height: 40)
                        }
                    }
                }
                .padding(.horizontal, ASUDesign.pagePadding)
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.bottom, ASUDesign.sectionSpacing)
    }

    private func deliveryStep(_ number: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 13) {
            Text(number)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(ASUDesign.orange)
                .frame(width: 34, height: 34)
                .background(ASUDesign.orange.opacity(0.10), in: Circle())
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Text(text)
                    .font(.system(size: 13.5))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var soldSection: some View {
        let cars = homeFiltered(store.soldCars)
        if !cars.isEmpty {
            VStack(spacing: 20) {
                ASUHomeSectionHeader(
                    kicker: L10n.t("УЖЕ НАШЛИ СВОИХ ВЛАДЕЛЬЦЕВ", "O‘Z EGALARINI TOPGAN AVTOMOBILLAR", settings.language),
                    title: L10n.t("Эти автомобили уже проданы.", "Bu avtomobillar allaqachon sotilgan.", settings.language),
                    text: L10n.t(
                        "Часть истории Auto Sale Umar — реальные автомобили, которые уже переданы своим владельцам.",
                        "Auto Sale Umar tarixining bir qismi — allaqachon egalariga topshirilgan real avtomobillar.",
                        settings.language
                    )
                )

                ScrollView(.horizontal) {
                    LazyHStack(spacing: 14) {
                        ForEach(cars.prefix(10)) { car in
                            NavigationLink(value: car.id) {
                                ASUHomeCarCard(car: car)
                                    .saturation(0.72)
                            }
                            .buttonStyle(.plain)
                            .asuStoryTransition(axis: .horizontal)
                        }
                    }
                    .padding(.horizontal, ASUDesign.pagePadding)
                    .padding(.bottom, 10)
                }
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned)
            }
            .padding(.bottom, ASUDesign.sectionSpacing)
        }
    }

    private var digitalSection: some View {
        VStack(spacing: 20) {
            ASUHomeSectionHeader(
                kicker: L10n.t("ЭКОСИСТЕМА AUTO SALE UMAR", "AUTO SALE UMAR EKOTIZIMI", settings.language),
                title: L10n.t("Сайт и приложение работают как одна система.", "Sayt va ilova bitta tizim sifatida ishlaydi.", settings.language),
                text: L10n.t(
                    "Каталог, статусы, цены и карточки автомобилей связаны в единый цифровой контур.",
                    "Katalog, statuslar, narxlar va avtomobil kartalari yagona raqamli konturda ishlaydi.",
                    settings.language
                )
            )

            ASUGlassPanel(radius: 34, padding: 0) {
                VStack(spacing: 10) {
                    TabView(selection: $digitalIndex) {
                        ForEach(Array(ASUHomeContent.digitalStories.enumerated()), id: \.offset) { index, story in
                            ASUDigitalStoryCard(story: story)
                                .tag(index)
                        }
                    }
                    .frame(height: 390)
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    HStack(spacing: 7) {
                        ForEach(ASUHomeContent.digitalStories.indices, id: \.self) { index in
                            Capsule()
                                .fill(index == digitalIndex ? Color.primary : Color.secondary.opacity(0.28))
                                .frame(width: index == digitalIndex ? 24 : 7, height: 7)
                                .animation(ASUDesign.spring, value: digitalIndex)
                        }
                    }
                    .padding(.bottom, 16)

                    HStack(spacing: 10) {
                        Button {
                            openCatalog()
                        } label: {
                            Text(L10n.t("Открыть каталог", "Katalogni ochish", settings.language))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(ASUPrimaryButtonStyle())

                        ASUGlassIconButton(symbol: "sparkles", size: 56, accessibilityLabel: L10n.t("Подбор", "Tanlov", settings.language)) {
                            showRequest = true
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .padding(.horizontal, ASUDesign.pagePadding)
        }
        .padding(.bottom, ASUDesign.sectionSpacing)
    }

    private var contactsSection: some View {
        VStack(spacing: 20) {
            ASUHomeSectionHeader(
                kicker: L10n.t("КОНТАКТЫ", "KONTAKTLAR", settings.language),
                title: L10n.t("Продолжим там, где удобно вам.", "Sizga qulay joyda davom etamiz.", settings.language),
                text: L10n.t(
                    "Instagram остаётся главным каналом обзоров. Для консультации можно написать или позвонить напрямую.",
                    "Instagram asosiy avtomobil sharhlari kanali. Maslahat uchun yozish yoki qo‘ng‘iroq qilish mumkin.",
                    settings.language
                )
            )

            ASUGlassContainer(spacing: 10) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ASUContactTile(symbol: "camera", title: "Instagram", detail: "@auto_sale_umar") {
                        openURL(AppConfig.instagram)
                    }
                    ASUContactTile(symbol: "paperplane.fill", title: "Telegram", detail: "auto_sale_umar777") {
                        openURL(AppConfig.telegram)
                    }
                    ASUContactTile(symbol: "message.fill", title: "WhatsApp", detail: AppConfig.phoneDisplay) {
                        openURL(URL(string: "https://wa.me/\(AppConfig.whatsappPhone)")!)
                    }
                    ASUContactTile(symbol: "phone.fill", title: L10n.t("Позвонить", "Qo‘ng‘iroq", settings.language), detail: AppConfig.phoneDisplay) {
                        openURL(URL(string: "tel:\(AppConfig.phone)")!)
                    }
                }
            }
            .padding(.horizontal, ASUDesign.pagePadding)
        }
        .padding(.bottom, ASUDesign.sectionSpacing)
    }

    private var legacySection: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(Color.black)

            Circle()
                .fill(ASUDesign.orange.opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 45)
                .offset(x: 190, y: -120)

            Text("25")
                .font(.system(size: 180, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.04))
                .offset(x: 150, y: 18)

            VStack(alignment: .leading, spacing: 14) {
                Text(L10n.t("25 ЛЕТ В АВТОМОБИЛЬНОЙ СФЕРЕ", "AVTOMOBIL SOHASIDA 25 YIL", settings.language))
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .tracking(1.15)
                    .foregroundStyle(.white.opacity(0.58))

                Text(L10n.t("Доверие, которое\nвыдерживает время.", "Vaqt sinovidan o‘tgan\nishonch.", settings.language))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .tracking(-1)
                    .foregroundStyle(.white)

                Text(L10n.t(
                    "Опыт Auto Sale Umar — это привычка отвечать за выбор, детали и результат.",
                    "Auto Sale Umar tajribasi — tanlov, tafsilot va natija uchun javob berish odati.",
                    settings.language
                ))
                .font(.system(size: 14.5))
                .foregroundStyle(.white.opacity(0.66))
                .lineSpacing(4)

                Image("WordmarkWhite")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 178)
                    .padding(.top, 8)
            }
            .padding(24)
        }
        .frame(minHeight: 390)
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .padding(.horizontal, ASUDesign.pagePadding)
        .padding(.bottom, ASUDesign.sectionSpacing)
    }

    private var closingSection: some View {
        Image("BentleyClosing")
            .resizable()
            .scaledToFill()
            .frame(height: 560)
            .clipped()
            .overlay(alignment: .bottomLeading) {
                LinearGradient(colors: [.clear, .black.opacity(0.52)], startPoint: .center, endPoint: .bottom)
                    .overlay(alignment: .bottomLeading) {
                        Image("WordmarkWhite")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 190)
                            .padding(22)
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .padding(.horizontal, 14)
            .padding(.bottom, ASUDesign.sectionSpacing)
    }

    private var itTeamSection: some View {
        ASUGlassActionTile {
            openURL(AppConfig.website.appending(path: "it-team/"))
        } label: {
            HStack(spacing: 14) {
                Image("DeveloperPortrait")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("IT TEAM")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(.secondary)
                    Text("AutoSale Umar IT Team")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text("Abdulaziz.developer")
                        .font(.system(size: 12.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
        }
        .padding(.horizontal, ASUDesign.pagePadding)
        .padding(.bottom, 32)
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Image(colorScheme == .dark ? "WordmarkWhite" : "WordmarkBlack")
                .resizable()
                .scaledToFit()
                .frame(width: 180)
            Text(L10n.t(
                "Премиальные автомобили. Точный выбор. Персональное сопровождение.",
                "Premium avtomobillar. Aniq tanlov. Shaxsiy kuzatuv.",
                settings.language
            ))
            .font(.system(size: 12.5, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            Text("Auto Sale Umar 2026 · All rights reserved.")
                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
    }

    private func homeFiltered(_ cars: [Car]) -> [Car] {
        guard let homeBrand else { return cars }
        return cars.filter { $0.brand == homeBrand }
    }

    private func openCatalog(brand: String? = nil, status: CarStatus? = nil) {
        store.requestCatalog(brand: brand, status: status)
        selectTab(.catalog)
    }
}
