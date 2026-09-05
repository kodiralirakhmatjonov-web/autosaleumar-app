import SwiftUI
import Foundation

struct CompareView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showPicker = false
    @State private var pickerSearch = ""
    @State private var selectedCriteria: Set<AdviceCriterion> = []
    @State private var budget = ""
    @State private var currency: ASUCurrency = .USD
    @State private var note = ""
    @State private var details: [Int: CarDetail] = [:]
    @State private var availability = CompareAIAvailability(available: false, reason: nil)
    @State private var aiLoading: CompareAIAction?
    @State private var aiResult: CompareAIResult?
    @State private var aiError: String?
    @State private var quota: CompareQuota?

    private let api = ClientAPI()

    private var selectedCars: [Car] { store.compareCars }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 28) {
                    intro
                    selectedRail
                    if selectedCars.count >= 2 {
                        differenceSection
                        advisorSection
                    } else {
                        selectionHint
                    }
                }
                .padding(.horizontal, ASUDesign.pagePadding)
                .padding(.bottom, 34)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(ASUDesign.page)
            .navigationTitle(L10n.t("Сравнение", "Solishtirish", settings.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if selectedCars.count < 3 {
                        Button { showPicker = true } label: { Image(systemName: "plus") }
                    }
                }
            }
            .sheet(isPresented: $showPicker) { pickerSheet }
            .task {
                availability = await api.compareAvailability()
                await loadDetails()
            }
            .onChange(of: store.compareIDs) { _, _ in
                Task { await loadDetails() }
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AUTO SALE UMAR · COMPARE")
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(.secondary)
            Text(L10n.t(
                "Сравните не модели.\nСравните конкретные автомобили.",
                "Modellarni emas.\nAniq avtomobillarni solishtiring.",
                settings.language
            ))
            .asuSectionTitle(size: 35)
            Text(L10n.t(
                "Цена, статус и характеристики берутся из каталога Auto Sale Umar. Консультант подключается только когда вы просите совет или углублённое сравнение.",
                "Narx, status va xususiyatlar Auto Sale Umar katalogidan olinadi. Maslahatchi faqat maslahat yoki chuqur solishtirish so‘ralganda ishga tushadi.",
                settings.language
            ))
            .font(.system(size: 15))
            .foregroundStyle(.secondary)
            .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 6)
    }

    private var selectedRail: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.t("ВАШЕ СРАВНЕНИЕ", "SIZNING SOLISHTIRISHINGIZ", settings.language))
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(.secondary)
                    Text(L10n.t("Выберите до трёх автомобилей", "Uchtagacha avtomobil tanlang", settings.language))
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                }
                Spacer()
                Text("\(selectedCars.count)/3")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(selectedCars) { car in
                        selectedCard(car)
                    }
                    if selectedCars.count < 3 {
                        Button { showPicker = true } label: {
                            VStack(spacing: 12) {
                                ASUGlassCircleSurface(size: 52) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                Text(L10n.t("Добавить\nавтомобиль", "Avtomobil\nqo‘shish", settings.language))
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(width: 154, height: 208)
                            .modifier(CompareGlassCard())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 3)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func selectedCard(_ car: Car) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                ASURemoteImage(url: car.primaryImageURL, contentMode: .fit)
                    .frame(width: 178, height: 110)
                    .background(ASUDesign.gallery)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                Button { store.toggleCompare(car) } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 32, height: 32)
                        .modifier(CompareGlassCircle())
                }
                .buttonStyle(.plain)
                .padding(7)
            }
            Text(car.displayName)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .lineLimit(2)
            Text(Format.price(car, language: settings.language))
                .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(width: 198, height: 208, alignment: .topLeading)
        .modifier(CompareGlassCard())
    }

    private var selectionHint: some View {
        VStack(spacing: 15) {
            ASUGlassCircleSurface(size: 78) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 27, weight: .medium))
            }
            Text(L10n.t("Сначала выберите минимум два автомобиля.", "Avval kamida ikkita avtomobil tanlang.", settings.language))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
            Button(L10n.t("Добавить автомобиль", "Avtomobil qo‘shish", settings.language)) { showPicker = true }
                .buttonStyle(ASUPrimaryButtonStyle())
        }
        .padding(22)
        .asuCard()
    }

    private var differenceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.t("СРАВНЕНИЕ", "SOLISHTIRISH", settings.language))
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                .tracking(1)
                .foregroundStyle(.secondary)
            Text(L10n.t("Разница видна сразу.", "Farq darhol ko‘rinadi.", settings.language))
                .asuSectionTitle(size: 28)

            VStack(spacing: 0) {
                compareRow(L10n.t("Цена", "Narx", settings.language)) { car in Format.price(car, language: settings.language) }
                compareRow(L10n.t("Статус", "Status", settings.language)) { car in car.status.title(settings.language) }
                compareRow(L10n.t("Год", "Yil", settings.language)) { car in car.year.map(String.init) ?? "—" }
                compareRow(L10n.t("Комплектация", "Komplektatsiya", settings.language)) { car in car.trim ?? "—" }
                compareRow(L10n.t("Двигатель", "Dvigatel", settings.language)) { car in detail(for: car)?.engineText ?? car.engineText ?? "—" }
                compareRow(L10n.t("Мощность", "Quvvat", settings.language)) { car in detail(for: car)?.performance.horsepowerHp.map { "\($0) л.с." } ?? "—" }
                compareRow(L10n.t("0–100 км/ч", "0–100 km/soat", settings.language)) { car in detail(for: car)?.performance.acceleration0100.map { String(format: "%.1f сек.", $0) } ?? "—" }
                compareRow(L10n.t("Макс. скорость", "Maks. tezlik", settings.language)) { car in detail(for: car)?.performance.topSpeedKmh.map { "\($0) км/ч" } ?? "—" }
                compareRow(L10n.t("Топливо", "Yoqilg‘i", settings.language)) { car in car.fuelType ?? "—" }
                compareRow(L10n.t("Привод", "Privod", settings.language)) { car in car.driveType ?? "—" }
                compareRow(L10n.t("Коробка", "Uzatma", settings.language)) { car in car.transmission ?? "—" }
                compareRow(L10n.t("Мест", "O‘rin", settings.language)) { car in car.seats.map(String.init) ?? "—" }
                compareRow(L10n.t("Пробег", "Yurgan masofa", settings.language)) { car in car.mileageKm.map { "\($0) км" } ?? "—" }
                compareRow(L10n.t("Цвет кузова", "Kuzov rangi", settings.language), divider: false) { car in car.exteriorColor ?? "—" }
            }
            .asuCard(radius: 26)
        }
    }

    private func compareRow(_ label: String, divider: Bool = true, value: @escaping (Car) -> String) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text(label)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                HStack(alignment: .top, spacing: 8) {
                    ForEach(selectedCars) { car in
                        Text(value(car))
                            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                            .lineLimit(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(15)
            if divider { Divider().padding(.leading, 15) }
        }
    }

    private var advisorSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(LinearGradient(colors: [.black, Color(red: 0.075, green: 0.075, blue: 0.085)], startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle()
                .fill(ASUDesign.orange.opacity(0.18))
                .frame(width: 210, height: 210)
                .blur(radius: 44)
                .offset(x: 120, y: -130)

            VStack(alignment: .leading, spacing: 18) {
                Label("AUTO SALE UMAR · \(L10n.t("КОНСУЛЬТАНТ", "MASLAHATCHI", settings.language))", systemImage: "sparkles")
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.64))

                Text(L10n.t("Нужен вывод, а не ещё одна таблица?", "Yana bir jadval emas, aniq xulosa kerakmi?", settings.language))
                    .font(.system(size: 29, weight: .bold, design: .rounded))
                    .tracking(-0.8)
                    .foregroundStyle(.white)

                Text(L10n.t(
                    "Укажите, что важно именно вам. Консультант работает только по вашему запросу и использует данные конкретных автомобилей.",
                    "Siz uchun nima muhimligini belgilang. Maslahatchi faqat sizning so‘rovingiz bo‘yicha ishlaydi va aniq avtomobillar ma’lumotlaridan foydalanadi.",
                    settings.language
                ))
                .font(.system(size: 14.5))
                .foregroundStyle(.white.opacity(0.66))
                .lineSpacing(3)

                criteriaGrid
                advisorInputs

                if let aiError {
                    Text(aiError)
                        .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.orange)
                }

                if availability.available {
                    HStack(spacing: 10) {
                        advisorButton(.advice, title: L10n.t("Получить совет", "Maslahat olish", settings.language))
                        advisorButton(.deep, title: L10n.t("Сравнить подробнее", "Batafsil solishtirish", settings.language))
                    }
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "clock.badge.exclamationmark")
                        Text(L10n.t(
                            "Консультант временно недоступен из-за высокого спроса. Таблица сравнения продолжает работать.",
                            "Maslahatchi yuqori talab sababli vaqtincha ishlamayapti. Solishtirish jadvali ishlashda davom etadi.",
                            settings.language
                        ))
                            .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white.opacity(0.74))
                    .padding(14)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                if let quota {
                    Text(L10n.t("Совет: \(quota.adviceRemaining) · Подробно: \(quota.deepRemaining)", "Maslahat: \(quota.adviceRemaining) · Batafsil: \(quota.deepRemaining)", settings.language))
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }

                if let aiResult { resultCard(aiResult) }
            }
            .padding(22)
        }
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    }

    private var criteriaGrid: some View {
        let criteria = AdviceCriterion.allCases
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(criteria) { criterion in
                Button {
                    withAnimation(reduceMotion ? nil : .easeOut(duration: ASUDesign.microDuration)) {
                        if selectedCriteria.contains(criterion) { selectedCriteria.remove(criterion) }
                        else { selectedCriteria.insert(criterion) }
                    }
                } label: {
                    HStack(spacing: 5) {
                        if selectedCriteria.contains(criterion) { Image(systemName: "checkmark") }
                        Text(criterionLabel(criterion))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(selectedCriteria.contains(criterion) ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .modifier(CompareDarkSelectable(selected: selectedCriteria.contains(criterion)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var advisorInputs: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                TextField(L10n.t("Максимальный бюджет", "Maksimal budjet", settings.language), text: $budget)
                    .keyboardType(.numberPad)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .modifier(CompareDarkField(radius: 16))
                Picker("", selection: $currency) {
                    ForEach(ASUCurrency.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu)
                .tint(.white)
                .frame(width: 88, height: 48)
                .modifier(CompareDarkField(radius: 16))
            }

            TextField(L10n.t(
                "Что ещё важно? Например: семья, тихий салон, перепродажа…",
                "Yana nima muhim? Masalan: oila, sokin salon, qayta sotish…",
                settings.language
            ), text: $note, axis: .vertical)
                .lineLimit(3...6)
                .font(.system(size: 13.5, design: .rounded))
                .foregroundStyle(.white)
                .padding(14)
                .modifier(CompareDarkField(radius: 18))
        }
    }

    private func advisorButton(_ action: CompareAIAction, title: String) -> some View {
        Button {
            Task { await runAI(action) }
        } label: {
            HStack(spacing: 8) {
                if aiLoading == action { ProgressView().tint(.black).controlSize(.small) }
                else { Image(systemName: action == .advice ? "sparkles" : "magnifyingglass") }
                Text(title).lineLimit(2)
            }
            .font(.system(size: 12.5, weight: .bold, design: .rounded))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .modifier(CompareDarkProminentButton())
        }
        .buttonStyle(.plain)
        .disabled(aiLoading != nil)
    }

    private func resultCard(_ result: CompareAIResult) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.t("РЕКОМЕНДАЦИЯ", "TAVSIYA", settings.language))
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.52))
            Text(result.title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            TypewriterText(text: result.verdict)
                .font(.system(size: 15.5, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Text(result.summary)
                .font(.system(size: 13.5))
                .foregroundStyle(.white.opacity(0.7))
                .lineSpacing(3)

            if !result.reasons.isEmpty {
                resultList(L10n.t("Почему", "Nima uchun", settings.language), items: result.reasons, symbol: "checkmark.circle.fill")
            }
            if !result.cautions.isEmpty {
                resultList(L10n.t("Что учесть", "Nimani hisobga olish kerak", settings.language), items: result.cautions, symbol: "exclamationmark.circle.fill")
            }
            if !result.sources.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.t("Источники проверки", "Tekshiruv manbalari", settings.language))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                    ForEach(result.sources) { source in
                        Button {
                            if let url = URL(string: source.url) { openURL(url) }
                        } label: {
                            HStack {
                                Text(source.title).lineLimit(1)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(18)
        .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func resultList(_ title: String, items: [String], symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: symbol).font(.system(size: 12)).padding(.top, 2)
                    Text(item).font(.system(size: 12.5)).lineSpacing(2)
                }
                .foregroundStyle(.white.opacity(0.82))
            }
        }
    }

    private var pickerSheet: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ASUGlassSearchField(text: $pickerSearch, placeholder: L10n.t("Марка, модель или комплектация", "Marka, model yoki komplektatsiya", settings.language))
                        .padding(.horizontal, ASUDesign.pagePadding)

                    ForEach(pickerCars) { car in
                        Button {
                            store.toggleCompare(car)
                            if store.compareCars.count >= 3 { showPicker = false }
                        } label: {
                            HStack(spacing: 12) {
                                ASURemoteImage(url: car.primaryImageURL, contentMode: .fit)
                                    .frame(width: 96, height: 70)
                                    .background(ASUDesign.gallery)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(car.displayName)
                                        .font(.system(size: 15.5, weight: .bold, design: .rounded))
                                        .foregroundStyle(.primary)
                                    Text(Format.price(car, language: settings.language))
                                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: store.isCompared(car) ? "checkmark.circle.fill" : "plus.circle")
                                    .font(.system(size: 21, weight: .medium))
                                    .foregroundStyle(store.isCompared(car) ? ASUDesign.orange : .primary)
                            }
                            .padding(10)
                            .asuCard(radius: 22, shadow: false)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, ASUDesign.pagePadding)
                    }
                }
                .padding(.vertical, 12)
            }
            .navigationTitle(L10n.t("Выберите автомобиль", "Avtomobilni tanlang", settings.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(L10n.t("Готово", "Tayyor", settings.language)) { showPicker = false } } }
        }
        .presentationDetents([.large])
        .presentationCornerRadius(34)
    }

    private var pickerCars: [Car] {
        let query = pickerSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty { return store.cars }
        return store.cars.filter { car in
            [car.brand, car.model, car.trim ?? ""].joined(separator: " ").lowercased().contains(query)
        }
    }

    private func detail(for car: Car) -> CarDetail? { details[car.id] }

    private func loadDetails() async {
        for car in selectedCars where details[car.id] == nil {
            if let value = try? await store.detail(for: car) {
                details[car.id] = value
            }
        }
    }

    private func runAI(_ action: CompareAIAction) async {
        aiError = nil
        aiResult = nil
        guard selectedCars.count >= 2 else {
            aiError = L10n.t("Сначала выберите минимум два автомобиля.", "Avval kamida ikkita avtomobil tanlang.", settings.language)
            ASUHaptics.error()
            return
        }
        if action == .advice, selectedCriteria.isEmpty, note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            aiError = L10n.t("Для совета выберите хотя бы один критерий или напишите комментарий.", "Maslahat uchun kamida bitta mezon tanlang yoki izoh yozing.", settings.language)
            ASUHaptics.error()
            return
        }

        aiLoading = action
        defer { aiLoading = nil }
        do {
            let amount = Double(budget.replacingOccurrences(of: " ", with: ""))
            let output = try await api.compare(
                action: action,
                cars: selectedCars,
                criteria: AdviceCriterion.allCases.filter { selectedCriteria.contains($0) },
                note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                budget: amount,
                currency: currency,
                language: settings.language
            )
            quota = output.1
            withAnimation(reduceMotion ? nil : .easeInOut(duration: ASUDesign.navigationDuration)) { aiResult = output.0 }
            ASUHaptics.success()
        } catch {
            aiError = settings.language == .ru ? error.localizedDescription : "Maslahatchi vaqtincha mavjud emas. Qayta urinib ko‘ring."
            ASUHaptics.error()
        }
    }

    private func criterionLabel(_ criterion: AdviceCriterion) -> String {
        switch criterion {
        case .budget: return L10n.t("Бюджет", "Budjet", settings.language)
        case .status: return L10n.t("Статус", "Status", settings.language)
        case .comfort: return L10n.t("Комфорт", "Qulaylik", settings.language)
        case .performance: return L10n.t("Динамика", "Dinamika", settings.language)
        case .family: return L10n.t("Семья", "Oila", settings.language)
        case .economy: return L10n.t("Экономичность", "Tejamkorlik", settings.language)
        case .technology: return L10n.t("Технологии", "Texnologiyalar", settings.language)
        case .ownership: return L10n.t("Владение", "Ekspluatatsiya", settings.language)
        case .resale: return L10n.t("Перепродажа", "Qayta sotish", settings.language)
        }
    }
}

private struct CompareGlassCard: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        } else {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.white.opacity(0.2), lineWidth: 0.7))
        }
    }
}

private struct CompareGlassCircle: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: Circle())
        } else {
            content.background(.ultraThinMaterial, in: Circle())
        }
    }
}

private struct CompareDarkSelectable: ViewModifier {
    let selected: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if selected { content.glassEffect(.regular.tint(.white).interactive(), in: Capsule()) }
            else { content.glassEffect(.regular.interactive(), in: Capsule()) }
        } else {
            content.background(selected ? AnyShapeStyle(Color.white) : AnyShapeStyle(Color.white.opacity(0.09)), in: Capsule())
        }
    }
}

private struct CompareDarkField: ViewModifier {
    let radius: CGFloat

    @ViewBuilder
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: shape)
        } else {
            content.background(Color.white.opacity(0.09), in: shape)
        }
    }
}

private struct CompareDarkProminentButton: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.tint(.white).interactive(), in: shape)
        } else {
            content.background(.white, in: shape)
        }
    }
}

private struct TypewriterText: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let text: String
    @State private var visible = ""

    var body: some View {
        Text(visible)
            .task(id: text) {
                if reduceMotion {
                    visible = text
                    return
                }
                visible = ""
                for character in text {
                    if Task.isCancelled { return }
                    visible.append(character)
                    try? await Task.sleep(for: .milliseconds(14))
                }
            }
    }
}
