import SwiftUI
import UIKit

struct ASUAdminRamadanGiftView: View {
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject var session: ASUAdminSessionStore

    @State private var gift: RamadanGift?
    @State private var draft: ASUAdminRamadanGiftDraft?
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var uploadingGroup: ASUAdminRamadanPhotoGroup?
    @State private var deletingMediaID: Int?
    @State private var errorMessage: String?
    @State private var savedNotice = false

    private let api = ASUAdminRamadanAPI()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                hero

                if let errorMessage {
                    errorCard(errorMessage)
                }

                if isLoading && draft == nil {
                    loadingState
                } else if draft != nil {
                    previewCard
                    contentSection
                    vehicleSection
                    photosSection
                    systemMeta
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(ASUDesign.page)
        .navigationTitle("Ramadan Gift")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Link(destination: AppConfig.website.appending(path: "ramadan-gift/")) {
                    Image(systemName: "arrow.up.right.square")
                }
                .accessibilityLabel(L10n.t("Открыть публичную страницу", "Ommaviy sahifani ochish", settings.language))
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if draft != nil {
                saveBar
            }
        }
        .refreshable { await load(silent: true) }
        .task { await load() }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color.black, Color(red: 0.09, green: 0.075, blue: 0.045)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Circle()
                .fill(Color(red: 0.86, green: 0.65, blue: 0.28).opacity(0.24))
                .frame(width: 220, height: 220)
                .blur(radius: 48)
                .offset(x: 165, y: -115)

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("AUTO SALE UMAR / CLIENT GRATITUDE")
                        .font(.system(size: 9.2, weight: .bold, design: .rounded))
                        .tracking(1.05)
                    Spacer()
                    Image(systemName: "gift.fill")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.white.opacity(0.62))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Ramadan Gift")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .tracking(-1.25)
                        .foregroundStyle(.white)
                    Text(L10n.t(
                        "Карточка на главной, отдельная публичная страница, условия программы и галерея подарочного автомобиля.",
                        "Bosh sahifa kartochkasi, ommaviy sahifa, dastur shartlari va sovg‘a avtomobil galereyasi.",
                        settings.language
                    ))
                    .font(.system(size: 13.5))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineSpacing(3)
                }

                if let draft {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(draft.isActive ? ASUDesign.success : .secondary)
                            .frame(width: 7, height: 7)
                        Text(draft.isActive
                             ? L10n.t("ПУБЛИЧНЫЙ БЛОК АКТИВЕН", "OMMAVIY BLOK FAOL", settings.language)
                             : L10n.t("БЛОК СКРЫТ", "BLOK YASHIRILGAN", settings.language))
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                            .tracking(0.8)
                    }
                    .foregroundStyle(.white.opacity(0.74))
                }
            }
            .padding(21)
        }
        .frame(minHeight: 270)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 0.7))
    }

    private var previewCard: some View {
        let current = draft
        let cover = gift?.coverMedia
        return VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                if let cover {
                    ASURemoteImage(
                        url: ASUAdminRamadanMediaURL.resolve(cover.publicUrl),
                        contentMode: .fill,
                        background: ASUDesign.gallery
                    )
                } else {
                    ASUDesign.gallery
                        .overlay {
                            Image(systemName: "gift")
                                .font(.system(size: 42, weight: .light))
                                .foregroundStyle(.secondary)
                        }
                }

                LinearGradient(
                    colors: [.clear, .black.opacity(0.78)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 7) {
                    Text(L10n.t("ЕЖЕГОДНАЯ ПРОГРАММА БЛАГОДАРНОСТИ", "YILLIK MINNATDORCHILIK DASTURI", settings.language))
                        .font(.system(size: 8.5, weight: .bold, design: .rounded))
                        .tracking(0.9)
                        .foregroundStyle(.white.opacity(0.66))
                    Text(localized(current?.titleRu ?? "", current?.titleUz ?? ""))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))
                    Text(localized(current?.subtitleRu ?? "", current?.subtitleUz ?? ""))
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                        .tracking(-0.6)
                        .foregroundStyle(.white)
                    Text(localized(current?.shortPhraseRu ?? "", current?.shortPhraseUz ?? ""))
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.70))
                        .lineLimit(2)
                }
                .padding(17)
            }
            .frame(height: 245)
            .clipped()

            HStack(spacing: 0) {
                previewMetric(
                    title: L10n.t("Рыночная цена", "Bozor narxi", settings.language),
                    value: money(current?.marketPrice ?? "", currency: current?.currency ?? .USD)
                )
                Divider().frame(height: 44)
                previewMetric(
                    title: L10n.t("От суммы покупки", "Xarid summasi", settings.language),
                    value: money(current?.minPurchaseAmount ?? "", currency: current?.currency ?? .USD)
                )
            }
            .padding(.vertical, 8)
        }
        .background(ASUDesign.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))
    }

    private func previewMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                .tracking(0.65)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .frame(height: 66)
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeading(
                kicker: L10n.t("КОНТЕНТ", "KONTENT", settings.language),
                title: L10n.t("Тексты на двух языках", "Ikki tildagi matnlar", settings.language),
                subtitle: L10n.t("Эти поля используются одновременно на главной и на странице Ramadan Gift.", "Bu maydonlar bosh sahifa va Ramadan Gift sahifasida ishlatiladi.", settings.language)
            )

            toggleRow
            field(L10n.t("Заголовок · RU", "Sarlavha · RU", settings.language), text: draftBinding(\.titleRu, fallback: ""))
            field(L10n.t("Заголовок · UZ", "Sarlavha · UZ", settings.language), text: draftBinding(\.titleUz, fallback: ""))
            field(L10n.t("Подзаголовок / автомобиль · RU", "Avtomobil nomi · RU", settings.language), text: draftBinding(\.subtitleRu, fallback: ""))
            field(L10n.t("Подзаголовок / автомобиль · UZ", "Avtomobil nomi · UZ", settings.language), text: draftBinding(\.subtitleUz, fallback: ""))
            field(L10n.t("Короткая фраза · RU", "Qisqa ibora · RU", settings.language), text: draftBinding(\.shortPhraseRu, fallback: ""))
            field(L10n.t("Короткая фраза · UZ", "Qisqa ibora · UZ", settings.language), text: draftBinding(\.shortPhraseUz, fallback: ""))
            editor(L10n.t("Подробное описание · RU", "Batafsil tavsif · RU", settings.language), text: draftBinding(\.descriptionRu, fallback: ""))
            editor(L10n.t("Подробное описание · UZ", "Batafsil tavsif · UZ", settings.language), text: draftBinding(\.descriptionUz, fallback: ""))
        }
        .padding(17)
        .asuCard(radius: 28)
    }

    private var vehicleSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeading(
                kicker: L10n.t("УСЛОВИЯ ПРОГРАММЫ", "DASTUR SHARTLARI", settings.language),
                title: L10n.t("Автомобиль и экономика", "Avtomobil va iqtisod", settings.language),
                subtitle: L10n.t("Параметры подарочного автомобиля и порог участия клиента.", "Sovg‘a avtomobil parametrlari va mijoz ishtiroki chegarasi.", settings.language)
            )

            HStack(spacing: 10) {
                field(L10n.t("Марка", "Marka", settings.language), text: draftBinding(\.brand, fallback: ""))
                field(L10n.t("Модель", "Model", settings.language), text: draftBinding(\.model, fallback: ""))
            }
            HStack(spacing: 10) {
                field(L10n.t("Год", "Yil", settings.language), text: draftBinding(\.year, fallback: ""), keyboard: .numberPad)
                field(L10n.t("Комплектация", "Komplektatsiya", settings.language), text: draftBinding(\.trim, fallback: ""))
            }
            HStack(spacing: 10) {
                field(L10n.t("Цвет кузова", "Kuzov rangi", settings.language), text: draftBinding(\.exteriorColor, fallback: ""))
                field(L10n.t("Цвет салона", "Salon rangi", settings.language), text: draftBinding(\.interiorColor, fallback: ""))
            }
            HStack(spacing: 10) {
                field(L10n.t("Минимальная сумма", "Minimal summa", settings.language), text: draftBinding(\.minPurchaseAmount, fallback: ""), keyboard: .numberPad)
                field(L10n.t("Рыночная цена", "Bozor narxi", settings.language), text: draftBinding(\.marketPrice, fallback: ""), keyboard: .numberPad)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(L10n.t("ВАЛЮТА", "VALYUTA", settings.language))
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .tracking(0.65)
                    .foregroundStyle(.secondary)
                Picker("Currency", selection: draftBinding(\.currency, fallback: .USD)) {
                    ForEach(ASUCurrency.allCases) { currency in
                        Text(currency.rawValue).tag(currency)
                    }
                }
                .pickerStyle(.segmented)
            }

            field("Instagram", text: draftBinding(\.instagramUrl, fallback: ""), keyboard: .URL)
            field(L10n.t("Ссылка кнопки «Заказать автомобиль»", "“Avtomobil buyurtma qilish” havolasi", settings.language), text: draftBinding(\.orderHref, fallback: "/compare/"), keyboard: .URL)
        }
        .padding(17)
        .asuCard(radius: 28)
    }

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionHeading(
                kicker: "R2 MEDIA",
                title: L10n.t("Фотографии подарка", "Sovg‘a fotosuratlari", settings.language),
                subtitle: L10n.t("Фото оптимизируются на iPhone перед загрузкой и сохраняются в существующий R2 MEDIA.", "Suratlar iPhone’da optimallashtirilib mavjud R2 MEDIA ga yuklanadi.", settings.language)
            )

            ASUAdminRamadanPhotoSection(
                group: .exterior,
                media: gift?.media ?? [],
                canUpload: gift?.id != nil,
                isUploading: uploadingGroup == .exterior,
                deletingID: deletingMediaID,
                upload: { photos in Task { await upload(photos, group: .exterior) } },
                delete: { media in Task { await delete(media) } }
            )

            Divider()

            ASUAdminRamadanPhotoSection(
                group: .interior,
                media: gift?.media ?? [],
                canUpload: gift?.id != nil,
                isUploading: uploadingGroup == .interior,
                deletingID: deletingMediaID,
                upload: { photos in Task { await upload(photos, group: .interior) } },
                delete: { media in Task { await delete(media) } }
            )
        }
        .padding(17)
        .asuCard(radius: 28)
    }

    private var systemMeta: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CONTROL SYSTEM / PARITY")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(0.9)
                        .foregroundStyle(.secondary)
                    Text(L10n.t("Ramadan Gift подключён к production D1 + R2", "Ramadan Gift production D1 + R2 ga ulangan", settings.language))
                        .font(.system(size: 13.5, weight: .bold, design: .rounded))
                }
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(ASUDesign.success)
            }

            if let gift {
                if let updated = cleanOptional(gift.updatedAt) {
                    Text("\(L10n.t("Обновлено", "Yangilandi", settings.language)): \(updated)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                if let author = cleanOptional(gift.updatedByName) {
                    Text("\(L10n.t("Сотрудник", "Xodim", settings.language)): \(author)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .asuCard(radius: 24)
    }

    private var toggleRow: some View {
        Toggle(isOn: draftBinding(\.isActive, fallback: true)) {
            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.t("Показывать публичный блок", "Ommaviy blokni ko‘rsatish", settings.language))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Text(L10n.t("Управляет видимостью Ramadan Gift для клиентов.", "Ramadan Gift mijozlarga ko‘rinishini boshqaradi.", settings.language))
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .tint(ASUDesign.success)
        .padding(13)
        .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var saveBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(savedNotice ? L10n.t("Сохранено", "Saqlandi", settings.language) : L10n.t("Ramadan Gift", "Ramadan Gift", settings.language))
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    Text(L10n.t("D1 + R2 production", "D1 + R2 production", settings.language))
                        .font(.system(size: 9.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    Task { await save() }
                } label: {
                    HStack(spacing: 8) {
                        if isSaving {
                            ProgressView().controlSize(.small).tint(.white)
                        } else {
                            Image(systemName: savedNotice ? "checkmark" : "square.and.arrow.down")
                        }
                        Text(isSaving
                             ? L10n.t("Сохраняем…", "Saqlanmoqda…", settings.language)
                             : L10n.t("Сохранить", "Saqlash", settings.language))
                    }
                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 17)
                    .frame(height: 46)
                    .background(Color.black, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isSaving || uploadingGroup != nil || deletingMediaID != nil)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(ASUDesign.page)
        }
    }

    private func sectionHeading(kicker: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(kicker)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.9)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.system(size: 19, weight: .bold, design: .rounded))
            Text(subtitle)
                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineSpacing(2)
        }
    }

    private func field(
        _ title: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title.uppercased())
                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                .tracking(0.6)
                .foregroundStyle(.secondary)
            TextField(title, text: text)
                .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                .textInputAutocapitalization(keyboard == .URL ? .never : .sentences)
                .autocorrectionDisabled(keyboard == .URL)
                .keyboardType(keyboard)
                .padding(.horizontal, 12)
                .frame(height: 46)
                .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func editor(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title.uppercased())
                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                .tracking(0.6)
                .foregroundStyle(.secondary)
            TextEditor(text: text)
                .font(.system(size: 13.5, weight: .medium, design: .rounded))
                .scrollContentBackground(.hidden)
                .padding(9)
                .frame(minHeight: 130)
                .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))
        }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(L10n.t("Загружаем Ramadan Gift…", "Ramadan Gift yuklanmoqda…", settings.language))
                .font(.system(size: 13.5, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 190)
        .asuCard(radius: 28)
    }

    private func errorCard(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(ASUDesign.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.t("Ramadan Gift требует внимания", "Ramadan Gift e’tibor talab qiladi", settings.language))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Text(message)
                    .font(.system(size: 12.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(15)
        .asuCard(radius: 22)
    }

    private func draftBinding<T>(_ keyPath: WritableKeyPath<ASUAdminRamadanGiftDraft, T>, fallback: T) -> Binding<T> {
        Binding(
            get: { draft?[keyPath: keyPath] ?? fallback },
            set: { newValue in
                guard var current = draft else { return }
                current[keyPath: keyPath] = newValue
                draft = current
                savedNotice = false
            }
        )
    }

    private func localized(_ ru: String, _ uz: String) -> String {
        settings.language == .ru ? ru : uz
    }

    private func money(_ raw: String, currency: ASUCurrency) -> String {
        let clean = raw.replacingOccurrences(of: " ", with: "")
        guard let value = Int64(clean), value > 0 else { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = " "
        let number = formatter.string(from: NSNumber(value: value)) ?? String(value)
        switch currency {
        case .USD: return "\(number) $"
        case .EUR: return "\(number) €"
        case .UZS: return "\(number) \(L10n.t("сум", "so‘m", settings.language))"
        }
    }

    private func cleanOptional(_ value: String?) -> String? {
        guard let value else { return nil }
        let clean = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? nil : clean
    }

    @MainActor
    private func load(silent: Bool = false) async {
        guard let token = session.bearerToken else {
            session.invalidateSession()
            return
        }
        if !silent { isLoading = true }
        errorMessage = nil
        defer { isLoading = false }

        do {
            let loaded = try await api.loadGift(token: token)
            gift = loaded
            draft = ASUAdminRamadanGiftDraft(gift: loaded)
            savedNotice = false
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

    @MainActor
    private func save() async {
        guard !isSaving, let draft else { return }
        guard let token = session.bearerToken else {
            session.invalidateSession()
            return
        }
        isSaving = true
        errorMessage = nil
        savedNotice = false
        defer { isSaving = false }

        do {
            let saved = try await api.saveGift(draft: draft, token: token)
            gift = saved
            self.draft = ASUAdminRamadanGiftDraft(gift: saved)
            savedNotice = true
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

    @MainActor
    private func upload(_ photos: [ASUAdminPendingPhoto], group: ASUAdminRamadanPhotoGroup) async {
        guard uploadingGroup == nil, !photos.isEmpty else { return }
        guard let token = session.bearerToken else {
            session.invalidateSession()
            return
        }
        guard let giftID = gift?.id else {
            errorMessage = L10n.t("Сначала сохраните Ramadan Gift.", "Avval Ramadan Gift’ni saqlang.", settings.language)
            return
        }

        uploadingGroup = group
        errorMessage = nil
        defer { uploadingGroup = nil }

        let managed = (gift?.media ?? []).filter { ASUAdminRamadanMediaURL.isManaged($0) }
        let maxSort = managed.map(\.sortOrder).max() ?? -1
        var firstError: Error?

        for (index, photo) in photos.enumerated() {
            do {
                try await api.uploadMedia(
                    giftID: giftID,
                    group: group,
                    photo: photo,
                    sortOrder: maxSort + index + 1,
                    isCover: managed.isEmpty && index == 0,
                    token: token
                )
            } catch {
                firstError = error
                break
            }
        }

        do {
            let refreshed = try await api.loadGift(token: token)
            gift = refreshed
        } catch {
            if firstError == nil { firstError = error }
        }

        if let error = firstError as? ASUAdminAPI.APIError {
            if error.shouldDiscardSession {
                session.invalidateSession(notice: error.localizedDescription)
            } else {
                errorMessage = error.localizedDescription
            }
        } else if let firstError {
            errorMessage = firstError.localizedDescription
        }
    }

    @MainActor
    private func delete(_ media: RamadanGiftMedia) async {
        guard ASUAdminRamadanMediaURL.isManaged(media), deletingMediaID == nil else { return }
        guard let token = session.bearerToken else {
            session.invalidateSession()
            return
        }
        deletingMediaID = media.id
        errorMessage = nil
        defer { deletingMediaID = nil }

        do {
            try await api.deleteMedia(id: media.id, token: token)
            let refreshed = try await api.loadGift(token: token)
            gift = refreshed
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
}
