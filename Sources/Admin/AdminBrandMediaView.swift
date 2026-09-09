import SwiftUI
import PhotosUI
import UIKit

struct ASUAdminBrandMediaView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject var session: ASUAdminSessionStore

    @State private var brands: [String] = ASUHomeContent.brands.map(\.name)
    @State private var selectedBrand = ASUHomeContent.brands.first?.name ?? "Mercedes-Benz"
    @State private var covers: [ASUAdminBrandCover] = []
    @State private var maxCovers = 3
    @State private var isLoading = true
    @State private var isUploading = false
    @State private var deletingKey: String?
    @State private var errorMessage: String?
    @State private var selection: [PhotosPickerItem] = []
    @State private var pendingDelete: ASUAdminBrandCover?

    private let mediaAPI = ASUAdminMediaAPI()
    private let adminAPI = ASUAdminAPI()

    private var roleAllowed: Bool {
        session.user?.role == .admin || session.user?.role == .superAdmin
    }

    private var remaining: Int { max(0, maxCovers - covers.count) }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 22) {
                hero

                if !roleAllowed {
                    deniedState
                } else {
                    brandRail
                    coverHeader

                    if isLoading && covers.isEmpty {
                        loadingState
                    } else if let errorMessage, covers.isEmpty {
                        errorState(errorMessage)
                    } else {
                        coverGrid
                        uploadSection
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 36)
        }
        .scrollIndicators(.hidden)
        .background(ASUDesign.page)
        .navigationTitle(L10n.t("Марки", "Markalar", settings.language))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .refreshable { await loadCovers(for: selectedBrand, silent: true) }
        .task { await loadBrandsAndCovers() }
        .task(id: selectedBrand) {
            guard roleAllowed else { return }
            await loadCovers(for: selectedBrand, silent: !covers.isEmpty)
        }
        .onChange(of: selection) { _, items in
            guard !items.isEmpty else { return }
            Task { await importAndUpload(items) }
        }
        .confirmationDialog(
            L10n.t("Удалить обложку?", "Muqova o‘chirilsinmi?", settings.language),
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(L10n.t("Удалить", "O‘chirish", settings.language), role: .destructive) {
                guard let pendingDelete else { return }
                Task { await deleteCover(pendingDelete) }
                self.pendingDelete = nil
            }
            Button(L10n.t("Отмена", "Bekor qilish", settings.language), role: .cancel) {
                pendingDelete = nil
            }
        } message: {
            Text(L10n.t(
                "Обложка будет удалена из R2 и исчезнет со всех автомобилей этой марки.",
                "Muqova R2 dan o‘chiriladi va ushbu markadagi barcha avtomobillardan yo‘qoladi.",
                settings.language
            ))
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.black, Color(red: 0.055, green: 0.055, blue: 0.065)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(Color.white.opacity(0.09))
                .frame(width: 210, height: 210)
                .blur(radius: 45)
                .offset(x: 175, y: -110)

            VStack(alignment: .leading, spacing: 17) {
                HStack {
                    Text("CONTROL SYSTEM · BRAND MEDIA")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .tracking(1.15)
                        .foregroundStyle(.white.opacity(0.56))
                    Spacer()
                    HStack(spacing: 6) {
                        Circle().fill(ASUDesign.success).frame(width: 7, height: 7)
                        Text("R2 LIVE")
                    }
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.62))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.t("Обложки марок", "Marka muqovalari", settings.language))
                        .font(.system(size: 37, weight: .bold, design: .rounded))
                        .tracking(-1.2)
                        .foregroundStyle(.white)
                    Text(L10n.t(
                        "До трёх атмосферных изображений на марку. Они автоматически становятся верхней визуальной сценой всех автомобилей выбранного бренда.",
                        "Har bir marka uchun uchtagacha atmosfera tasviri. Ular tanlangan brenddagi barcha avtomobillarning yuqori vizual sahnasiga avtomatik aylanadi.",
                        settings.language
                    ))
                    .font(.system(size: 14.5))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineSpacing(4)
                }

                HStack(spacing: 10) {
                    heroMetric("\(covers.count)", L10n.t("обложки", "muqova", settings.language))
                    heroMetric("\(maxCovers)", L10n.t("максимум", "maksimum", settings.language))
                    heroMetric("\(brands.count)", L10n.t("марок", "marka", settings.language))
                }
            }
            .padding(21)
        }
        .frame(minHeight: 275)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 0.7))
    }

    private func heroMetric(_ value: String, _ title: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
            Text(title)
                .font(.system(size: 9.5, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.50))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .padding(.horizontal, 12)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var brandRail: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.t("ВЫБЕРИТЕ МАРКУ", "MARKANI TANLANG", settings.language))
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(brands, id: \.self) { brand in
                        Button {
                            withAnimation(reduceMotion ? nil : ASUDesign.spring) {
                                selectedBrand = brand
                            }
                        } label: {
                            VStack(spacing: 9) {
                                brandLogo(brand)
                                    .frame(width: 78, height: 48)
                                Text(brand)
                                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .foregroundStyle(.primary)
                            .frame(width: 126, height: 104)
                            .background(
                                selectedBrand == brand ? Color.primary.opacity(0.08) : ASUDesign.elevated,
                                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(selectedBrand == brand ? Color.primary.opacity(0.72) : ASUDesign.line, lineWidth: selectedBrand == brand ? 1.4 : 0.7)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var coverHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedBrand)
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .tracking(-0.65)
                Text(L10n.t("Обложки верхней сцены", "Yuqori sahna muqovalari", settings.language))
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(covers.count) / \(maxCovers)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(ASUDesign.soft, in: Capsule())
        }
    }

    @ViewBuilder
    private var coverGrid: some View {
        if covers.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "photo.stack")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(.secondary)
                Text(L10n.t("Обложки ещё не добавлены", "Muqovalar hali qo‘shilmagan", settings.language))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text(L10n.t(
                    "Пока приложение использует стандартную сцену марки.",
                    "Hozircha ilova markaning standart sahnasidan foydalanadi.",
                    settings.language
                ))
                .font(.system(size: 13.5))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 190)
            .padding(20)
            .asuCard(radius: 28)
        } else {
            VStack(spacing: 12) {
                ForEach(Array(covers.enumerated()), id: \.element.key) { index, cover in
                    ZStack(alignment: .topTrailing) {
                        ASURemoteImage(url: cover.resolvedURL, contentMode: .fill, background: ASUDesign.gallery)
                            .frame(maxWidth: .infinity)
                            .frame(height: 210)
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))

                        LinearGradient(
                            colors: [.clear, .black.opacity(0.58)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .allowsHitTesting(false)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(String(format: "%02d", index + 1)) · \(selectedBrand.uppercased())")
                                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                .tracking(1)
                            Text(ASUAdminMediaFormatting.fileSize(cover.size))
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        .padding(17)
                        .allowsHitTesting(false)

                        Button {
                            pendingDelete = cover
                        } label: {
                            Group {
                                if deletingKey == cover.key {
                                    ProgressView().controlSize(.small).tint(.white)
                                } else {
                                    Image(systemName: "trash")
                                        .font(.system(size: 12, weight: .bold))
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(.black.opacity(0.52), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .disabled(deletingKey != nil || isUploading)
                        .padding(12)
                    }
                }
            }
        }
    }

    private var uploadSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.t("Добавить атмосферную обложку", "Atmosfera muqovasini qo‘shish", settings.language))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text(L10n.t("JPG / PNG / WebP / AVIF · до 20 МБ · максимум 3", "JPG / PNG / WebP / AVIF · 20 MB gacha · maksimum 3", settings.language))
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isUploading { ProgressView().controlSize(.small) }
            }

            PhotosPicker(
                selection: $selection,
                maxSelectionCount: max(1, remaining),
                matching: .images
            ) {
                HStack(spacing: 9) {
                    Image(systemName: remaining > 0 ? "photo.badge.plus" : "checkmark.circle.fill")
                    Text(remaining > 0
                         ? L10n.t("Выбрать изображения", "Tasvirlarni tanlash", settings.language)
                         : L10n.t("Лимит заполнен", "Limit to‘ldi", settings.language))
                    Spacer()
                    Text("\(remaining)")
                        .foregroundStyle(.secondary)
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .padding(.horizontal, 15)
                .frame(height: 52)
                .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 19, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))
            }
            .buttonStyle(.plain)
            .disabled(remaining == 0 || isUploading)
            .opacity(remaining == 0 ? 0.52 : 1)

            if let errorMessage, !covers.isEmpty {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.red)
            }
        }
        .padding(18)
        .asuCard(radius: 28)
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView().controlSize(.large)
            Text(L10n.t("Загружаем обложки…", "Muqovalar yuklanmoqda…", settings.language))
                .font(.system(size: 13.5, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 210)
    }

    private func errorState(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(L10n.t("Не удалось загрузить обложки", "Muqovalarni yuklab bo‘lmadi", settings.language), systemImage: "exclamationmark.triangle")
                .font(.system(size: 17, weight: .bold, design: .rounded))
            Text(message)
                .font(.system(size: 13.5))
                .foregroundStyle(.secondary)
            Button(L10n.t("Повторить", "Qayta urinish", settings.language)) {
                Task { await loadCovers(for: selectedBrand, silent: false) }
            }
            .buttonStyle(ASUPrimaryButtonStyle(prominent: false))
        }
        .padding(18)
        .asuCard(radius: 28)
    }

    private var deniedState: some View {
        VStack(spacing: 13) {
            Image(systemName: "lock.shield")
                .font(.system(size: 36, weight: .light))
            Text(L10n.t("Нет доступа к Brand Media", "Brand Media uchun ruxsat yo‘q", settings.language))
                .font(.system(size: 20, weight: .bold, design: .rounded))
            Text(L10n.t("Управление обложками доступно администраторам.", "Muqovalarni boshqarish administratorlar uchun mavjud.", settings.language))
                .font(.system(size: 13.5))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 230)
        .padding(18)
        .asuCard(radius: 28)
    }

    @ViewBuilder
    private func brandLogo(_ brand: String) -> some View {
        if let item = ASUHomeContent.brands.first(where: { $0.name.caseInsensitiveCompare(brand) == .orderedSame }) {
            Image(item.assetName)
                .resizable()
                .scaledToFit()
                .grayscale(1)
        } else {
            Text(String(brand.prefix(2)).uppercased())
                .font(.system(size: 17, weight: .black, design: .rounded))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @MainActor
    private func loadBrandsAndCovers() async {
        guard roleAllowed, let token = session.bearerToken else { return }
        do {
            let snapshot = try await adminAPI.cars(query: "", brand: nil, status: .all, country: .all, token: token)
            let known = ASUHomeContent.brands.map(\.name)
            let merged = Set(known + snapshot.brands.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
            brands = merged.sorted { left, right in
                if let li = known.firstIndex(of: left), let ri = known.firstIndex(of: right) { return li < ri }
                if known.contains(left) { return true }
                if known.contains(right) { return false }
                return left.localizedCaseInsensitiveCompare(right) == .orderedAscending
            }
            if !brands.contains(selectedBrand), let first = brands.first { selectedBrand = first }
        } catch let error as ASUAdminAPI.APIError {
            handle(error)
        } catch {
            // Covers remain usable with the known brand list if the catalog request is temporarily unavailable.
        }
        await loadCovers(for: selectedBrand, silent: false)
    }

    @MainActor
    private func loadCovers(for brand: String, silent: Bool) async {
        guard roleAllowed, let token = session.bearerToken else { return }
        if !silent { isLoading = true }
        errorMessage = nil
        defer { isLoading = false }

        do {
            let snapshot = try await mediaAPI.brandCovers(brand: brand, token: token)
            guard selectedBrand == brand else { return }
            maxCovers = snapshot.maxCovers
            covers = snapshot.images
        } catch let error as ASUAdminAPI.APIError {
            handle(error)
        } catch {
            errorMessage = L10n.t("Не удалось загрузить обложки марки.", "Marka muqovalarini yuklab bo‘lmadi.", settings.language)
        }
    }

    @MainActor
    private func importAndUpload(_ items: [PhotosPickerItem]) async {
        guard remaining > 0, !isUploading, let token = session.bearerToken else {
            selection = []
            return
        }
        isUploading = true
        errorMessage = nil
        defer {
            isUploading = false
            selection = []
        }

        let limit = remaining
        for item in items.prefix(limit) {
            do {
                guard let rawData = try await item.loadTransferable(type: Data.self),
                      let data = Self.optimizedJPEG(rawData) else {
                    errorMessage = L10n.t("Одно из изображений не удалось подготовить.", "Tasvirlardan birini tayyorlab bo‘lmadi.", settings.language)
                    continue
                }
                let uploaded = try await mediaAPI.uploadBrandCover(
                    brand: selectedBrand,
                    data: data,
                    filename: "brand-cover-\(UUID().uuidString).jpg",
                    token: token
                )
                covers.append(uploaded)
                if covers.count >= maxCovers { break }
            } catch let error as ASUAdminAPI.APIError {
                handle(error)
                if error.shouldDiscardSession { break }
            } catch {
                errorMessage = L10n.t("Не удалось загрузить изображение.", "Tasvirni yuklab bo‘lmadi.", settings.language)
            }
        }
    }

    @MainActor
    private func deleteCover(_ cover: ASUAdminBrandCover) async {
        guard deletingKey == nil, let token = session.bearerToken else { return }
        deletingKey = cover.key
        errorMessage = nil
        defer { deletingKey = nil }

        do {
            try await mediaAPI.deleteBrandCover(key: cover.key, token: token)
            withAnimation(reduceMotion ? nil : ASUDesign.spring) {
                covers.removeAll { $0.key == cover.key }
            }
        } catch let error as ASUAdminAPI.APIError {
            handle(error)
        } catch {
            errorMessage = L10n.t("Не удалось удалить обложку.", "Muqovani o‘chirib bo‘lmadi.", settings.language)
        }
    }

    @MainActor
    private func handle(_ error: ASUAdminAPI.APIError) {
        if error.shouldDiscardSession {
            session.invalidateSession(notice: error.localizedDescription)
        } else {
            errorMessage = error.localizedDescription
        }
    }

    private static func optimizedJPEG(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let maxDimension: CGFloat = 2600
        let longest = max(image.size.width, image.size.height)
        let output: UIImage

        if longest > maxDimension, longest > 0 {
            let scale = maxDimension / longest
            let target = CGSize(width: max(1, image.size.width * scale), height: max(1, image.size.height * scale))
            let format = UIGraphicsImageRendererFormat.default()
            format.scale = 1
            format.opaque = true
            output = UIGraphicsImageRenderer(size: target, format: format).image { context in
                context.cgContext.setFillColor(UIColor.black.cgColor)
                context.cgContext.fill(CGRect(origin: .zero, size: target))
                image.draw(in: CGRect(origin: .zero, size: target))
            }
        } else {
            output = image
        }

        var quality: CGFloat = 0.88
        guard var jpeg = output.jpegData(compressionQuality: quality) else { return nil }
        while jpeg.count > 18 * 1024 * 1024 && quality > 0.48 {
            quality -= 0.10
            guard let next = output.jpegData(compressionQuality: quality) else { break }
            jpeg = next
        }
        return jpeg.count <= 20 * 1024 * 1024 ? jpeg : nil
    }
}
