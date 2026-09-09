import SwiftUI
import UIKit

private enum ASUAdminCarEditorMode: Hashable {
    case create
    case edit(Int)

    var carID: Int? {
        if case .edit(let id) = self { return id }
        return nil
    }

    var isCreate: Bool { carID == nil }
}

struct ASUAdminCarEditorView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ObservedObject var session: ASUAdminSessionStore
    private let mode: ASUAdminCarEditorMode
    private let onSaved: (Int) -> Void
    private let api = ASUAdminAPI()

    @State private var draft = ASUAdminCarFormDraft.newCar()
    @State private var persistedCarID: Int?
    @State private var isLoadingDetail = false
    @State private var isSaving = false
    @State private var savingText: String?
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var deletingPhotoID: Int?
    @State private var pendingVariantRemoval: UUID?

    @State private var aiOpen = false
    @State private var aiText = ""
    @State private var aiLoading = false
    @State private var aiWarnings: [String] = []
    @State private var aiApplied = false

    init(session: ASUAdminSessionStore, carID: Int? = nil, onSaved: @escaping (Int) -> Void) {
        self.session = session
        self.mode = carID.map(ASUAdminCarEditorMode.edit) ?? .create
        self.onSaved = onSaved
        _persistedCarID = State(initialValue: carID)
    }

    private var columns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    }

    private var editorTitle: String {
        mode.isCreate
            ? L10n.t("Новый автомобиль", "Yangi avtomobil", settings.language)
            : L10n.t("Редактирование", "Tahrirlash", settings.language)
    }

    private var allowedStatuses: [CarStatus] {
        if mode.isCreate {
            return [.inStock, .inShowroom, .inTransit, .reserved, .madeToOrder]
        }
        return [.inStock, .inShowroom, .inTransit, .reserved, .madeToOrder, .sold, .hidden]
    }

    var body: some View {
        Group {
            if isLoadingDetail {
                loadingView
            } else {
                editorContent
            }
        }
        .background(ASUDesign.page)
        .navigationTitle(editorTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(L10n.t("Закрыть", "Yopish", settings.language)) { dismiss() }
                    .disabled(isSaving)
            }
            ToolbarItem(placement: .topBarTrailing) {
                if let persistedCarID {
                    Text("ID \(persistedCarID)")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .interactiveDismissDisabled(isSaving)
        .task { await loadDetailIfNeeded() }
        .confirmationDialog(
            L10n.t("Удалить цветовой вариант?", "Rang varianti o‘chirilsinmi?", settings.language),
            isPresented: Binding(
                get: { pendingVariantRemoval != nil },
                set: { if !$0 { pendingVariantRemoval = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(L10n.t("Удалить вариант", "Variantni o‘chirish", settings.language), role: .destructive) {
                if let id = pendingVariantRemoval { removeVariant(id) }
                pendingVariantRemoval = nil
            }
            Button(L10n.t("Отмена", "Bekor qilish", settings.language), role: .cancel) {
                pendingVariantRemoval = nil
            }
        } message: {
            Text(L10n.t(
                "После сохранения вариант и его фотографии будут удалены из системы.",
                "Saqlangandan keyin variant va uning suratlari tizimdan o‘chiriladi.",
                settings.language
            ))
        }
        .sensoryFeedback(.success, trigger: aiApplied)
    }

    private var editorContent: some View {
        ScrollView {
            LazyVStack(spacing: 18) {
                editorHero
                aiCard
                vehicleSection
                deliverySection
                specificationSection
                variantsSection
                commerceSection
                descriptionsSection

                if let errorMessage {
                    errorCard(errorMessage)
                }
                if let successMessage {
                    successCard(successMessage)
                }

                Color.clear.frame(height: 88)
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            saveDock
        }
    }

    private var loadingView: some View {
        VStack(spacing: 17) {
            ASUGlassCircleSurface(size: 82) {
                Image(systemName: "car.2")
                    .font(.system(size: 29, weight: .light))
            }
            ProgressView().controlSize(.large)
            Text(L10n.t("Загружаем полную карточку автомобиля…", "Avtomobilning to‘liq kartasi yuklanmoqda…", settings.language))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(28)
    }

    private var editorHero: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.black, Color(red: 0.055, green: 0.055, blue: 0.064)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(ASUDesign.success.opacity(0.20))
                .frame(width: 210, height: 210)
                .blur(radius: 46)
                .offset(x: 170, y: -105)

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("CONTROL SYSTEM · 04/07")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .tracking(1.2)
                    Spacer()
                    HStack(spacing: 6) {
                        Circle().fill(ASUDesign.success).frame(width: 7, height: 7)
                        Text("D1 + R2")
                    }
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white.opacity(0.58))

                Text(editorTitle)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .tracking(-1.25)
                    .foregroundStyle(.white)

                Text(L10n.t(
                    "Основные данные, поставка, характеристики, варианты, фотографии, цена и описания — одна нативная форма.",
                    "Asosiy ma’lumotlar, yetkazib berish, xususiyatlar, variantlar, suratlar, narx va tavsiflar — bitta native forma.",
                    settings.language
                ))
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.62))
                .lineSpacing(4)

                HStack(spacing: 8) {
                    heroBadge("01–03", L10n.t("данные", "ma’lumot", settings.language))
                    heroBadge("04", L10n.t("медиа", "media", settings.language))
                    heroBadge("05–06", L10n.t("публикация", "e’lon", settings.language))
                }
            }
            .padding(21)
        }
        .frame(minHeight: 285)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 0.7))
    }

    private func heroBadge(_ number: String, _ title: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(number)
                .font(.system(size: 14, weight: .bold, design: .rounded))
            Text(title)
                .font(.system(size: 9.5, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.50))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: 55, alignment: .leading)
        .padding(.horizontal, 11)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
    }

    // MARK: AI

    private var aiCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Button {
                withAnimation(reduceMotion ? nil : ASUDesign.spring) { aiOpen.toggle() }
            } label: {
                HStack(spacing: 13) {
                    ASUGlassCircleSurface(size: 48) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AUTO SALE UMAR AI")
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                            .tracking(1.1)
                            .foregroundStyle(.secondary)
                        Text(L10n.t("Умное автозаполнение", "Aqlli avtomatik to‘ldirish", settings.language))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .rotationEffect(.degrees(aiOpen ? 180 : 0))
                }
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)

            if aiOpen {
                Text(L10n.t(
                    "Вставьте спецификацию, дилерский лист, invoice или большой текст. AI заполнит только найденные данные — сохранение остаётся под вашим контролем.",
                    "Spetsifikatsiya, diler varaqasi, invoice yoki katta matnni kiriting. AI faqat topilgan ma’lumotlarni to‘ldiradi — saqlash sizning nazoratingizda qoladi.",
                    settings.language
                ))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .lineSpacing(4)

                TextEditor(text: $aiText)
                    .font(.system(size: 13.5, design: .rounded))
                    .frame(minHeight: 185)
                    .padding(10)
                    .scrollContentBackground(.hidden)
                    .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))
                    .onChange(of: aiText) { _, value in
                        if value.count > 180_000 { aiText = String(value.prefix(180_000)) }
                    }

                HStack(spacing: 10) {
                    Button {
                        Task { await runAI() }
                    } label: {
                        HStack(spacing: 8) {
                            if aiLoading { ProgressView().controlSize(.small).tint(Color(uiColor: .systemBackground)) }
                            else { Image(systemName: "sparkles") }
                            Text(aiLoading
                                 ? L10n.t("Анализируем…", "Tahlil qilinmoqda…", settings.language)
                                 : L10n.t("Проанализировать", "Tahlil qilish", settings.language))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ASUPrimaryButtonStyle())
                    .disabled(aiLoading)

                    ASUGlassIconButton(
                        symbol: "trash",
                        size: 56,
                        accessibilityLabel: L10n.t("Очистить", "Tozalash", settings.language)
                    ) {
                        aiText = ""
                        aiWarnings = []
                        aiApplied = false
                    }
                    .disabled(aiLoading)
                }

                if aiApplied {
                    Label(
                        L10n.t("Автозаполнение завершено. Проверьте значения перед сохранением.", "Avtomatik to‘ldirish yakunlandi. Saqlashdan oldin qiymatlarni tekshiring.", settings.language),
                        systemImage: "checkmark.circle.fill"
                    )
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(ASUDesign.success)
                }

                if !aiWarnings.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.t("ПРЕДУПРЕЖДЕНИЯ AI", "AI OGOHLANTIRISHLARI", settings.language))
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(.secondary)
                        ForEach(Array(aiWarnings.enumerated()), id: \.offset) { _, warning in
                            HStack(alignment: .top, spacing: 9) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(ASUDesign.orange)
                                    .padding(.top, 2)
                                Text(warning)
                                    .font(.system(size: 12.5))
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(14)
                    .background(ASUDesign.orange.opacity(0.065), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
        .padding(17)
        .asuCard(radius: 28)
    }

    // MARK: 01 Automobile

    private var vehicleSection: some View {
        editorSection(number: "01", title: L10n.t("Автомобиль", "Avtomobil", settings.language), detail: L10n.t("Сначала марка, затем точная модель и комплектация.", "Avval marka, keyin aniq model va komplektatsiya.", settings.language)) {
            ScrollView(.horizontal) {
                HStack(spacing: 9) {
                    ForEach(ASUHomeContent.brands) { item in
                        Button {
                            withAnimation(reduceMotion ? nil : ASUDesign.spring) { draft.brand = item.name }
                        } label: {
                            VStack(spacing: 8) {
                                Image(item.assetName)
                                    .resizable()
                                    .scaledToFit()
                                    .grayscale(1)
                                    .frame(width: 58, height: 36)
                                Text(item.name)
                                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.68)
                            }
                            .foregroundStyle(draft.brand == item.name ? Color(uiColor: .systemBackground) : Color.primary)
                            .frame(width: 112, height: 82)
                            .modifier(ASUAdminEditorRounded(selected: draft.brand == item.name, radius: 20))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)

            LazyVGrid(columns: columns, spacing: 10) {
                editorField(L10n.t("Модель *", "Model *", settings.language), text: $draft.model, placeholder: "GV80", capitalization: .characters)
                    .onChange(of: draft.model) { _, value in
                        let next = String(value.uppercased().prefix(100))
                        if next != value { draft.model = next }
                    }
                editorField(L10n.t("Комплектация", "Komplektatsiya", settings.language), text: $draft.trim, placeholder: "Prestige / Platinum")
                numericField(L10n.t("Год", "Yil", settings.language), text: $draft.year, placeholder: "2026", decimal: false)
            }

            VStack(alignment: .leading, spacing: 9) {
                fieldLabel(L10n.t("Состояние", "Holati", settings.language))
                HStack(spacing: 9) {
                    choiceButton(L10n.t("Новый", "Yangi", settings.language), selected: draft.isNew) {
                        draft.isNew = true
                        draft.mileageKm = "0"
                    }
                    choiceButton(L10n.t("С пробегом", "Yurgan", settings.language), selected: !draft.isNew) {
                        draft.isNew = false
                    }
                }
                if !draft.isNew {
                    numericField(L10n.t("Пробег, км", "Yurgan masofa, km", settings.language), text: $draft.mileageKm, placeholder: "45000", decimal: false)
                }
            }
        }
    }

    // MARK: 02 Delivery

    private var deliverySection: some View {
        editorSection(number: "02", title: L10n.t("Поставка", "Yetkazib berish", settings.language), detail: L10n.t("Статус управляет датой прибытия и публичным состоянием позиции.", "Status yetib kelish sanasi va pozitsiyaning holatini boshqaradi.", settings.language)) {
            VStack(alignment: .leading, spacing: 9) {
                fieldLabel(L10n.t("Статус", "Status", settings.language))
                LazyVGrid(columns: columns, spacing: 9) {
                    ForEach(allowedStatuses, id: \.rawValue) { status in
                        Button {
                            draft.status = status
                            if !draft.showsArrivalDate { draft.arrivalDate = "" }
                        } label: {
                            HStack(spacing: 7) {
                                Circle().fill(statusColor(status)).frame(width: 8, height: 8)
                                Text(status.adminTitle(settings.language))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)
                                Spacer(minLength: 4)
                                if draft.status == status { Image(systemName: "checkmark") }
                            }
                            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(draft.status == status ? Color(uiColor: .systemBackground) : Color.primary)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity)
                            .frame(height: 47)
                            .modifier(ASUAdminEditorRounded(selected: draft.status == status, radius: 18))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 7) {
                    fieldLabel(L10n.t("Страна поставки", "Yetkazib berish davlati", settings.language))
                    Picker("Country", selection: $draft.countryCode) {
                        ForEach(ASUAdminCarCountryFilter.allCases.filter { $0 != .all }) { item in
                            Text(item.title(settings.language)).tag(item.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 13)
                    .frame(height: 50)
                    .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }

            if draft.showsArrivalDate {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle(isOn: arrivalDateEnabledBinding) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(L10n.t("Ожидаемая дата прибытия", "Kutilayotgan yetib kelish sanasi", settings.language))
                                .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                            Text(L10n.t("Можно оставить без даты", "Sanani ko‘rsatmaslik mumkin", settings.language))
                                .font(.system(size: 11.5)).foregroundStyle(.secondary)
                        }
                    }
                    .tint(ASUDesign.success)

                    if !draft.arrivalDate.isEmpty {
                        DatePicker(
                            L10n.t("Дата", "Sana", settings.language),
                            selection: arrivalDateBinding,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                    }
                }
                .padding(14)
                .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }

    // MARK: 03 Specs

    private var specificationSection: some View {
        editorSection(number: "03", title: L10n.t("Характеристики", "Xususiyatlar", settings.language), detail: L10n.t("Двигатель, мощность, динамика, скорость и расход.", "Dvigatel, quvvat, dinamika, tezlik va sarf.", settings.language)) {
            LazyVGrid(columns: columns, spacing: 10) {
                editorField(L10n.t("Двигатель", "Dvigatel", settings.language), text: $draft.engineText, placeholder: "3.5 T-GDi V6")
                numericField(L10n.t("Объём, л", "Hajm, l", settings.language), text: $draft.engineDisplacementL, placeholder: "3.5", decimal: true)
            }

            HStack(spacing: 10) {
                menuField(
                    title: L10n.t("Топливо", "Yoqilg‘i", settings.language),
                    value: fuelTitle(draft.fuelType),
                    options: ["", "gasoline", "diesel", "hybrid", "phev", "electric"]
                ) { draft.fuelType = $0 }

                menuField(
                    title: L10n.t("Привод", "Yuritma", settings.language),
                    value: draft.driveType.isEmpty ? L10n.t("Не указано", "Ko‘rsatilmagan", settings.language) : draft.driveType,
                    options: ["", "AWD", "4WD", "RWD", "FWD"]
                ) { draft.driveType = $0 }
            }

            VStack(alignment: .leading, spacing: 9) {
                fieldLabel(L10n.t("Коробка", "Uzatmalar qutisi", settings.language))
                LazyVGrid(columns: columns, spacing: 9) {
                    ForEach(["automatic", "robot", "cvt", "manual"], id: \.self) { value in
                        choiceButton(transmissionTitle(value), selected: draft.transmission == value) {
                            draft.transmission = value
                        }
                    }
                }
            }

            LazyVGrid(columns: columns, spacing: 10) {
                numericField(L10n.t("Мест", "O‘rindiq", settings.language), text: $draft.seats, placeholder: "5", decimal: false)
                numericField(L10n.t("Мощность, л.с.", "Quvvat, ot k.", settings.language), text: $draft.horsepowerHp, placeholder: "375", decimal: false)
                numericField(L10n.t("Крутящий момент, Н·м", "Burilish momenti, N·m", settings.language), text: $draft.torqueNm, placeholder: "530", decimal: false)
                numericField(L10n.t("0–100 км/ч, сек", "0–100 km/soat, sek", settings.language), text: $draft.acceleration0100, placeholder: "5.5", decimal: true)
                numericField(L10n.t("Макс. скорость, км/ч", "Maks. tezlik, km/soat", settings.language), text: $draft.topSpeedKmh, placeholder: "240", decimal: false)
                numericField(L10n.t("Расход, л/100 км", "Sarf, l/100 km", settings.language), text: $draft.fuelConsumptionL100, placeholder: "11.2", decimal: true)
                numericField(L10n.t("Запас хода EV, км", "EV masofasi, km", settings.language), text: $draft.electricRangeKm, placeholder: "", decimal: false)
            }
        }
    }

    // MARK: 04 Variants + R2

    private var variantsSection: some View {
        editorSection(number: "04", title: L10n.t("Цвета и фотографии", "Ranglar va suratlar", settings.language), detail: L10n.t("Каждый цвет — отдельный вариант с собственным VIN, Stock и тремя группами фотографий.", "Har bir rang — o‘z VIN, Stock va uchta surat guruhi bilan alohida variant.", settings.language)) {
            VStack(spacing: 14) {
                ForEach(draft.variants.indices, id: \.self) { index in
                    variantCard(index: index)
                }
            }

            Button {
                guard draft.variants.count < maxVariantCount else { return }
                draft.variants.append(ASUAdminCarVariantDraft(index: draft.variants.count))
            } label: {
                Label(L10n.t("Добавить цвет", "Rang qo‘shish", settings.language), systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ASUPrimaryButtonStyle(prominent: false))
            .disabled(draft.variants.count >= maxVariantCount || isSaving)
        }
    }

    private func variantCard(index: Int) -> some View {
        let variant = draft.variants[index]
        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 10) {
                Text(String(format: "%02d", index + 1))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
                    .background(ASUDesign.soft, in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(variant.exteriorColorName.isEmpty
                         ? L10n.t("Цвет кузова \(index + 1)", "Kuzov rangi \(index + 1)", settings.language)
                         : variant.exteriorColorName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    if let dbID = variant.dbID {
                        Text("VARIANT ID \(dbID)")
                            .font(.system(size: 8.5, weight: .bold, design: .rounded))
                            .tracking(0.9)
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer()

                if draft.variants.count > 1 {
                    Button(role: .destructive) {
                        if variant.dbID != nil || variant.exteriorPhotoCount > 0 || !variant.existingInteriorPhotos.isEmpty || !variant.existingDetailPhotos.isEmpty {
                            pendingVariantRemoval = variant.localID
                        } else {
                            removeVariant(variant.localID)
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(isSaving)
                }
            }

            colorEditor(
                title: L10n.t("Цвет кузова", "Kuzov rangi", settings.language),
                nameTitle: L10n.t("Название цвета кузова", "Kuzov rangi nomi", settings.language),
                swatch: bindingForVariant(index, \.exteriorSwatch),
                name: bindingForVariant(index, \.exteriorColorName),
                palette: Self.exteriorSwatches
            )

            colorEditor(
                title: L10n.t("Цвет салона", "Salon rangi", settings.language),
                nameTitle: L10n.t("Название цвета салона", "Salon rangi nomi", settings.language),
                swatch: bindingForVariant(index, \.interiorSwatch),
                name: bindingForVariant(index, \.interiorColorName),
                palette: Self.interiorSwatches
            )

            LazyVGrid(columns: columns, spacing: 10) {
                editorField(L10n.t("VIN", "VIN", settings.language), text: bindingForVariant(index, \.vin), placeholder: "SALKABB90TA346327", capitalization: .characters)
                    .onChange(of: draft.variants[index].vin) { _, value in
                        let normalized = String(value.uppercased().filter { !$0.isWhitespace }.prefix(17))
                        if normalized != value { draft.variants[index].vin = normalized }
                    }
                editorField(L10n.t("Внутренний номер", "Ichki raqam", settings.language), text: bindingForVariant(index, \.stockNumber), placeholder: "ASU-0261", capitalization: .characters)
                    .onChange(of: draft.variants[index].stockNumber) { _, value in
                        let normalized = String(value.uppercased().prefix(80))
                        if normalized != value { draft.variants[index].stockNumber = normalized }
                    }
                numericField(L10n.t("Количество", "Miqdor", settings.language), text: bindingForVariant(index, \.quantity), placeholder: "1", decimal: false)
            }

            Divider()

            ASUAdminCarPhotoRail(
                group: .exterior,
                existingPhotos: bindingExistingPhotos(index, .exterior),
                newPhotos: bindingNewPhotos(index, .exterior),
                deletingPhotoID: deletingPhotoID,
                deleteExisting: { photo in
                    Task { await deleteExistingPhoto(variantIndex: index, group: .exterior, photo: photo) }
                }
            )
            .environmentObject(settings)

            ASUAdminCarPhotoRail(
                group: .interior,
                existingPhotos: bindingExistingPhotos(index, .interior),
                newPhotos: bindingNewPhotos(index, .interior),
                deletingPhotoID: deletingPhotoID,
                deleteExisting: { photo in
                    Task { await deleteExistingPhoto(variantIndex: index, group: .interior, photo: photo) }
                }
            )
            .environmentObject(settings)

            ASUAdminCarPhotoRail(
                group: .detail,
                existingPhotos: bindingExistingPhotos(index, .detail),
                newPhotos: bindingNewPhotos(index, .detail),
                deletingPhotoID: deletingPhotoID,
                deleteExisting: { photo in
                    Task { await deleteExistingPhoto(variantIndex: index, group: .detail, photo: photo) }
                }
            )
            .environmentObject(settings)
        }
        .padding(16)
        .background(ASUDesign.soft.opacity(0.55), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))
    }

    // MARK: 05 Commerce

    private var commerceSection: some View {
        editorSection(number: "05", title: L10n.t("Цена, обзор и публикация", "Narx, sharh va e’lon", settings.language), detail: L10n.t("Instagram хранится ссылкой. Публикация разрешена только при наличии фото кузова.", "Instagram havola sifatida saqlanadi. E’lon uchun kuzov surati bo‘lishi shart.", settings.language)) {
            HStack(spacing: 10) {
                numericField(L10n.t("Цена", "Narx", settings.language), text: $draft.price, placeholder: "258000", decimal: false)
                    .disabled(draft.priceOnRequest)
                    .opacity(draft.priceOnRequest ? 0.45 : 1)

                VStack(alignment: .leading, spacing: 7) {
                    fieldLabel(L10n.t("Валюта", "Valyuta", settings.language))
                    Picker("Currency", selection: $draft.currency) {
                        Text("USD").tag("USD")
                        Text("UZS").tag("UZS")
                        Text("EUR").tag("EUR")
                    }
                    .pickerStyle(.menu)
                    .frame(width: 88, height: 50)
                    .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .disabled(draft.priceOnRequest)
                .opacity(draft.priceOnRequest ? 0.45 : 1)
            }

            editorField(L10n.t("Instagram-обзор", "Instagram sharhi", settings.language), text: $draft.instagramUrl, placeholder: "https://www.instagram.com/reel/...", capitalization: .never)
                .keyboardType(.URL)
                .autocorrectionDisabled()

            VStack(spacing: 0) {
                switchRow(
                    title: L10n.t("Цена по запросу", "Narx so‘rov bo‘yicha", settings.language),
                    detail: L10n.t("В публичной карточке число будет скрыто.", "Ochiq kartada raqamli narx yashiriladi.", settings.language),
                    isOn: $draft.priceOnRequest,
                    tint: ASUDesign.orange
                )
                Divider().padding(.leading, 14)
                switchRow(
                    title: L10n.t("Рекомендуемый", "Tavsiya etilgan", settings.language),
                    detail: L10n.t("Поднимает автомобиль выше в каталоге.", "Avtomobilni katalogda yuqoriroq chiqaradi.", settings.language),
                    isOn: $draft.isFeatured,
                    tint: ASUDesign.orange
                )
                Divider().padding(.leading, 14)
                switchRow(
                    title: L10n.t("Опубликовать", "E’lon qilish", settings.language),
                    detail: draft.totalExteriorPhotoCount > 0
                        ? L10n.t("После сохранения автомобиль будет виден клиентам.", "Saqlangandan keyin avtomobil mijozlarga ko‘rinadi.", settings.language)
                        : L10n.t("Сначала добавьте хотя бы одну фотографию кузова.", "Avval kuzovning kamida bitta suratini qo‘shing.", settings.language),
                    isOn: $draft.isPublic,
                    tint: ASUDesign.success,
                    disabled: draft.totalExteriorPhotoCount == 0
                )
            }
            .asuCard(radius: 22, shadow: false)
        }
    }

    // MARK: 06 Description

    private var descriptionsSection: some View {
        editorSection(number: "06", title: L10n.t("Описание", "Tavsif", settings.language), detail: L10n.t("Русская и узбекская версии сохраняются отдельно.", "Ruscha va o‘zbekcha versiyalar alohida saqlanadi.", settings.language)) {
            multilineField(L10n.t("Коротко · RU", "Qisqa · RU", settings.language), text: $draft.shortDescriptionRu, minHeight: 92, maxLength: 220)
            multilineField("Qisqa · UZ", text: $draft.shortDescriptionUz, minHeight: 92, maxLength: 220)
            multilineField(L10n.t("Описание · RU", "Tavsif · RU", settings.language), text: $draft.descriptionRu, minHeight: 160, maxLength: 10_000)
            multilineField("Tavsif · UZ", text: $draft.descriptionUz, minHeight: 160, maxLength: 10_000)
        }
    }

    // MARK: Save dock / states

    private var saveDock: some View {
        VStack(spacing: 8) {
            if let savingText, isSaving {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text(savingText)
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }

            Button {
                Task { await save() }
            } label: {
                HStack(spacing: 9) {
                    if isSaving { ProgressView().tint(Color(uiColor: .systemBackground)) }
                    else { Image(systemName: "checkmark") }
                    Text(isSaving
                         ? L10n.t("Сохраняем…", "Saqlanmoqda…", settings.language)
                         : L10n.t("Сохранить автомобиль", "Avtomobilni saqlash", settings.language))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(ASUPrimaryButtonStyle())
            .disabled(isSaving || isLoadingDetail)
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) { Rectangle().fill(ASUDesign.line).frame(height: 0.7) }
    }

    private func errorCard(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 13.5, weight: .medium, design: .rounded))
                .foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.065), in: RoundedRectangle(cornerRadius: 21, style: .continuous))
    }

    private func successCard(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .font(.system(size: 13.5, weight: .semibold, design: .rounded))
            .foregroundStyle(ASUDesign.success)
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ASUDesign.success.opacity(0.07), in: RoundedRectangle(cornerRadius: 21, style: .continuous))
    }

    // MARK: API actions

    @MainActor
    private func loadDetailIfNeeded() async {
        guard let carID = mode.carID else { return }
        guard let token = session.bearerToken else {
            session.invalidateSession()
            dismiss()
            return
        }

        isLoadingDetail = true
        errorMessage = nil
        defer { isLoadingDetail = false }

        do {
            let detail = try await api.fullCarDetail(id: carID, token: token)
            draft = ASUAdminCarFormDraft(detail: detail)
            persistedCarID = detail.id
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

    @MainActor
    private func runAI() async {
        guard let token = session.bearerToken else {
            session.invalidateSession()
            dismiss()
            return
        }
        let source = aiText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard source.count >= 20 else {
            errorMessage = L10n.t("Вставьте текст с данными автомобиля.", "Avtomobil ma’lumotlari yozilgan matnni kiriting.", settings.language)
            return
        }

        aiLoading = true
        aiApplied = false
        aiWarnings = []
        errorMessage = nil
        defer { aiLoading = false }

        do {
            let response = try await api.carAIAutofill(text: source, token: token)
            applyAI(response.result)
            aiWarnings = response.result.warnings
            aiApplied = true
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

    @MainActor
    private func save() async {
        guard !isSaving else { return }
        guard let token = session.bearerToken else {
            session.invalidateSession()
            dismiss()
            return
        }

        errorMessage = nil
        successMessage = nil

        do {
            let requestedPublic = draft.isPublic
            let hadExistingExteriorBeforeSave = draft.hasExistingExteriorPhoto
            let publishDuringPrimarySave = requestedPublic && hadExistingExteriorBeforeSave && persistedCarID != nil
            let payload = try buildPayload(isPublic: publishDuringPrimarySave)

            isSaving = true
            savingText = L10n.t("Сохраняем данные в D1…", "Ma’lumotlar D1 ga saqlanmoqda…", settings.language)
            defer {
                isSaving = false
                savingText = nil
            }

            let receipt: ASUAdminCarPersistenceReceipt
            if persistedCarID == nil {
                receipt = try await api.createFullCar(payload: payload, token: token)
                persistedCarID = receipt.carID
            } else {
                receipt = try await api.saveFullCar(payload: payload, token: token)
            }

            try applySavedVariantIDs(receipt.variants)
            try await uploadPendingPhotos(carID: receipt.carID, token: token, coverAlreadyExists: hadExistingExteriorBeforeSave)

            if requestedPublic && !publishDuringPrimarySave {
                savingText = L10n.t("Подтверждаем публикацию…", "E’lon tasdiqlanmoqda…", settings.language)
                try await api.publishFullCar(id: receipt.carID, isPublic: true, token: token)
            }

            savingText = L10n.t("Проверяем запись D1 + R2…", "D1 + R2 yozuvi tekshirilmoqda…", settings.language)
            let verified = try await api.fullCarDetail(id: receipt.carID, token: token)
            guard verified.variants.count == draft.variants.count else {
                throw ASUAdminCarFormError.message(L10n.t("D1 не подтвердил все цветовые варианты.", "D1 barcha rang variantlarini tasdiqlamadi.", settings.language))
            }
            if requestedPublic && !verified.isPublic {
                throw ASUAdminCarFormError.message(L10n.t("Сервер не подтвердил публикацию автомобиля.", "Server avtomobil e’lonini tasdiqlamadi.", settings.language))
            }

            draft = ASUAdminCarFormDraft(detail: verified)
            persistedCarID = verified.id
            successMessage = L10n.t("Автомобиль сохранён. D1 + R2 подтвердили запись.", "Avtomobil saqlandi. D1 + R2 yozuvni tasdiqladi.", settings.language)
            onSaved(verified.id)

            if !reduceMotion {
                try? await Task.sleep(nanoseconds: 700_000_000)
            }
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

    @MainActor
    private func uploadPendingPhotos(carID: Int, token: String, coverAlreadyExists: Bool) async throws {
        let total = draft.totalNewPhotoCount
        guard total > 0 else { return }
        var completed = 0
        var coverAssigned = coverAlreadyExists

        for variantIndex in draft.variants.indices {
            guard let variantID = draft.variants[variantIndex].dbID else {
                throw ASUAdminCarFormError.message(L10n.t("D1 не подтвердил цветовой вариант.", "D1 rang variantini tasdiqlamadi.", settings.language))
            }

            for group in ASUAdminPhotoGroup.allCases {
                while let photo = firstPendingPhoto(variantIndex: variantIndex, group: group) {
                    savingText = L10n.t("Загружаем фото \(completed + 1)/\(total)…", "Surat yuklanmoqda \(completed + 1)/\(total)…", settings.language)
                    let existingCount = existingPhotoCount(variantIndex: variantIndex, group: group)
                    let shouldCover = group == .exterior && !coverAssigned
                    let uploaded = try await api.uploadCarMedia(
                        carID: carID,
                        variantID: variantID,
                        group: group,
                        photo: photo,
                        sortOrder: existingCount,
                        isCover: shouldCover,
                        token: token
                    )
                    if shouldCover { coverAssigned = true }
                    movePendingPhotoToExisting(variantIndex: variantIndex, group: group, photoID: photo.id, uploaded: uploaded)
                    completed += 1
                }
            }
        }
    }

    @MainActor
    private func deleteExistingPhoto(variantIndex: Int, group: ASUAdminPhotoGroup, photo: ASUAdminCarDetailMedia) async {
        guard deletingPhotoID == nil, !isSaving else { return }
        guard let token = session.bearerToken else {
            session.invalidateSession()
            dismiss()
            return
        }

        deletingPhotoID = photo.id
        errorMessage = nil
        defer { deletingPhotoID = nil }

        do {
            try await api.deleteCarMedia(id: photo.id, token: token)
            removeExistingPhotoLocally(variantIndex: variantIndex, group: group, photoID: photo.id, wasCover: photo.isCover)
            if draft.totalExteriorPhotoCount == 0 { draft.isPublic = false }
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

    // MARK: Payload / validation

    private func buildPayload(isPublic: Bool) throws -> ASUAdminCarSavePayload {
        let brand = draft.brand.trimmingCharacters(in: .whitespacesAndNewlines)
        let model = draft.model.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !brand.isEmpty else { throw formError("Выберите марку автомобиля.", "Avtomobil markasini tanlang.") }
        guard !model.isEmpty else { throw formError("Укажите модель автомобиля.", "Avtomobil modelini kiriting.") }

        guard let year = Int(draft.year), (1900...2100).contains(year) else {
            throw formError("Проверьте год автомобиля.", "Avtomobil yilini tekshiring.")
        }

        guard draft.status != .unknown else { throw formError("Выберите корректный статус автомобиля.", "To‘g‘ri avtomobil statusini tanlang.") }
        if mode.isCreate && (draft.status == .sold || draft.status == .hidden) {
            throw formError("Для нового автомобиля выберите рабочий статус.", "Yangi avtomobil uchun faol statusni tanlang.")
        }

        let allowedCountries = Set(ASUAdminCarCountryFilter.allCases.compactMap(\.queryValue))
        guard allowedCountries.contains(draft.countryCode) else {
            throw formError("Проверьте страну поставки.", "Yetkazib berish davlatini tekshiring.")
        }

        if draft.showsArrivalDate && !draft.arrivalDate.isEmpty && Self.dateFromISO(draft.arrivalDate) == nil {
            throw formError("Проверьте дату прибытия.", "Yetib kelish sanasini tekshiring.")
        }

        let mileage = try integerValue(draft.isNew ? "0" : draft.mileageKm, min: 0, max: 20_000_000, required: !draft.isNew, ru: "Проверьте пробег.", uz: "Yurgan masofani tekshiring.")
        let seats = try integerValue(draft.seats, min: 1, max: 99, required: false, ru: "Проверьте количество мест.", uz: "O‘rindiqlar sonini tekshiring.")
        let hp = try integerValue(draft.horsepowerHp, min: 1, max: 5000, required: false, ru: "Проверьте мощность.", uz: "Quvvatni tekshiring.")
        let torque = try integerValue(draft.torqueNm, min: 1, max: 10_000, required: false, ru: "Проверьте крутящий момент.", uz: "Burilish momentini tekshiring.")
        let topSpeed = try integerValue(draft.topSpeedKmh, min: 1, max: 1000, required: false, ru: "Проверьте максимальную скорость.", uz: "Maksimal tezlikni tekshiring.")
        let evRange = try integerValue(draft.electricRangeKm, min: 1, max: 5000, required: false, ru: "Проверьте запас хода EV.", uz: "EV masofasini tekshiring.")
        let displacement = try doubleValue(draft.engineDisplacementL, min: 0.1, max: 20, ru: "Проверьте объём двигателя.", uz: "Dvigatel hajmini tekshiring.")
        let acceleration = try doubleValue(draft.acceleration0100, min: 0.5, max: 60, ru: "Проверьте разгон 0–100.", uz: "0–100 tezlanishni tekshiring.")
        let consumption = try doubleValue(draft.fuelConsumptionL100, min: 0.1, max: 100, ru: "Проверьте расход топлива.", uz: "Yoqilg‘i sarfini tekshiring.")

        let price: Int64?
        let trimmedPrice = draft.price.trimmingCharacters(in: .whitespacesAndNewlines)
        if draft.priceOnRequest || trimmedPrice.isEmpty {
            price = nil
        } else {
            let cleanPrice = trimmedPrice.filter(\.isNumber)
            guard let value = Int64(cleanPrice), value >= 0, value <= 9_000_000_000_000 else {
                throw formError("Проверьте цену автомобиля.", "Avtomobil narxini tekshiring.")
            }
            price = value
        }

        guard ["USD", "UZS", "EUR"].contains(draft.currency) else {
            throw formError("Проверьте валюту.", "Valyutani tekshiring.")
        }
        guard looksLikeInstagram(draft.instagramUrl) else {
            throw formError("Проверьте ссылку Instagram.", "Instagram havolasini tekshiring.")
        }

        guard !draft.variants.isEmpty, draft.variants.count <= maxVariantCount else {
            throw formError("Добавьте хотя бы один цветовой вариант.", "Kamida bitta rang variantini qo‘shing.")
        }
        if draft.isPublic && draft.totalExteriorPhotoCount == 0 {
            throw formError("Добавьте хотя бы одну фотографию кузова перед публикацией.", "E’lon qilishdan oldin kuzovning kamida bitta suratini qo‘shing.")
        }

        var seenVIN = Set<String>()
        var seenStock = Set<String>()
        var variantInputs: [ASUAdminCarVariantInput] = []
        for variant in draft.variants {
            let vin = variant.vin.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            if !vin.isEmpty {
                guard vin.range(of: "^[A-HJ-NPR-Z0-9]{11,17}$", options: .regularExpression) != nil else {
                    throw formError("Укажите VIN корректно или оставьте поле пустым.", "VIN ni to‘g‘ri kiriting yoki maydonni bo‘sh qoldiring.")
                }
                guard seenVIN.insert(vin).inserted else {
                    throw formError("Один VIN указан дважды.", "Bitta VIN ikki marta kiritilgan.")
                }
            }

            let stock = variant.stockNumber.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            if !stock.isEmpty && !seenStock.insert(stock).inserted {
                throw formError("Один внутренний номер указан дважды.", "Bitta ichki raqam ikki marta kiritilgan.")
            }

            guard Self.validHex(variant.exteriorSwatch), Self.validHex(variant.interiorSwatch) else {
                throw formError("Проверьте цвета варианта.", "Variant ranglarini tekshiring.")
            }
            guard let quantity = Int(variant.quantity), (1...99).contains(quantity) else {
                throw formError("Проверьте количество автомобилей в варианте.", "Variantdagi avtomobillar sonini tekshiring.")
            }

            variantInputs.append(ASUAdminCarVariantInput(
                id: variant.dbID,
                exteriorColorName: cleanOptional(variant.exteriorColorName, max: 120),
                exteriorSwatch: variant.exteriorSwatch.lowercased(),
                interiorColorName: cleanOptional(variant.interiorColorName, max: 120),
                interiorSwatch: variant.interiorSwatch.lowercased(),
                vin: vin.isEmpty ? nil : vin,
                stockNumber: stock.isEmpty ? nil : stock,
                quantity: quantity
            ))
        }

        return ASUAdminCarSavePayload(
            id: persistedCarID,
            brand: String(brand.prefix(80)),
            model: String(model.prefix(100)),
            year: year,
            trim: cleanOptional(draft.trim, max: 120),
            status: draft.status.rawValue,
            countryCode: draft.countryCode,
            arrivalDate: draft.showsArrivalDate ? cleanOptional(draft.arrivalDate, max: 10) : nil,
            isNew: draft.isNew,
            mileageKm: draft.isNew ? 0 : mileage,
            engineText: cleanOptional(draft.engineText, max: 180),
            engineDisplacementL: displacement,
            fuelType: cleanOptional(draft.fuelType, max: 80),
            driveType: cleanOptional(draft.driveType, max: 80),
            transmission: draft.transmission.isEmpty ? "automatic" : draft.transmission,
            seats: seats,
            horsepowerHp: hp,
            torqueNm: torque,
            acceleration0100: acceleration,
            topSpeedKmh: topSpeed,
            fuelConsumptionL100: consumption,
            electricRangeKm: evRange,
            price: price,
            currency: draft.currency,
            priceOnRequest: draft.priceOnRequest,
            instagramUrl: cleanOptional(draft.instagramUrl, max: 500),
            shortDescriptionRu: cleanOptional(draft.shortDescriptionRu, max: 220),
            shortDescriptionUz: cleanOptional(draft.shortDescriptionUz, max: 220),
            descriptionRu: cleanOptional(draft.descriptionRu, max: 10_000),
            descriptionUz: cleanOptional(draft.descriptionUz, max: 10_000),
            isPublic: isPublic,
            isFeatured: draft.isFeatured,
            variants: variantInputs
        )
    }

    // MARK: AI application

    private func applyAI(_ result: ASUAdminCarAIResult) {
        let knownBrands = Set(ASUHomeContent.brands.map(\.name))
        if let brand = result.brand, knownBrands.contains(brand) { draft.brand = brand }
        if let model = result.model { draft.model = String(model.uppercased().prefix(100)) }
        if let year = result.year { draft.year = String(year) }
        if let trim = result.trim { draft.trim = trim }
        if let rawStatus = result.status, let status = CarStatus(rawValue: rawStatus), allowedStatuses.contains(status) {
            draft.status = status
        }
        if let country = result.countryCode, ASUAdminCarCountryFilter(rawValue: country) != nil, country != "all" {
            draft.countryCode = country
        }
        if let date = result.arrivalDate { draft.arrivalDate = date }
        if let isNew = result.isNew {
            draft.isNew = isNew
            if isNew && result.mileageKm == nil { draft.mileageKm = "0" }
        }
        if let mileage = result.mileageKm { draft.mileageKm = String(mileage) }
        assign(&draft.engineText, result.engineText)
        assignNumber(&draft.engineDisplacementL, result.engineDisplacementL)
        assign(&draft.fuelType, result.fuelType)
        assign(&draft.driveType, result.driveType)
        assign(&draft.transmission, result.transmission)
        assignInt(&draft.seats, result.seats)
        assignInt(&draft.horsepowerHp, result.horsepowerHp)
        assignInt(&draft.torqueNm, result.torqueNm)
        assignNumber(&draft.acceleration0100, result.acceleration0100)
        assignInt(&draft.topSpeedKmh, result.topSpeedKmh)
        assignNumber(&draft.fuelConsumptionL100, result.fuelConsumptionL100)
        assignInt(&draft.electricRangeKm, result.electricRangeKm)
        if let price = result.price { draft.price = String(price) }
        if let currency = result.currency, ["USD", "UZS", "EUR"].contains(currency) { draft.currency = currency }
        if let priceOnRequest = result.priceOnRequest { draft.priceOnRequest = priceOnRequest }
        assign(&draft.instagramUrl, result.instagramUrl)
        assign(&draft.shortDescriptionRu, result.shortDescriptionRu)
        assign(&draft.shortDescriptionUz, result.shortDescriptionUz)
        assign(&draft.descriptionRu, result.descriptionRu)
        assign(&draft.descriptionUz, result.descriptionUz)

        for (index, source) in result.variants.enumerated() {
            if index >= draft.variants.count {
                draft.variants.append(ASUAdminCarVariantDraft(index: index))
            }
            if let value = source.exteriorColorName { draft.variants[index].exteriorColorName = value }
            if let value = source.exteriorSwatch, Self.validHex(value) { draft.variants[index].exteriorSwatch = value.lowercased() }
            if let value = source.interiorColorName { draft.variants[index].interiorColorName = value }
            if let value = source.interiorSwatch, Self.validHex(value) { draft.variants[index].interiorSwatch = value.lowercased() }
            if let value = source.vin { draft.variants[index].vin = String(value.uppercased().prefix(17)) }
            if let value = source.stockNumber { draft.variants[index].stockNumber = String(value.uppercased().prefix(80)) }
            if let value = source.quantity, (1...99).contains(value) { draft.variants[index].quantity = String(value) }
        }

        if !draft.showsArrivalDate { draft.arrivalDate = "" }
    }

    // MARK: Local mutations

    private func removeVariant(_ localID: UUID) {
        guard draft.variants.count > 1 else { return }
        draft.variants.removeAll { $0.localID == localID }
        if draft.totalExteriorPhotoCount == 0 { draft.isPublic = false }
    }

    private func applySavedVariantIDs(_ saved: [ASUAdminSavedVariant]) throws {
        guard saved.count == draft.variants.count else {
            throw formError("D1 не подтвердил все цветовые варианты.", "D1 barcha rang variantlarini tasdiqlamadi.")
        }
        for item in saved {
            guard draft.variants.indices.contains(item.index) else {
                throw formError("D1 вернул некорректный индекс варианта.", "D1 noto‘g‘ri variant indeksini qaytardi.")
            }
            draft.variants[item.index].dbID = item.id
        }
    }

    private func firstPendingPhoto(variantIndex: Int, group: ASUAdminPhotoGroup) -> ASUAdminPendingPhoto? {
        guard draft.variants.indices.contains(variantIndex) else { return nil }
        switch group {
        case .exterior: return draft.variants[variantIndex].exteriorPhotos.first
        case .interior: return draft.variants[variantIndex].interiorPhotos.first
        case .detail: return draft.variants[variantIndex].detailPhotos.first
        }
    }

    private func existingPhotoCount(variantIndex: Int, group: ASUAdminPhotoGroup) -> Int {
        guard draft.variants.indices.contains(variantIndex) else { return 0 }
        return draft.variants[variantIndex].existingPhotos(for: group).count
    }

    private func movePendingPhotoToExisting(variantIndex: Int, group: ASUAdminPhotoGroup, photoID: UUID, uploaded: ASUAdminUploadedMedia) {
        guard draft.variants.indices.contains(variantIndex) else { return }
        let media = uploaded.asDetailMedia()
        switch group {
        case .exterior:
            draft.variants[variantIndex].exteriorPhotos.removeAll { $0.id == photoID }
            draft.variants[variantIndex].existingExteriorPhotos.append(media)
        case .interior:
            draft.variants[variantIndex].interiorPhotos.removeAll { $0.id == photoID }
            draft.variants[variantIndex].existingInteriorPhotos.append(media)
        case .detail:
            draft.variants[variantIndex].detailPhotos.removeAll { $0.id == photoID }
            draft.variants[variantIndex].existingDetailPhotos.append(media)
        }
    }

    private func removeExistingPhotoLocally(variantIndex: Int, group: ASUAdminPhotoGroup, photoID: Int, wasCover: Bool) {
        guard draft.variants.indices.contains(variantIndex) else { return }
        switch group {
        case .exterior:
            draft.variants[variantIndex].existingExteriorPhotos.removeAll { $0.id == photoID }
            if wasCover {
                promoteFirstLocalExteriorCover()
            }
        case .interior:
            draft.variants[variantIndex].existingInteriorPhotos.removeAll { $0.id == photoID }
        case .detail:
            draft.variants[variantIndex].existingDetailPhotos.removeAll { $0.id == photoID }
        }
    }

    private func promoteFirstLocalExteriorCover() {
        for variantIndex in draft.variants.indices {
            guard let firstIndex = draft.variants[variantIndex].existingExteriorPhotos.indices.first else { continue }
            let photo = draft.variants[variantIndex].existingExteriorPhotos[firstIndex]
            draft.variants[variantIndex].existingExteriorPhotos[firstIndex] = ASUAdminCarDetailMedia(
                id: photo.id,
                publicUrl: photo.publicUrl,
                objectKey: photo.objectKey,
                isCover: true,
                sortOrder: photo.sortOrder
            )
            return
        }
    }

    // MARK: Bindings

    private func bindingForVariant(_ index: Int, _ keyPath: WritableKeyPath<ASUAdminCarVariantDraft, String>) -> Binding<String> {
        Binding(
            get: { draft.variants.indices.contains(index) ? draft.variants[index][keyPath: keyPath] : "" },
            set: { value in
                guard draft.variants.indices.contains(index) else { return }
                draft.variants[index][keyPath: keyPath] = value
            }
        )
    }

    private func bindingExistingPhotos(_ index: Int, _ group: ASUAdminPhotoGroup) -> Binding<[ASUAdminCarDetailMedia]> {
        Binding(
            get: {
                guard draft.variants.indices.contains(index) else { return [] }
                return draft.variants[index].existingPhotos(for: group)
            },
            set: { value in
                guard draft.variants.indices.contains(index) else { return }
                switch group {
                case .exterior: draft.variants[index].existingExteriorPhotos = value
                case .interior: draft.variants[index].existingInteriorPhotos = value
                case .detail: draft.variants[index].existingDetailPhotos = value
                }
            }
        )
    }

    private func bindingNewPhotos(_ index: Int, _ group: ASUAdminPhotoGroup) -> Binding<[ASUAdminPendingPhoto]> {
        Binding(
            get: {
                guard draft.variants.indices.contains(index) else { return [] }
                return draft.variants[index].newPhotos(for: group)
            },
            set: { value in
                guard draft.variants.indices.contains(index) else { return }
                switch group {
                case .exterior: draft.variants[index].exteriorPhotos = value
                case .interior: draft.variants[index].interiorPhotos = value
                case .detail: draft.variants[index].detailPhotos = value
                }
            }
        )
    }

    private var arrivalDateEnabledBinding: Binding<Bool> {
        Binding(
            get: { !draft.arrivalDate.isEmpty },
            set: { enabled in
                draft.arrivalDate = enabled ? Self.isoDate(Date()) : ""
            }
        )
    }

    private var arrivalDateBinding: Binding<Date> {
        Binding(
            get: { Self.dateFromISO(draft.arrivalDate) ?? Date() },
            set: { draft.arrivalDate = Self.isoDate($0) }
        )
    }

    // MARK: Reusable form components

    private func editorSection<Content: View>(number: String, title: String, detail: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack(alignment: .top, spacing: 14) {
                Text(number)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
                    .background(ASUDesign.soft, in: Circle())
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .tracking(-0.45)
                    Text(detail)
                        .font(.system(size: 12.5))
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
            }
            content()
        }
        .padding(17)
        .asuCard(radius: 28)
    }

    private func editorField(
        _ title: String,
        text: Binding<String>,
        placeholder: String,
        capitalization: TextInputAutocapitalization = .sentences
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            fieldLabel(title)
            TextField(placeholder, text: text)
                .font(.system(size: 14.5, weight: .medium, design: .rounded))
                .textInputAutocapitalization(capitalization)
                .padding(.horizontal, 13)
                .frame(height: 50)
                .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))
        }
    }

    private func numericField(_ title: String, text: Binding<String>, placeholder: String, decimal: Bool) -> some View {
        editorField(title, text: text, placeholder: placeholder, capitalization: .never)
            .keyboardType(decimal ? .decimalPad : .numberPad)
    }

    private func multilineField(_ title: String, text: Binding<String>, minHeight: CGFloat, maxLength: Int) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                fieldLabel(title)
                Spacer()
                Text("\(text.wrappedValue.count)/\(maxLength)")
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
            TextEditor(text: text)
                .font(.system(size: 14, design: .rounded))
                .frame(minHeight: minHeight)
                .padding(10)
                .scrollContentBackground(.hidden)
                .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))
                .onChange(of: text.wrappedValue) { _, value in
                    if value.count > maxLength { text.wrappedValue = String(value.prefix(maxLength)) }
                }
        }
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
    }

    private func choiceButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).lineLimit(1).minimumScaleFactor(0.75)
                Spacer(minLength: 4)
                if selected { Image(systemName: "checkmark") }
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(selected ? Color(uiColor: .systemBackground) : Color.primary)
            .padding(.horizontal, 13)
            .frame(maxWidth: .infinity)
            .frame(height: 47)
            .modifier(ASUAdminEditorRounded(selected: selected, radius: 18))
        }
        .buttonStyle(.plain)
    }

    private func menuField(title: String, value: String, options: [String], select: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            fieldLabel(title)
            Menu {
                ForEach(options, id: \.self) { item in
                    Button(menuOptionTitle(item)) { select(item) }
                }
            } label: {
                HStack {
                    Text(value).lineLimit(1).minimumScaleFactor(0.75)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.horizontal, 13)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    private func colorEditor(title: String, nameTitle: String, swatch: Binding<String>, name: Binding<String>, palette: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldLabel(title)
            ScrollView(.horizontal) {
                HStack(spacing: 9) {
                    ForEach(palette, id: \.self) { color in
                        Button {
                            swatch.wrappedValue = color
                        } label: {
                            Circle()
                                .fill(Color(asuHex: color, fallback: .primary))
                                .frame(width: 36, height: 36)
                                .overlay(Circle().stroke(swatch.wrappedValue.caseInsensitiveCompare(color) == .orderedSame ? Color.primary : ASUDesign.lineStrong, lineWidth: swatch.wrappedValue.caseInsensitiveCompare(color) == .orderedSame ? 2.2 : 0.8))
                                .padding(3)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)

            HStack(spacing: 10) {
                editorField(nameTitle, text: name, placeholder: L10n.t("Название", "Nomi", settings.language))
                editorField("HEX", text: swatch, placeholder: "#111214", capitalization: .characters)
                    .frame(width: 116)
            }
        }
    }

    private func switchRow(title: String, detail: String, isOn: Binding<Bool>, tint: Color, disabled: Bool = false) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                Text(detail)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(tint)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
        .padding(14)
    }

    // MARK: Helpers

    private var maxVariantCount: Int { mode.isCreate ? 20 : 30 }

    private func statusColor(_ status: CarStatus) -> Color {
        switch status {
        case .inStock, .inShowroom: return ASUDesign.success
        case .reserved: return ASUDesign.orange
        case .sold, .hidden: return Color.secondary.opacity(0.82)
        case .inTransit, .madeToOrder: return Color.secondary.opacity(0.68)
        case .unknown: return Color.secondary.opacity(0.55)
        }
    }

    private func fuelTitle(_ value: String) -> String {
        switch value {
        case "gasoline": return L10n.t("Бензин", "Benzin", settings.language)
        case "diesel": return L10n.t("Дизель", "Dizel", settings.language)
        case "hybrid": return L10n.t("Гибрид", "Gibrid", settings.language)
        case "phev": return L10n.t("Plug-in гибрид", "Plug-in gibrid", settings.language)
        case "electric": return L10n.t("Электро", "Elektr", settings.language)
        default: return L10n.t("Не указано", "Ko‘rsatilmagan", settings.language)
        }
    }

    private func transmissionTitle(_ value: String) -> String {
        switch value {
        case "robot": return L10n.t("Робот", "Robot", settings.language)
        case "cvt": return L10n.t("Вариатор", "Variator", settings.language)
        case "manual": return L10n.t("Механика", "Mexanika", settings.language)
        default: return L10n.t("Автомат", "Avtomat", settings.language)
        }
    }

    private func menuOptionTitle(_ value: String) -> String {
        if ["gasoline", "diesel", "hybrid", "phev", "electric"].contains(value) { return fuelTitle(value) }
        if value.isEmpty { return L10n.t("Не указано", "Ko‘rsatilmagan", settings.language) }
        return value
    }

    private func integerValue(_ raw: String, min: Int, max: Int, required: Bool, ru: String, uz: String) throws -> Int? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty {
            if required { throw formError(ru, uz) }
            return nil
        }
        guard let number = Int(value), (min...max).contains(number) else { throw formError(ru, uz) }
        return number
    }

    private func doubleValue(_ raw: String, min: Double, max: Double, ru: String, uz: String) throws -> Double? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty { return nil }
        guard let number = Double(value.replacingOccurrences(of: ",", with: ".")), number >= min, number <= max else {
            throw formError(ru, uz)
        }
        return number
    }

    private func cleanOptional(_ raw: String, max: Int) -> String? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : String(value.prefix(max))
    }

    private func looksLikeInstagram(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        let candidate = trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") ? trimmed : "https://\(trimmed)"
        guard let host = URL(string: candidate)?.host?.lowercased() else { return false }
        return host == "instagram.com" || host.hasSuffix(".instagram.com")
    }

    private func formError(_ ru: String, _ uz: String) -> ASUAdminCarFormError {
        .message(L10n.t(ru, uz, settings.language))
    }

    private func assign(_ target: inout String, _ value: String?) {
        if let value, !value.isEmpty { target = value }
    }

    private func assignInt(_ target: inout String, _ value: Int?) {
        if let value { target = String(value) }
    }

    private func assignNumber(_ target: inout String, _ value: Double?) {
        if let value {
            target = value.rounded() == value ? String(Int(value)) : String(value)
        }
    }

    private static func validHex(_ value: String) -> Bool {
        value.range(of: "^#[0-9A-Fa-f]{6}$", options: .regularExpression) != nil
    }

    private static func dateFromISO(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        return formatter.date(from: value)
    }

    private static func isoDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static let exteriorSwatches = ["#111214", "#f4f4f0", "#7b7e82", "#b7bbc0", "#193b73", "#7f2024", "#2c4738", "#5f493b"]
    private static let interiorSwatches = ["#111214", "#ece9df", "#c7ad86", "#68483a", "#7d2828", "#9b5c31", "#73767a"]
}

private enum ASUAdminCarFormError: LocalizedError {
    case message(String)

    var errorDescription: String? {
        switch self {
        case .message(let text): return text
        }
    }
}

private struct ASUAdminEditorRounded: ViewModifier {
    let selected: Bool
    let radius: CGFloat

    @ViewBuilder
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
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
