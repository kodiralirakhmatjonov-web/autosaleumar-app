import SwiftUI
import Foundation

struct LocationView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.openURL) private var openURL
    @State private var showBooking = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                hero
                navigationTiles
                showroomGallery
                visitCard
            }
            .padding(.horizontal, ASUDesign.pagePadding)
            .padding(.bottom, 34)
        }
        .background(ASUDesign.page)
        .navigationTitle(L10n.t("Локация", "Lokatsiya", settings.language))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBooking) { NavigationStack { BookingView() } }
    }

    private var hero: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                Image("Showroom01")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 290)
                    .clipped()
                LinearGradient(colors: [.clear, .black.opacity(0.78)], startPoint: .center, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 7) {
                    Text("AUTO SALE UMAR · TASHKENT")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(L10n.t("Локация\nшоурума.", "Shourum\nlokatsiyasi.", settings.language))
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .tracking(-1.1)
                        .foregroundStyle(.white)
                    Text(L10n.t(
                        "Приезжайте посмотреть автомобиль в спокойной обстановке.",
                        "Avtomobilni xotirjam muhitda ko‘rish uchun keling.",
                        settings.language
                    ))
                    .font(.system(size: 14.5))
                    .foregroundStyle(.white.opacity(0.72))
                }
                .padding(20)
            }

            HStack(spacing: 10) {
                Button { openURL(AppConfig.yandexMaps) } label: {
                    Label(L10n.t("Яндекс Карты", "Yandex Xaritalar", settings.language), systemImage: "map.fill")
                }
                .buttonStyle(ASUPrimaryButtonStyle())

                ASUGlassIconButton(symbol: "calendar", size: 56, accessibilityLabel: L10n.t("Забронировать визит", "Tashrifni band qilish", settings.language)) {
                    showBooking = true
                }
            }
            .padding(16)
        }
        .asuCard(radius: 32)
    }

    private var navigationTiles: some View {
        HStack(spacing: 10) {
            locationTile("01", L10n.t("Автомобили", "Avtomobillar", settings.language), L10n.t("В наличии и в пути", "Mavjud va yo‘lda", settings.language), "car.2")
            locationTile("02", L10n.t("Шоурум", "Shourum", settings.language), L10n.t("Auto Sale Umar", "Auto Sale Umar", settings.language), "building.2")
            Button { openURL(AppConfig.yandexMaps) } label: {
                locationTileContent("03", L10n.t("Маршрут", "Yo‘nalish", settings.language), L10n.t("Открыть карту", "Xaritani ochish", settings.language), "location.fill")
                    .modifier(LocationGlassTile())
            }
            .buttonStyle(.plain)
        }
    }

    private func locationTile(_ number: String, _ title: String, _ caption: String, _ symbol: String) -> some View {
        locationTileContent(number, title, caption, symbol)
            .modifier(LocationGlassTile())
    }

    private func locationTileContent(_ number: String, _ title: String, _ caption: String, _ symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Text(number).font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(.secondary); Spacer(); Image(systemName: symbol).font(.system(size: 16, weight: .semibold)) }
            Text(title).font(.system(size: 13.5, weight: .bold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.8)
            Text(caption).font(.system(size: 10.5, design: .rounded)).foregroundStyle(.secondary).lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
        .padding(12)
    }

    private var showroomGallery: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.t("ШОУРУМ", "SHOURUM", settings.language))
                .font(.system(size: 10.5, weight: .bold, design: .rounded)).tracking(1).foregroundStyle(.secondary)
            Text(L10n.t("Сначала почувствуйте автомобиль.", "Avval avtomobilni his qiling.", settings.language))
                .asuSectionTitle(size: 29)
            Text(L10n.t("Посмотрите детали, салон и комплектацию вживую, а команда шоурума подготовит автомобиль к вашему визиту.", "Detallar, salon va komplektatsiyani jonli ko‘ring. Shourum jamoasi avtomobilni tashrifingizga tayyorlaydi.", settings.language))
                .font(.system(size: 14.5)).foregroundStyle(.secondary).lineSpacing(3)

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    showroomImage("Showroom02")
                    showroomImage("Showroom03")
                    showroomImage("Showroom04")
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private func showroomImage(_ name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFill()
            .frame(width: 300, height: 205)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .asuStoryTransition(axis: .horizontal)
    }

    private var visitCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text(L10n.t("ПЕРЕД ВИЗИТОМ", "TASHRIFDAN OLDIN", settings.language))
                .font(.system(size: 10.5, weight: .bold, design: .rounded)).tracking(1).foregroundStyle(.secondary)
            Text(L10n.t("Мы подготовим автомобиль заранее.", "Avtomobilni oldindan tayyorlaymiz.", settings.language))
                .font(.system(size: 25, weight: .bold, design: .rounded))
            Text(L10n.t("Выберите удобное время или свяжитесь с командой Auto Sale Umar напрямую.", "Qulay vaqtni tanlang yoki Auto Sale Umar jamoasi bilan to‘g‘ridan-to‘g‘ri bog‘laning.", settings.language))
                .font(.system(size: 14.5)).foregroundStyle(.secondary).lineSpacing(3)
            Button(L10n.t("Забронировать визит", "Tashrifni band qilish", settings.language)) { showBooking = true }
                .buttonStyle(ASUPrimaryButtonStyle())
            Button { openURL(URL(string: "tel:\(AppConfig.phone)")!) } label: { Label(AppConfig.phoneDisplay, systemImage: "phone.fill") }
                .buttonStyle(ASUPrimaryButtonStyle(prominent: false))
        }
        .padding(20)
        .asuCard(radius: 30)
    }
}

struct TrustView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var showBooking = false
    let openCatalog: () -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 26) {
                trustHero
                story
                principles
                today
                finalCard
            }
            .padding(.horizontal, ASUDesign.pagePadding)
            .padding(.bottom, 34)
        }
        .background(ASUDesign.page)
        .navigationTitle(L10n.t("Доверие", "Ishonch", settings.language))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBooking) { NavigationStack { BookingView() } }
    }

    private var trustHero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(LinearGradient(colors: [.black, Color(red: 0.07, green: 0.07, blue: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().fill(ASUDesign.orange.opacity(0.22)).frame(width: 230, height: 230).blur(radius: 50).offset(x: 130, y: -120)
            VStack(alignment: .leading, spacing: 15) {
                Text(L10n.t("AUTO SALE UMAR · 25 ЛЕТ ОПЫТА", "AUTO SALE UMAR · 25 YIL TAJRIBA", settings.language))
                    .font(.system(size: 10.5, weight: .bold, design: .rounded)).tracking(1).foregroundStyle(.white.opacity(0.62))
                Text(L10n.t("Доверие не появляется\nза один день.", "Ishonch bir kunda\npaydo bo‘lmaydi.", settings.language))
                    .font(.system(size: 35, weight: .bold, design: .rounded)).tracking(-1).foregroundStyle(.white)
                Text(L10n.t("25 лет в автомобильной сфере формируют не только опыт. Они формируют стандарт: понимать автомобиль, уважать выбор клиента и отвечать за результат.", "Avtomobil sohasidagi 25 yil faqat tajriba emas. Bu avtomobilni tushunish, mijoz tanlovini hurmat qilish va natija uchun javob berish standartidir.", settings.language))
                    .font(.system(size: 14.5)).foregroundStyle(.white.opacity(0.68)).lineSpacing(3)
                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    Text("25").font(.system(size: 72, weight: .bold, design: .rounded)).tracking(-3)
                    Text(L10n.t("лет опыта\nв автомобильной сфере", "yil tajriba\navtomobil sohasida", settings.language))
                        .font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.62))
                }
                .foregroundStyle(.white)
            }
            .padding(22)
        }
        .frame(minHeight: 420)
    }

    private var story: some View {
        VStack(alignment: .leading, spacing: 15) {
            Image("Showroom05").resizable().scaledToFill().frame(height: 235).clipped().clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            Text(L10n.t("НАША ИСТОРИЯ", "BIZNING TARIX", settings.language)).font(.system(size: 10.5, weight: .bold, design: .rounded)).tracking(1).foregroundStyle(.secondary)
            Text(L10n.t("Меняются автомобили. Принцип остаётся.", "Avtomobillar o‘zgaradi. Tamoyil qoladi.", settings.language)).asuSectionTitle(size: 29)
            Text(L10n.t("За четверть века автомобильный рынок менялся много раз: новые бренды, технологии, рынки поставки и способы покупки. Но доверие всегда строилось одинаково — на точности, ответственности и отношении к человеку.", "Chorak asr davomida avtomobil bozori ko‘p marta o‘zgardi: yangi brendlar, texnologiyalar, yetkazib berish bozorlari va xarid usullari. Ammo ishonch doim aniqlik, mas’uliyat va insonga munosabat orqali quriladi.", settings.language))
                .font(.system(size: 14.5)).foregroundStyle(.secondary).lineSpacing(4)
            Text(L10n.t("Сегодня этот опыт продолжает Auto Sale Umar. Мы соединяем живой шоурум, международный подбор и цифровой каталог в одну понятную систему, где клиент видит конкретный автомобиль и его реальный статус.", "Bugun bu tajribani Auto Sale Umar davom ettiradi. Biz jonli shourum, xalqaro tanlov va raqamli katalogni bitta tushunarli tizimga birlashtiramiz.", settings.language))
                .font(.system(size: 14.5)).foregroundStyle(.secondary).lineSpacing(4)
            Text(L10n.t("Для нас хорошая сделка — не момент передачи ключей. Это ощущение клиента, что его выбор был осознанным, спокойным и правильным.", "Biz uchun yaxshi bitim kalit topshirilgan paytda tugamaydi. Muhimi — mijoz o‘z tanlovini xotirjam va to‘g‘ri deb his qilishi.", settings.language))
                .font(.system(size: 14.5, weight: .semibold)).lineSpacing(4)
        }
    }

    private var principles: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.t("ТО, ЧТО НЕ МЕНЯЕТСЯ", "O‘ZGARMAYDIGAN NARSALAR", settings.language)).font(.system(size: 10.5, weight: .bold, design: .rounded)).tracking(1).foregroundStyle(.secondary)
            Text(L10n.t("Три принципа, на которых держится доверие.", "Ishonch tayanadigan uch tamoyil.", settings.language)).asuSectionTitle(size: 29)
            principle("01", "handshake.fill", L10n.t("Репутация важнее одной сделки", "Obro‘ bir savdodan muhimroq", settings.language), L10n.t("Мы думаем не о том, как продать сегодня, а о том, с каким впечатлением клиент вернётся завтра.", "Bugun sotishdan ko‘ra, mijoz ertaga qanday taassurot bilan qaytishini o‘ylaymiz.", settings.language))
            principle("02", "checkmark.shield.fill", L10n.t("Точность важнее обещаний", "Aniqlik va’dadan muhimroq", settings.language), L10n.t("Статус, характеристики и путь автомобиля должны быть понятны до принятия решения.", "Avtomobil statusi, xususiyatlari va yo‘li qarordan oldin tushunarli bo‘lishi kerak.", settings.language))
            principle("03", "point.3.connected.trianglepath.dotted", L10n.t("Сопровождение до результата", "Natijagacha kuzatuv", settings.language), L10n.t("От первого вопроса до автомобиля у клиента — один понятный путь и ответственное сопровождение.", "Birinchi savoldan avtomobil mijozga yetguncha — bitta tushunarli va mas’uliyatli yo‘l.", settings.language))
        }
    }

    private func principle(_ number: String, _ symbol: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ASUGlassCircleSurface(size: 54) { Image(systemName: symbol).font(.system(size: 19, weight: .semibold)) }
            VStack(alignment: .leading, spacing: 6) {
                Text(number).font(.system(size: 9.5, weight: .bold, design: .rounded)).foregroundStyle(ASUDesign.orange)
                Text(title).font(.system(size: 16.5, weight: .bold, design: .rounded))
                Text(text).font(.system(size: 13.5)).foregroundStyle(.secondary).lineSpacing(3)
            }
        }
        .padding(16).asuCard(radius: 24)
    }

    private var today: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.t("25 ЛЕТ → СЕГОДНЯ", "25 YIL → BUGUN", settings.language)).font(.system(size: 10.5, weight: .bold, design: .rounded)).tracking(1).foregroundStyle(.secondary)
            Text(L10n.t("Опыт прошлого. Сервис настоящего.", "O‘tmish tajribasi. Bugungi servis.", settings.language)).asuSectionTitle(size: 29)
            Text(L10n.t("Сегодня доверие поддерживается не только отношением, но и системой: каталогом реальных автомобилей, прозрачными статусами, международной поставкой и персональным контактом с командой Auto Sale Umar.", "Bugun ishonch munosabat bilan birga tizim orqali ham qo‘llab-quvvatlanadi: real avtomobillar katalogi, aniq statuslar, xalqaro yetkazib berish va Auto Sale Umar jamoasi bilan shaxsiy aloqa.", settings.language))
                .font(.system(size: 14.5)).foregroundStyle(.secondary).lineSpacing(4)
            HStack(spacing: 10) {
                stat(L10n.t("Опыт", "Tajriba", settings.language), L10n.t("25 лет", "25 yil", settings.language))
                stat(L10n.t("Подход", "Yondashuv", settings.language), L10n.t("Без давления", "Bosimsiz", settings.language))
                stat(L10n.t("Система", "Tizim", settings.language), L10n.t("Showroom + Digital", "Showroom + Digital", settings.language))
            }
        }
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.system(size: 10.5)).foregroundStyle(.secondary)
            Text(value).font(.system(size: 13.5, weight: .bold, design: .rounded)).lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .topLeading).padding(12).modifier(LocationGlassTile())
    }

    private var finalCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("AUTO SALE UMAR").font(.system(size: 10.5, weight: .bold, design: .rounded)).tracking(1).foregroundStyle(.secondary)
            Text(L10n.t("Доверие, которое продолжается.", "Davom etadigan ishonch.", settings.language)).font(.system(size: 27, weight: .bold, design: .rounded))
            Text(L10n.t("Выберите автомобиль онлайн или приезжайте в шоурум. Продолжим историю вашим следующим автомобилем.", "Avtomobilni onlayn tanlang yoki shourumga keling. Tarixni sizning keyingi avtomobilingiz bilan davom ettiramiz.", settings.language)).font(.system(size: 14.5)).foregroundStyle(.secondary).lineSpacing(3)
            Button(L10n.t("Смотреть автомобили", "Avtomobillarni ko‘rish", settings.language), action: openCatalog).buttonStyle(ASUPrimaryButtonStyle())
            Button(L10n.t("Забронировать визит", "Tashrifni bron qilish", settings.language)) { showBooking = true }.buttonStyle(ASUPrimaryButtonStyle(prominent: false))
        }
        .padding(20).asuCard(radius: 30)
    }
}

struct RamadanGiftView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.openURL) private var openURL
    @State private var gift: RamadanGift?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedMediaID: Int?
    @State private var now = Date()
    @State private var showBooking = false
    @State private var showRequest = false
    @State private var rulesRequest = 0

    private let api = ClientAPI()

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Group {
                    if isLoading { loadingState }
                    else if let gift { giftContent(gift) }
                    else { emptyState }
                }
                .padding(.horizontal, ASUDesign.pagePadding)
                .padding(.bottom, 34)
            }
            .onChange(of: rulesRequest) { _, _ in
                withAnimation(ASUDesign.softSpring) {
                    proxy.scrollTo("ramadan-rules", anchor: .top)
                }
            }
        }
        .background(ASUDesign.page)
        .navigationTitle("Ramadan Gift")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadGift() }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                now = Date()
            }
        }
        .sheet(isPresented: $showBooking) { NavigationStack { BookingView() } }
        .sheet(isPresented: $showRequest) { NavigationStack { RequestCarView() } }
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView().controlSize(.large)
            Text(L10n.t("Загружаем Ramadan Gift…", "Ramadan Gift yuklanmoqda…", settings.language)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 420)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ASUGlassCircleSurface(size: 86) { Image(systemName: "gift").font(.system(size: 30, weight: .medium)) }
            Text(L10n.t("Ramadan Gift временно недоступен", "Ramadan Gift vaqtincha mavjud emas", settings.language)).font(.system(size: 23, weight: .bold, design: .rounded)).multilineTextAlignment(.center)
            if let errorMessage { Text(errorMessage).font(.system(size: 13.5)).foregroundStyle(.secondary).multilineTextAlignment(.center) }
        }
        .frame(maxWidth: .infinity, minHeight: 420)
    }

    private func giftContent(_ gift: RamadanGift) -> some View {
        LazyVStack(spacing: 22) {
            giftHero(gift)
            countdownSection
            programStory(gift)
            rulesSection.id("ramadan-rules")
            if !gift.media.isEmpty { giftGallery(gift) }
        }
    }

    private func giftHero(_ gift: RamadanGift) -> some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                ASURemoteImage(url: activeGiftURL(gift), contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(height: 310)
                    .background(ASUDesign.gallery)
                LinearGradient(colors: [.clear, .black.opacity(0.78)], startPoint: .center, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.t("ПРЕМИАЛЬНАЯ ПРОГРАММА БЛАГОДАРНОСТИ", "PREMIUM MINNATDORCHILIK DASTURI", settings.language))
                        .font(.system(size: 9.5, weight: .bold, design: .rounded)).tracking(0.8).foregroundStyle(.white.opacity(0.65))
                    Text(gift.subtitle(settings.language)).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(.white)
                }.padding(18)
            }

            VStack(alignment: .leading, spacing: 13) {
                Text("AUTO SALE UMAR · RAMADAN GIFT").font(.system(size: 10, weight: .bold, design: .rounded)).tracking(1).foregroundStyle(.secondary)
                Text("Auto Sale Umar Ramadan Gift").asuSectionTitle(size: 31)
                Text(gift.shortPhrase(settings.language)).font(.system(size: 15, weight: .semibold)).foregroundStyle(.secondary).lineSpacing(3)
                Text(gift.description(settings.language)).font(.system(size: 14)).foregroundStyle(.secondary).lineSpacing(4)

                HStack(spacing: 10) {
                    giftMetric(L10n.t("Ориентир по стоимости", "Taxminiy qiymat", settings.language), money(gift.marketPrice, gift.currency))
                    giftMetric(L10n.t("Участие от", "Ishtirok", settings.language), money(gift.minPurchaseAmount, gift.currency))
                }

                Button(L10n.t("Условия программы", "Dastur shartlari", settings.language)) { rulesRequest += 1 }
                    .buttonStyle(ASUPrimaryButtonStyle())
                HStack(spacing: 10) {
                    Button(L10n.t("Визит", "Tashrif", settings.language)) { showBooking = true }.buttonStyle(ASUPrimaryButtonStyle(prominent: false))
                    Button(L10n.t("Заказать", "Buyurtma", settings.language)) { showRequest = true }.buttonStyle(ASUPrimaryButtonStyle(prominent: false))
                }
                if let instagram = gift.instagramUrl, let url = URL(string: instagram) {
                    Button { openURL(url) } label: { Label("Instagram", systemImage: "camera") }.buttonStyle(ASUPrimaryButtonStyle(prominent: false))
                }
            }
            .padding(18)
        }
        .asuCard(radius: 32)
    }

    private var countdownSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text(L10n.t("ДО СЛЕДУЮЩЕГО РАМАДАНА", "KEYINGI RAMAZONGACHA", settings.language)).font(.system(size: 10.5, weight: .bold, design: .rounded)).tracking(1).foregroundStyle(.secondary)
            Text(L10n.t("Живой обратный отсчёт", "Jonli ortga sanash", settings.language)).font(.system(size: 24, weight: .bold, design: .rounded))
            HStack(spacing: 8) {
                countdownMetric(countdown.days, L10n.t("дней", "kun", settings.language))
                countdownMetric(countdown.hours, L10n.t("часов", "soat", settings.language))
                countdownMetric(countdown.minutes, L10n.t("минут", "daqiqa", settings.language))
                countdownMetric(countdown.seconds, L10n.t("секунд", "soniya", settings.language))
            }
        }
        .padding(18).asuCard(radius: 28)
    }

    private func programStory(_ gift: RamadanGift) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.t("ПРОГРАММА БЛАГОДАРНОСТИ", "MINNATDORCHILIK DASTURI", settings.language)).font(.system(size: 10.5, weight: .bold, design: .rounded)).tracking(1).foregroundStyle(.secondary)
            Text(L10n.t("Главный подарок года.", "Yilning asosiy sovg‘asi.", settings.language)).asuSectionTitle(size: 28)
            Text(L10n.t("Ramadan Gift — это премиальная программа благодарности для клиентов Auto Sale Umar. Она создаёт эмоциональную кульминацию года: реальный автомобиль, выразительная подача и один клиент, который получает главный подарок программы в Рамадан.", "Ramadan Gift — Auto Sale Umar mijozlari uchun premium minnatdorchilik dasturi. U yilning hissiy kulminatsiyasini yaratadi: haqiqiy avtomobil va Ramazon oyida bosh sovg‘ani oladigan bitta mijoz.", settings.language))
                .font(.system(size: 14.5)).foregroundStyle(.secondary).lineSpacing(4)
        }
    }

    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.t("Как работает программа", "Dastur qanday ishlaydi", settings.language)).font(.system(size: 24, weight: .bold, design: .rounded))
            giftRule("01", L10n.t("Каждый клиент, который в течение года приобрёл автомобиль у Auto Sale Umar на сумму от 88 000 USD, автоматически становится участником программы.", "Bir yil davomida Auto Sale Umar’dan 88 000 USD dan boshlab avtomobil xarid qilgan har bir mijoz avtomatik ravishda dastur ishtirokchisiga aylanadi.", settings.language))
            giftRule("02", L10n.t("Во время Рамадана один из клиентов получает подарочный Mercedes-Benz E-Class как главный автомобиль программы благодарности.", "Ramazon davrida mijozlardan biri dastur bosh sovg‘asi bo‘lgan Mercedes-Benz E-Class egasiga aylanadi.", settings.language))
            giftRule("03", L10n.t("На странице показан конкретный подарочный автомобиль, его визуальный образ, ключевые параметры и ориентир по рыночной стоимости.", "Sahifada aynan sovg‘a avtomobil, uning vizual taqdimoti, asosiy parametrlar va bozor qiymatining yo‘nalishi ko‘rsatiladi.", settings.language))
        }
        .padding(18).asuCard(radius: 28)
    }

    private func giftGallery(_ gift: RamadanGift) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            Text(L10n.t("Галерея автомобиля", "Avtomobil galereyasi", settings.language)).font(.system(size: 24, weight: .bold, design: .rounded))
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(gift.media) { media in
                        Button { selectedMediaID = media.id } label: {
                            ASURemoteImage(url: URL(string: media.publicUrl), contentMode: .fit)
                                .frame(width: 260, height: 184)
                                .background(ASUDesign.gallery)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(selectedMediaID == media.id ? ASUDesign.orange : Color.clear, lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private func giftMetric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 10.5)).foregroundStyle(.secondary)
            Text(value).font(.system(size: 14, weight: .bold, design: .rounded)).lineLimit(2).minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading).padding(12).modifier(LocationGlassTile())
    }

    private func countdownMetric(_ value: Int, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(String(format: "%02d", value)).font(.system(size: 24, weight: .bold, design: .rounded))
            Text(label).font(.system(size: 9.5, design: .rounded)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).frame(height: 74).modifier(LocationGlassTile())
    }

    private func giftRule(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number).font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(ASUDesign.orange).frame(width: 28, height: 28).modifier(LocationGlassTile())
            Text(text).font(.system(size: 13.5)).foregroundStyle(.secondary).lineSpacing(3)
        }
    }

    private var countdown: (days: Int, hours: Int, minutes: Int, seconds: Int) {
        let target = nextRamadanStart(after: now)
        let interval = max(0, target.timeIntervalSince(now))
        let total = Int(interval)
        return (total / 86400, (total % 86400) / 3600, (total % 3600) / 60, total % 60)
    }

    private func nextRamadanStart(after date: Date) -> Date {
        let dates = ["2027-02-09T00:00:00+05:00", "2028-01-29T00:00:00+05:00", "2029-01-17T00:00:00+05:00", "2030-01-06T00:00:00+05:00"]
        let formatter = ISO8601DateFormatter()
        for raw in dates {
            if let candidate = formatter.date(from: raw), candidate > date { return candidate }
        }
        return formatter.date(from: dates.last!) ?? date
    }

    private func activeGiftURL(_ gift: RamadanGift) -> URL? {
        let media = selectedMediaID.flatMap { id in gift.media.first(where: { $0.id == id }) } ?? gift.coverMedia
        return media.flatMap { URL(string: $0.publicUrl) }
    }

    private func money(_ value: Double?, _ currency: ASUCurrency) -> String {
        guard let value else { return "—" }
        let formatter = NumberFormatter(); formatter.numberStyle = .decimal; formatter.maximumFractionDigits = 0; formatter.groupingSeparator = " "
        let number = formatter.string(from: NSNumber(value: value)) ?? String(Int(value))
        return "\(number) \(currency.rawValue)"
    }

    private func loadGift() async {
        isLoading = true
        defer { isLoading = false }
        do {
            gift = try await api.fetchRamadanGift()
            selectedMediaID = gift?.coverMedia?.id
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct LocationGlassTile: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) { content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous)) }
        else { content.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous)) }
    }
}
