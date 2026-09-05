import SwiftUI
import UIKit

struct RequestCarView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var brand = ""
    @State private var model = ""
    @State private var trim = ""
    @State private var desiredYear = ""
    @State private var exteriorColor = ""
    @State private var interiorColor = ""
    @State private var importantOptions = ""
    @State private var maxBudget = ""
    @State private var currency: ASUCurrency = .USD
    @State private var purchaseTiming: PurchaseTiming = .thirtyDays
    @State private var acceptInTransit = true
    @State private var sourceURL = ""
    @State private var note = ""
    @State private var name = Persistence.customerProfile().name
    @State private var phone = Persistence.customerProfile().phone
    @State private var contactChannel: ContactChannel = Persistence.customerProfile().preferredChannel
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var receipt: VehicleRequestReceipt?

    private let api = ClientAPI()
    private let brands = ["Toyota", "Genesis", "BMW", "Mercedes-Benz", "Range Rover", "Rolls-Royce", "Cadillac", "Porsche", "Lexus", "Lamborghini"]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                if let receipt {
                    successCard(receipt)
                } else {
                    intro
                    vehicleSection
                    budgetSection
                    referenceSection
                    contactSection
                    privacyAndSubmit
                }
            }
            .padding(.horizontal, ASUDesign.pagePadding)
            .padding(.bottom, 34)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(ASUDesign.page)
        .navigationTitle(L10n.t("Персональный подбор", "Shaxsiy tanlov", settings.language))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { dismiss() } label: { Image(systemName: "xmark") } } }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.t("AUTO SALE UMAR · ПЕРСОНАЛЬНЫЙ ПОДБОР", "AUTO SALE UMAR · SHAXSIY TANLOV", settings.language))
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                .tracking(1.15)
                .foregroundStyle(.secondary)
            Text(L10n.t("Найдём автомобиль\nпод ваш запрос.", "Siz izlayotgan\navtomobilni topamiz.", settings.language))
                .asuSectionTitle(size: 36)
            Text(L10n.t(
                "Если нужной машины сейчас нет в каталоге, отправьте точные параметры. Команда увидит запрос в Control System и начнёт подбор.",
                "Kerakli avtomobil hozir katalogda bo‘lmasa, aniq parametrlarni yuboring. Jamoa so‘rovni Control System’da ko‘radi va qidiruvni boshlaydi.",
                settings.language
            ))
            .font(.system(size: 15))
            .foregroundStyle(.secondary)
            .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var vehicleSection: some View {
        formSection(
            kicker: L10n.t("АВТОМОБИЛЬ", "AVTOMOBIL", settings.language),
            title: L10n.t("Какой автомобиль вы ищете?", "Qanday avtomobil izlayapsiz?", settings.language),
            caption: L10n.t("Марка и модель обязательны. Остальные параметры помогают подобрать автомобиль точнее.", "Marka va model majburiy. Qolgan parametrlar tanlovni aniqroq qiladi.", settings.language)
        ) {
            VStack(spacing: 12) {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(brands, id: \.self) { value in
                            ASUGlassPillButton(isSelected: brand == value) { brand = value } label: { Text(value) }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)

                ASUFormField(title: L10n.t("Марка", "Marka", settings.language), text: $brand, required: true)
                ASUFormField(title: L10n.t("Модель", "Model", settings.language), text: $model, required: true)
                ASUFormField(title: L10n.t("Комплектация", "Komplektatsiya", settings.language), text: $trim)
                HStack(spacing: 10) {
                    ASUFormField(title: L10n.t("Желаемый год", "Istalgan yil", settings.language), text: $desiredYear, keyboard: .numberPad)
                    ASUFormField(title: L10n.t("Цвет кузова", "Kuzov rangi", settings.language), text: $exteriorColor)
                }
                ASUFormField(title: L10n.t("Цвет салона", "Salon rangi", settings.language), text: $interiorColor)
                ASUTextArea(title: L10n.t("Важные опции", "Muhim opsiyalar", settings.language), text: $importantOptions, placeholder: L10n.t("Например: пневмоподвеска, 7 мест, массаж, Burmester…", "Masalan: pnevmo, 7 o‘rin, massaj, Burmester…", settings.language))
            }
        }
    }

    private var budgetSection: some View {
        formSection(
            kicker: L10n.t("БЮДЖЕТ И СРОК", "BUDJET VA MUDDAT", settings.language),
            title: L10n.t("Когда автомобиль должен быть у вас?", "Avtomobil qachon sizda bo‘lishi kerak?", settings.language),
            caption: nil
        ) {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    ASUFormField(title: L10n.t("Максимальный бюджет", "Maksimal budjet", settings.language), text: $maxBudget, keyboard: .numberPad)
                    Menu {
                        ForEach(ASUCurrency.allCases) { value in Button(value.rawValue) { currency = value } }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L10n.t("Валюта", "Valyuta", settings.language)).font(.system(size: 10.5)).foregroundStyle(.secondary)
                                Text(currency.rawValue).font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundStyle(.primary)
                            }
                            Spacer()
                            Image(systemName: "chevron.down").font(.system(size: 12, weight: .bold)).foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 58)
                        .modifier(ClientGlassField())
                    }
                    .frame(width: 112)
                }

                Picker("", selection: $purchaseTiming) {
                    ForEach(PurchaseTiming.allCases) { value in Text(timingLabel(value)).tag(value) }
                }
                .pickerStyle(.menu)
                .tint(.primary)
                .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                .padding(.horizontal, 14)
                .modifier(ClientGlassField())

                Toggle(isOn: $acceptInTransit) {
                    Text(L10n.t("Готов рассмотреть автомобиль в пути", "Yo‘ldagi avtomobilni ham ko‘rib chiqaman", settings.language))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .tint(ASUDesign.orange)
                .padding(14)
                .modifier(ClientGlassField())
            }
        }
    }

    private var referenceSection: some View {
        formSection(
            kicker: L10n.t("РЕФЕРЕНС", "NAMUNA", settings.language),
            title: L10n.t("Есть пример автомобиля?", "Avtomobil namunasi bormi?", settings.language),
            caption: L10n.t("Вставьте ссылку на Instagram, Telegram, YouTube, объявление или страницу автомобиля. Менеджер откроет её одним нажатием.", "Instagram, Telegram, YouTube, e’lon yoki avtomobil sahifasiga havolani kiriting. Menejer uni bir bosishda ochadi.", settings.language)
        ) {
            VStack(spacing: 12) {
                ASUFormField(title: L10n.t("Ссылка на пример", "Namuna havolasi", settings.language), text: $sourceURL, keyboard: .URL)
                ASUTextArea(title: L10n.t("Комментарий", "Izoh", settings.language), text: $note, placeholder: L10n.t("Например: только светлый салон, нужен 7-местный автомобиль, важна пневмоподвеска.", "Masalan: faqat och salon, 7 o‘rinli, pnevmatik osma muhim.", settings.language))
            }
        }
    }

    private var contactSection: some View {
        formSection(
            kicker: L10n.t("КОНТАКТ", "ALOQA", settings.language),
            title: L10n.t("Как с вами связаться?", "Siz bilan qanday bog‘lanamiz?", settings.language),
            caption: nil
        ) {
            VStack(spacing: 12) {
                ASUFormField(title: L10n.t("Ваше имя", "Ismingiz", settings.language), text: $name, required: true)
                ASUFormField(title: L10n.t("Телефон", "Telefon", settings.language), text: $phone, required: true, keyboard: .phonePad)
                HStack(spacing: 8) {
                    channelButton(.whatsapp, title: "WhatsApp", symbol: "message.fill")
                    channelButton(.telegram, title: "Telegram", symbol: "paperplane.fill")
                    channelButton(.phone, title: L10n.t("Звонок", "Qo‘ng‘iroq", settings.language), symbol: "phone.fill")
                }
            }
        }
    }

    private var privacyAndSubmit: some View {
        VStack(spacing: 12) {
            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Label(L10n.t("Запрос увидят только сотрудники Auto Sale Umar в Control System.", "So‘rovni faqat Auto Sale Umar xodimlari Control System’da ko‘radi.", settings.language), systemImage: "lock.shield")
                .font(.system(size: 12.5, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                Task { await submit() }
            } label: {
                HStack(spacing: 9) {
                    if isSubmitting { ProgressView().tint(Color(uiColor: .systemBackground)) }
                    else { Image(systemName: "magnifyingglass") }
                    Text(isSubmitting ? L10n.t("Отправляем запрос…", "So‘rov yuborilmoqda…", settings.language) : L10n.t("Отправить запрос", "So‘rov yuborish", settings.language))
                }
            }
            .buttonStyle(ASUPrimaryButtonStyle())
            .disabled(isSubmitting)
        }
    }

    private func successCard(_ receipt: VehicleRequestReceipt) -> some View {
        VStack(spacing: 18) {
            ASUGlassCircleSurface(size: 88) {
                Image(systemName: "checkmark")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(ASUDesign.success)
            }
            Text(L10n.t("Запрос принят.", "So‘rov qabul qilindi.", settings.language))
                .asuSectionTitle(size: 30)
                .multilineTextAlignment(.center)
            Text(L10n.t("Он уже появился в Control System. Менеджер увидит параметры автомобиля и сможет открыть вашу ссылку-пример напрямую.", "U Control System’da paydo bo‘ldi. Menejer avtomobil parametrlarini ko‘radi va namuna havolasini to‘g‘ridan-to‘g‘ri ochadi.", settings.language))
                .font(.system(size: 14.5))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            HStack(spacing: 10) {
                metric(L10n.t("Код запроса", "So‘rov kodi", settings.language), receipt.code)
                metric(L10n.t("Автомобиль", "Avtomobil", settings.language), "\(receipt.brand) \(receipt.model)")
            }

            Button(L10n.t("Отправить ещё один запрос", "Yana so‘rov yuborish", settings.language)) {
                self.receipt = nil
                errorMessage = nil
            }
            .buttonStyle(ASUPrimaryButtonStyle(prominent: false))
        }
        .padding(22)
        .asuCard()
        .padding(.top, 26)
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 10.5, weight: .medium)).foregroundStyle(.secondary)
            Text(value).font(.system(size: 14, weight: .bold, design: .rounded)).lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 78, alignment: .leading)
        .padding(14)
        .modifier(ClientGlassField())
    }

    private func channelButton(_ value: ContactChannel, title: String, symbol: String) -> some View {
        Button { contactChannel = value } label: {
            VStack(spacing: 7) {
                Image(systemName: symbol).font(.system(size: 17, weight: .semibold))
                Text(title).font(.system(size: 10.5, weight: .semibold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.7)
            }
            .foregroundStyle(contactChannel == value ? Color(uiColor: .systemBackground) : .primary)
            .frame(maxWidth: .infinity)
            .frame(height: 66)
            .background(contactChannel == value ? Color.primary : .clear, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .modifier(ClientGlassFieldFallbackOnly(active: contactChannel != value))
        }
        .buttonStyle(.plain)
    }

    private func formSection<Content: View>(kicker: String, title: String, caption: String?, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(kicker).font(.system(size: 10.5, weight: .bold, design: .rounded)).tracking(1).foregroundStyle(.secondary)
            Text(title).font(.system(size: 22, weight: .bold, design: .rounded)).tracking(-0.4)
            if let caption { Text(caption).font(.system(size: 13.5)).foregroundStyle(.secondary).lineSpacing(3) }
            content()
        }
        .padding(18)
        .asuCard(radius: 28)
    }

    private func timingLabel(_ value: PurchaseTiming) -> String {
        switch value {
        case .sevenDays: return L10n.t("В ближайшие 7 дней", "Keyingi 7 kun ichida", settings.language)
        case .thirtyDays: return L10n.t("В ближайшие 30 дней", "Keyingi 30 kun ichida", settings.language)
        case .ninetyDays: return L10n.t("В ближайшие 3 месяца", "Keyingi 3 oy ichida", settings.language)
        case .flexible: return L10n.t("Срок не критичен", "Muddat muhim emas", settings.language)
        }
    }

    private func submit() async {
        errorMessage = nil
        guard name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else { errorMessage = L10n.t("Укажите ваше имя.", "Ismingizni kiriting.", settings.language); ASUHaptics.error(); return }
        guard phone.filter(\.isNumber).count >= 7 else { errorMessage = L10n.t("Укажите корректный номер телефона.", "Telefon raqamini tekshiring.", settings.language); ASUHaptics.error(); return }
        guard brand.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else { errorMessage = L10n.t("Укажите марку автомобиля.", "Avtomobil markasini kiriting.", settings.language); ASUHaptics.error(); return }
        guard !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { errorMessage = L10n.t("Укажите модель автомобиля.", "Avtomobil modelini kiriting.", settings.language); ASUHaptics.error(); return }

        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let response = try await api.submitVehicleRequest(VehicleRequestDraft(
                customerName: name.trimmed,
                phone: phone.trimmed,
                contactChannel: contactChannel,
                brand: brand.trimmed,
                model: model.trimmed,
                trim: trim.nilIfEmpty,
                desiredYear: Int(desiredYear.trimmed),
                exteriorColor: exteriorColor.nilIfEmpty,
                interiorColor: interiorColor.nilIfEmpty,
                importantOptions: importantOptions.nilIfEmpty,
                maxBudget: Double(maxBudget.replacingOccurrences(of: " ", with: "")),
                currency: currency,
                purchaseTiming: purchaseTiming,
                acceptInTransit: acceptInTransit,
                sourceUrl: sourceURL.nilIfEmpty,
                note: note.nilIfEmpty
            ))
            receipt = response
            Persistence.recordVehicleRequest(response)
            Persistence.saveCustomerProfile(ASUCustomerProfile(name: name.trimmed, phone: phone.trimmed, preferredChannel: contactChannel))
            ASUHaptics.success()
        } catch {
            errorMessage = settings.language == .ru ? error.localizedDescription : "Xizmat vaqtincha mavjud emas. Qayta urinib ko‘ring."
            ASUHaptics.error()
        }
    }
}

struct BookingView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var selectedDate = BookingView.defaultVisitDate
    @State private var timeSlot = "09:00–11:00"
    @State private var brand = ""
    @State private var carID: Int?
    @State private var name = Persistence.customerProfile().name
    @State private var phone = Persistence.customerProfile().phone
    @State private var note = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var receipt: VisitReceipt?

    private let api = ClientAPI()
    private let timeSlots = ["09:00–11:00", "11:00–13:00", "14:00–16:00", "16:00–18:00", "18:00–20:00"]

    init(initialCar: Car? = nil) {
        _brand = State(initialValue: initialCar?.brand ?? "")
        _carID = State(initialValue: initialCar?.id)
    }

    private var selectedCar: Car? { carID.flatMap { id in store.cars.first(where: { $0.id == id }) } }
    private var availableCars: [Car] { brand.isEmpty ? store.cars : store.cars.filter { $0.brand == brand } }
    private var brands: [String] { Array(Set(store.cars.map(\.brand))).sorted() }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                if let receipt { successCard(receipt) }
                else {
                    bookingIntro
                    showroomStage
                    dateSection
                    carSection
                    contactSection
                    submitSection
                }
            }
            .padding(.horizontal, ASUDesign.pagePadding)
            .padding(.bottom, 34)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(ASUDesign.page)
        .navigationTitle(L10n.t("Визит", "Tashrif", settings.language))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { dismiss() } label: { Image(systemName: "xmark") } } }
        .task { await store.loadIfNeeded() }
    }

    private var bookingIntro: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.t("AUTO SALE UMAR · ШОУРУМ", "AUTO SALE UMAR · SHOURUM", settings.language))
                .font(.system(size: 10.5, weight: .bold, design: .rounded)).tracking(1.15).foregroundStyle(.secondary)
            Text(L10n.t("Забронируйте время\nдля спокойного выбора.", "Xotirjam tanlov uchun\nvaqtni band qiling.", settings.language))
                .asuSectionTitle(size: 36)
            Text(L10n.t("Выберите удобную дату, временной промежуток и автомобиль, который хотите посмотреть. Мы подготовим визит заранее.", "Qulay sana, vaqt oralig‘i va ko‘rmoqchi bo‘lgan avtomobilingizni tanlang. Tashrifni oldindan tayyorlaymiz.", settings.language))
                .font(.system(size: 15)).foregroundStyle(.secondary).lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var showroomStage: some View {
        ZStack(alignment: .bottomLeading) {
            Image("Showroom01").resizable().scaledToFill().frame(height: 220).clipped()
            LinearGradient(colors: [.clear, .black.opacity(0.72)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.t("ЛОКАЦИЯ", "LOKATSIYA", settings.language)).font(.system(size: 10, weight: .bold, design: .rounded)).tracking(1).foregroundStyle(.white.opacity(0.7))
                Text(L10n.t("Ташкент · Auto Sale Umar", "Toshkent · Auto Sale Umar", settings.language)).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(.white)
            }.padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.t("ДАТА И ВРЕМЯ", "SANA VA VAQT", settings.language)).font(.system(size: 10.5, weight: .bold, design: .rounded)).tracking(1).foregroundStyle(.secondary)
            Text(L10n.t("Выберите удобное окно", "Qulay vaqtni tanlang", settings.language)).font(.system(size: 22, weight: .bold, design: .rounded))
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(nextDates, id: \.self) { date in
                        dateButton(date)
                    }
                }.padding(.vertical, 2)
            }.scrollIndicators(.hidden)
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(timeSlots, id: \.self) { slot in
                        ASUGlassPillButton(isSelected: timeSlot == slot) { timeSlot = slot } label: { Text(slot) }
                    }
                }.padding(.vertical, 2)
            }.scrollIndicators(.hidden)
        }
        .padding(18).asuCard(radius: 28)
    }

    private var carSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.t("АВТОМОБИЛЬ", "AVTOMOBIL", settings.language)).font(.system(size: 10.5, weight: .bold, design: .rounded)).tracking(1).foregroundStyle(.secondary)
            Text(L10n.t("Что подготовить к вашему визиту?", "Tashrifingizga nimani tayyorlaymiz?", settings.language)).font(.system(size: 22, weight: .bold, design: .rounded))

            Menu {
                Button(L10n.t("Любая марка", "Istalgan marka", settings.language)) { brand = ""; carID = nil }
                ForEach(brands, id: \.self) { value in Button(value) { brand = value; carID = nil } }
            } label: {
                fieldMenuLabel(title: L10n.t("Интересующая марка", "Qiziqtirgan marka", settings.language), value: brand.isEmpty ? L10n.t("Любая марка", "Istalgan marka", settings.language) : brand)
            }

            Menu {
                Button(L10n.t("Без привязки к автомобилю", "Aniq avtomobilsiz", settings.language)) { carID = nil }
                ForEach(availableCars) { car in Button(car.displayName) { carID = car.id; brand = car.brand } }
            } label: {
                fieldMenuLabel(title: L10n.t("Конкретный автомобиль", "Aniq avtomobil", settings.language), value: selectedCar?.displayName ?? L10n.t("Без привязки к автомобилю", "Aniq avtomobilsiz", settings.language))
            }

            if let selectedCar {
                HStack(spacing: 12) {
                    ASURemoteImage(url: selectedCar.primaryImageURL, contentMode: .fit)
                        .frame(width: 112, height: 76)
                        .background(ASUDesign.gallery)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    VStack(alignment: .leading, spacing: 5) {
                        Text(selectedCar.displayName).font(.system(size: 15, weight: .bold, design: .rounded))
                        Text(Format.price(selectedCar, language: settings.language)).font(.system(size: 12.5, weight: .semibold, design: .rounded)).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(10).modifier(ClientGlassField())
            }
        }
        .padding(18).asuCard(radius: 28)
    }

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.t("КОНТАКТНЫЕ ДАННЫЕ", "ALOQA MA’LUMOTLARI", settings.language)).font(.system(size: 10.5, weight: .bold, design: .rounded)).tracking(1).foregroundStyle(.secondary)
            ASUFormField(title: L10n.t("Ваше имя", "Ismingiz", settings.language), text: $name, required: true)
            ASUFormField(title: L10n.t("Телефон", "Telefon", settings.language), text: $phone, required: true, keyboard: .phonePad)
            ASUTextArea(title: L10n.t("Комментарий", "Izoh", settings.language), text: $note, placeholder: L10n.t("Например: хочу сравнить два цвета или посмотреть автомобиль вместе с семьёй.", "Masalan: ikki rangni solishtirmoqchiman yoki oilam bilan kelaman.", settings.language))
        }
        .padding(18).asuCard(radius: 28)
    }

    private var submitSection: some View {
        VStack(spacing: 12) {
            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.circle.fill").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(.red).frame(maxWidth: .infinity, alignment: .leading)
            }
            Button { Task { await submit() } } label: {
                HStack(spacing: 9) {
                    if isSubmitting { ProgressView().tint(Color(uiColor: .systemBackground)) }
                    else { Image(systemName: "calendar.badge.checkmark") }
                    Text(isSubmitting ? L10n.t("Сохраняем бронирование…", "Band qilinmoqda…", settings.language) : L10n.t("Забронировать визит", "Tashrifni band qilish", settings.language))
                }
            }
            .buttonStyle(ASUPrimaryButtonStyle())
            .disabled(isSubmitting)
            Button { openURL(AppConfig.yandexMaps) } label: { Label(L10n.t("Построить маршрут", "Yo‘nalishni ochish", settings.language), systemImage: "map") }
                .buttonStyle(ASUPrimaryButtonStyle(prominent: false))
        }
    }

    private func successCard(_ receipt: VisitReceipt) -> some View {
        VStack(spacing: 18) {
            ASUGlassCircleSurface(size: 88) { Image(systemName: "calendar.badge.checkmark").font(.system(size: 31, weight: .bold)).foregroundStyle(ASUDesign.success) }
            Text(L10n.t("Визит забронирован", "Tashrif band qilindi", settings.language)).asuSectionTitle(size: 30).multilineTextAlignment(.center)
            Text(L10n.t("Бронирование уже появилось в Control System. Сотрудник шоурума увидит его и сможет подтвердить визит.", "Band qilish Control System’da paydo bo‘ldi. Shourum xodimi uni ko‘radi va tashrifni tasdiqlashi mumkin.", settings.language))
                .font(.system(size: 14.5)).foregroundStyle(.secondary).multilineTextAlignment(.center).lineSpacing(3)
            HStack(spacing: 10) {
                visitMetric(L10n.t("Код визита", "Tashrif kodi", settings.language), receipt.code)
                visitMetric(L10n.t("Время", "Vaqt", settings.language), "\(receipt.visitDate)\n\(receipt.timeSlot)")
            }
            Button(L10n.t("Построить маршрут", "Yo‘nalishni ochish", settings.language)) { openURL(AppConfig.yandexMaps) }
                .buttonStyle(ASUPrimaryButtonStyle())
        }
        .padding(22).asuCard().padding(.top, 26)
    }

    private func visitMetric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 10.5)).foregroundStyle(.secondary)
            Text(value).font(.system(size: 13.5, weight: .bold, design: .rounded)).lineLimit(3)
        }
        .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading).padding(14).modifier(ClientGlassField())
    }

    private func fieldMenuLabel(title: String, value: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 10.5)).foregroundStyle(.secondary)
                Text(value).font(.system(size: 14.5, weight: .semibold, design: .rounded)).foregroundStyle(.primary).lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.down").font(.system(size: 12, weight: .bold)).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14).frame(height: 60).modifier(ClientGlassField())
    }

    private static var showroomCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tashkent") ?? .current
        return calendar
    }

    private static var defaultVisitDate: Date {
        let calendar = showroomCalendar
        return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) ?? Date()
    }

    private var nextDates: [Date] {
        let calendar = Self.showroomCalendar
        let today = calendar.startOfDay(for: Date())
        return (1...21).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }

    private func showroomDatePart(_ date: Date, template: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: settings.language == .ru ? "ru_RU" : "uz_UZ")
        formatter.calendar = Self.showroomCalendar
        formatter.timeZone = Self.showroomCalendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter.string(from: date)
    }

    private func dateButton(_ date: Date) -> some View {
        let selected = Self.showroomCalendar.isDate(selectedDate, inSameDayAs: date)
        return Button { selectedDate = date } label: {
            VStack(spacing: 4) {
                Text(showroomDatePart(date, template: "EEE")).font(.system(size: 10.5, weight: .semibold, design: .rounded))
                Text(showroomDatePart(date, template: "d")).font(.system(size: 18, weight: .bold, design: .rounded))
                Text(showroomDatePart(date, template: "MMM")).font(.system(size: 10.5, design: .rounded))
            }
            .foregroundStyle(selected ? Color(uiColor: .systemBackground) : .primary)
            .frame(width: 68, height: 76)
            .modifier(ClientGlassSelectable(selected: selected))
        }
        .buttonStyle(.plain)
    }

    private func submit() async {
        errorMessage = nil
        guard name.trimmed.count >= 2 else { errorMessage = L10n.t("Укажите ваше имя.", "Ismingizni kiriting.", settings.language); ASUHaptics.error(); return }
        guard phone.filter(\.isNumber).count >= 7 else { errorMessage = L10n.t("Укажите корректный номер телефона.", "Telefon raqamini tekshiring.", settings.language); ASUHaptics.error(); return }

        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.calendar = Self.showroomCalendar
            formatter.timeZone = Self.showroomCalendar.timeZone
            formatter.dateFormat = "yyyy-MM-dd"
            let response = try await api.submitVisit(VisitDraft(
                customerName: name.trimmed,
                phone: phone.trimmed,
                visitDate: formatter.string(from: selectedDate),
                timeSlot: timeSlot,
                brand: brand.nilIfEmpty,
                carId: selectedCar?.id,
                carLabel: selectedCar.map { car in "\(car.displayName)\(car.trim.map { " · \($0)" } ?? "")" },
                note: note.nilIfEmpty
            ))
            receipt = response
            Persistence.recordVisit(response)
            let existing = Persistence.customerProfile()
            Persistence.saveCustomerProfile(ASUCustomerProfile(name: name.trimmed, phone: phone.trimmed, preferredChannel: existing.preferredChannel))
            if settings.visitRemindersEnabled {
                await ASUVisitReminder.schedule(for: response, language: settings.language)
            }
            ASUHaptics.success()
        } catch {
            errorMessage = settings.language == .ru ? error.localizedDescription : "Xizmat vaqtincha mavjud emas. Qayta urinib ko‘ring."
            ASUHaptics.error()
        }
    }
}

struct ASUFormField: View {
    let title: String
    @Binding var text: String
    var required = false
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(title).font(.system(size: 10.5)).foregroundStyle(.secondary)
                if required { Text("•").foregroundStyle(ASUDesign.orange) }
            }
            TextField("", text: $text)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .URL ? .never : .sentences)
                .autocorrectionDisabled(keyboard == .URL)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .frame(height: 58)
        .modifier(ClientGlassField())
    }
}

struct ASUTextArea: View {
    let title: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 10.5)).foregroundStyle(.secondary)
            TextField(placeholder, text: $text, axis: .vertical)
                .lineLimit(3...6)
                .font(.system(size: 14, weight: .medium, design: .rounded))
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
        .modifier(ClientGlassField())
    }
}

struct ClientGlassField: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        } else {
            content.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.18), lineWidth: 0.7))
        }
    }
}


struct ClientGlassSelectable: ViewModifier {
    let selected: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        if #available(iOS 26.0, *) {
            if selected { content.glassEffect(.regular.tint(Color.primary).interactive(), in: shape) }
            else { content.glassEffect(.regular.interactive(), in: shape) }
        } else {
            if selected { content.background(Color.primary, in: shape) }
            else { content.background(.ultraThinMaterial, in: shape) }
        }
    }
}

struct ClientGlassFieldFallbackOnly: ViewModifier {
    let active: Bool
    @ViewBuilder
    func body(content: Content) -> some View {
        if active {
            if #available(iOS 26.0, *) { content.glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 20, style: .continuous)) }
            else { content.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous)) }
        } else { content }
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var nilIfEmpty: String? { trimmed.isEmpty ? nil : trimmed }
}
