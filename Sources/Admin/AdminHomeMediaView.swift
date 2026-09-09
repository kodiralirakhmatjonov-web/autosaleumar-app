import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

struct ASUAdminHomeMediaView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject var session: ASUAdminSessionStore

    @State private var videos: [ASUAdminHomeVideo] = []
    @State private var brands: [String] = ASUHomeContent.brands.map(\.name)
    @State private var isLoading = true
    @State private var isUploading = false
    @State private var savingKey: String?
    @State private var savedKey: String?
    @State private var deletingKey: String?
    @State private var pendingDelete: ASUAdminHomeVideo?
    @State private var errorMessage: String?
    @State private var showImporter = false
    @State private var heroMuted = true

    private let mediaAPI = ASUAdminMediaAPI()
    private let adminAPI = ASUAdminAPI()

    private var roleAllowed: Bool {
        session.user?.role == .admin || session.user?.role == .superAdmin
    }

    private var introURL: URL? {
        Bundle.main.url(forResource: "intro", withExtension: "mp4")
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 22) {
                hero

                if !roleAllowed {
                    deniedState
                } else {
                    systemVideoCard
                    libraryHeader

                    if isLoading && videos.isEmpty {
                        loadingState
                    } else if let errorMessage, videos.isEmpty {
                        errorState(errorMessage)
                    } else if videos.isEmpty {
                        emptyState
                    } else {
                        videoLibrary
                    }

                    if let errorMessage, !videos.isEmpty {
                        inlineError(errorMessage)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 38)
        }
        .scrollIndicators(.hidden)
        .background(ASUDesign.page)
        .navigationTitle(L10n.t("Главная", "Bosh sahifa", settings.language))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showImporter = true
                } label: {
                    if isUploading {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "plus")
                    }
                }
                .disabled(!roleAllowed || isUploading)
                .accessibilityLabel(L10n.t("Добавить видео", "Video qo‘shish", settings.language))
            }
        }
        .refreshable { await loadAll(silent: true) }
        .task { await loadAll(silent: false) }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.movie, .mpeg4Movie, .quickTimeMovie],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                Task { await uploadVideo(url) }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
        .confirmationDialog(
            L10n.t("Удалить видео с главной?", "Videoni bosh sahifadan o‘chirasizmi?", settings.language),
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(L10n.t("Удалить", "O‘chirish", settings.language), role: .destructive) {
                guard let video = pendingDelete else { return }
                Task { await deleteVideo(video) }
                pendingDelete = nil
            }
            Button(L10n.t("Отмена", "Bekor qilish", settings.language), role: .cancel) {
                pendingDelete = nil
            }
        } message: {
            Text(L10n.t(
                "Видео будет удалено из R2 и исчезнет из публичной карусели Auto Sale Umar.",
                "Video R2 dan o‘chiriladi va Auto Sale Umar ommaviy karuselidan yo‘qoladi.",
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
                .fill(ASUDesign.orange.opacity(0.20))
                .frame(width: 220, height: 220)
                .blur(radius: 44)
                .offset(x: 175, y: -115)

            VStack(alignment: .leading, spacing: 17) {
                HStack {
                    Text("CONTROL SYSTEM · HOME MEDIA")
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
                    Text(L10n.t("Главная страница", "Bosh sahifa", settings.language))
                        .font(.system(size: 37, weight: .bold, design: .rounded))
                        .tracking(-1.2)
                        .foregroundStyle(.white)
                    Text(L10n.t(
                        "Управляйте рекламной видео-каруселью, подписью, ценой и статусом каждого ролика прямо с iPhone.",
                        "Reklama video karuseli, yozuv, narx va har bir rolik statusini bevosita iPhone’dan boshqaring.",
                        settings.language
                    ))
                    .font(.system(size: 14.5))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineSpacing(4)
                }

                HStack(spacing: 10) {
                    heroMetric("1", L10n.t("системное", "tizim", settings.language))
                    heroMetric("\(videos.count)", L10n.t("добавлено", "qo‘shilgan", settings.language))
                    heroMetric("80 MB", L10n.t("на видео", "har video", settings.language))
                }

                Button {
                    showImporter = true
                } label: {
                    HStack(spacing: 9) {
                        if isUploading {
                            ProgressView().controlSize(.small).tint(.black)
                        } else {
                            Image(systemName: "plus.circle.fill")
                        }
                        Text(isUploading
                             ? L10n.t("Загружаем видео…", "Video yuklanmoqda…", settings.language)
                             : L10n.t("Добавить видео", "Video qo‘shish", settings.language))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(.white, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isUploading)
            }
            .padding(21)
        }
        .frame(minHeight: 315)
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
                .minimumScaleFactor(0.72)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .padding(.horizontal, 12)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var systemVideoCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                if let introURL {
                    ASUVideoSurface(
                        url: introURL,
                        isMuted: heroMuted,
                        shouldPlay: true,
                        loops: true,
                        gravity: .resizeAspectFill
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 210)
                    .clipped()
                } else {
                    ASUDesign.gallery
                        .frame(height: 210)
                        .overlay(Image(systemName: "play.rectangle").font(.system(size: 42, weight: .light)).foregroundStyle(.secondary))
                }

                LinearGradient(
                    colors: [.clear, .black.opacity(0.60)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                HStack(spacing: 7) {
                    Image(systemName: "lock.fill")
                    Text(L10n.t("СИСТЕМНОЕ ВИДЕО", "TIZIM VIDEOSI", settings.language))
                }
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .frame(height: 30)
                .background(.black.opacity(0.48), in: Capsule())
                .padding(13)

                Button {
                    heroMuted.toggle()
                } label: {
                    Image(systemName: heroMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(.black.opacity(0.48), in: Circle())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(13)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("INTRO · 01")
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .tracking(1.05)
                    .foregroundStyle(.secondary)
                Text(L10n.t("Первый слайд всегда защищён.", "Birinchi slayd doimo himoyalangan.", settings.language))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text(L10n.t(
                    "Встроенный intro остаётся первым слайдом и служит безопасным fallback, даже если R2 временно недоступен.",
                    "O‘rnatilgan intro birinchi slayd bo‘lib qoladi va R2 vaqtincha ishlamasa ham xavfsiz fallback vazifasini bajaradi.",
                    settings.language
                ))
                .font(.system(size: 13.5))
                .foregroundStyle(.secondary)
                .lineSpacing(3)
            }
            .padding(17)
        }
        .asuCard(radius: 30)
    }

    private var libraryHeader: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.t("ВИДЕО КАРУСЕЛИ", "KARUSEL VIDEOLARI", settings.language))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.15)
                    .foregroundStyle(.secondary)
                Text("\(videos.count) \(L10n.t("добавлено", "qo‘shilgan", settings.language))")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .tracking(-0.65)
            }
            Spacer()
            Text(L10n.t("MP4 / MOV / WebM · до 80 МБ", "MP4 / MOV / WebM · 80 MB gacha", settings.language))
                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private var videoLibrary: some View {
        VStack(spacing: 16) {
            ForEach($videos) { $video in
                ASUAdminHomeVideoEditorCard(
                    video: $video,
                    brands: brands,
                    isSaving: savingKey == video.key,
                    isSaved: savedKey == video.key,
                    isDeleting: deletingKey == video.key,
                    save: { Task { await saveVideo(video) } },
                    delete: { pendingDelete = video }
                )
                .environmentObject(settings)
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 13) {
            ProgressView().controlSize(.large)
            Text(L10n.t("Загружаем библиотеку видео…", "Video kutubxonasi yuklanmoqda…", settings.language))
                .font(.system(size: 13.5, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "film.stack")
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(.secondary)
            Text(L10n.t("Дополнительных видео пока нет", "Qo‘shimcha videolar hali yo‘q", settings.language))
                .font(.system(size: 19, weight: .bold, design: .rounded))
            Text(L10n.t(
                "Добавьте короткий ролик автомобиля. После загрузки укажите марку, модель, цену и статус.",
                "Avtomobilning qisqa videosini qo‘shing. Yuklangandan keyin marka, model, narx va statusni kiriting.",
                settings.language
            ))
            .font(.system(size: 13.5))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .lineSpacing(3)
            Button(L10n.t("Добавить видео", "Video qo‘shish", settings.language)) {
                showImporter = true
            }
            .buttonStyle(ASUPrimaryButtonStyle(prominent: false))
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 250)
        .asuCard(radius: 28)
    }

    private func errorState(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(L10n.t("Не удалось загрузить видео", "Videolarni yuklab bo‘lmadi", settings.language), systemImage: "exclamationmark.triangle")
                .font(.system(size: 17, weight: .bold, design: .rounded))
            Text(message)
                .font(.system(size: 13.5))
                .foregroundStyle(.secondary)
            Button(L10n.t("Повторить", "Qayta urinish", settings.language)) {
                Task { await loadAll(silent: false) }
            }
            .buttonStyle(ASUPrimaryButtonStyle(prominent: false))
        }
        .padding(18)
        .asuCard(radius: 28)
    }

    private func inlineError(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.triangle")
            .font(.system(size: 12.5, weight: .medium, design: .rounded))
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(15)
            .background(Color.red.opacity(0.06), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var deniedState: some View {
        VStack(spacing: 13) {
            Image(systemName: "lock.shield")
                .font(.system(size: 36, weight: .light))
            Text(L10n.t("Нет доступа к Home Media", "Home Media uchun ruxsat yo‘q", settings.language))
                .font(.system(size: 20, weight: .bold, design: .rounded))
            Text(L10n.t("Управление рекламной главной доступно администраторам.", "Reklama bosh sahifasini boshqarish administratorlar uchun mavjud.", settings.language))
                .font(.system(size: 13.5))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 230)
        .padding(18)
        .asuCard(radius: 28)
    }

    @MainActor
    private func loadAll(silent: Bool) async {
        guard roleAllowed, let token = session.bearerToken else { return }
        if !silent { isLoading = true }
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let videoTask = mediaAPI.homeVideos(token: token)
            async let carsTask = adminAPI.cars(query: "", brand: nil, status: .all, country: .all, token: token)
            let loadedVideos = try await videoTask
            videos = loadedVideos

            do {
                let snapshot = try await carsTask
                let known = ASUHomeContent.brands.map(\.name)
                let merged = Set(known + snapshot.brands.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
                brands = merged.sorted { left, right in
                    if let li = known.firstIndex(of: left), let ri = known.firstIndex(of: right) { return li < ri }
                    if known.contains(left) { return true }
                    if known.contains(right) { return false }
                    return left.localizedCaseInsensitiveCompare(right) == .orderedAscending
                }
            } catch {
                // Known brands stay available if the cars request is temporarily unavailable.
            }
        } catch let error as ASUAdminAPI.APIError {
            handle(error)
        } catch {
            errorMessage = L10n.t("Не удалось загрузить список видео.", "Video ro‘yxatini yuklab bo‘lmadi.", settings.language)
        }
    }

    @MainActor
    private func uploadVideo(_ url: URL) async {
        guard !isUploading, let token = session.bearerToken else { return }
        isUploading = true
        errorMessage = nil
        defer { isUploading = false }

        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        do {
            let uploaded = try await mediaAPI.uploadHomeVideo(fileURL: url, token: token)
            videos.append(uploaded)
            savedKey = nil
        } catch let error as ASUAdminAPI.APIError {
            handle(error)
        } catch {
            errorMessage = L10n.t("Не удалось загрузить видео.", "Videoni yuklab bo‘lmadi.", settings.language)
        }
    }

    @MainActor
    private func saveVideo(_ video: ASUAdminHomeVideo) async {
        guard savingKey == nil, let token = session.bearerToken else { return }
        savingKey = video.key
        savedKey = nil
        errorMessage = nil
        defer { savingKey = nil }

        do {
            let updated = try await mediaAPI.saveHomeVideo(video, token: token)
            if let index = videos.firstIndex(where: { $0.key == updated.key }) {
                videos[index] = updated
            }
            savedKey = updated.key
        } catch let error as ASUAdminAPI.APIError {
            handle(error)
        } catch {
            errorMessage = L10n.t("Не удалось сохранить подпись видео.", "Video yozuvini saqlab bo‘lmadi.", settings.language)
        }
    }

    @MainActor
    private func deleteVideo(_ video: ASUAdminHomeVideo) async {
        guard deletingKey == nil, let token = session.bearerToken else { return }
        deletingKey = video.key
        errorMessage = nil
        defer { deletingKey = nil }

        do {
            try await mediaAPI.deleteHomeVideo(key: video.key, token: token)
            withAnimation(reduceMotion ? nil : ASUDesign.spring) {
                videos.removeAll { $0.key == video.key }
            }
            if savedKey == video.key { savedKey = nil }
        } catch let error as ASUAdminAPI.APIError {
            handle(error)
        } catch {
            errorMessage = L10n.t("Не удалось удалить видео.", "Videoni o‘chirib bo‘lmadi.", settings.language)
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
}

private struct ASUAdminHomeVideoEditorCard: View {
    @EnvironmentObject private var settings: AppSettings
    @Binding var video: ASUAdminHomeVideo

    let brands: [String]
    let isSaving: Bool
    let isSaved: Bool
    let isDeleting: Bool
    let save: () -> Void
    let delete: () -> Void

    @State private var videoMuted = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            preview
            editor
        }
        .asuCard(radius: 30)
    }

    private var preview: some View {
        ZStack(alignment: .bottomLeading) {
            if let url = video.resolvedURL {
                ASUVideoSurface(
                    url: url,
                    isMuted: videoMuted,
                    shouldPlay: true,
                    loops: true,
                    gravity: .resizeAspect
                )
                .frame(maxWidth: .infinity)
                .frame(height: 320)
                .background(Color.black)
                .clipped()
            } else {
                ASUDesign.gallery
                    .frame(height: 320)
                    .overlay(Image(systemName: "film").font(.system(size: 40, weight: .light)).foregroundStyle(.secondary))
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.68)],
                startPoint: .center,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    Circle().fill(statusColor).frame(width: 7, height: 7)
                    Text(video.status.title(settings.language).uppercased())
                }
                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                .tracking(0.9)
                Text(previewTitle)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .tracking(-0.45)
                    .lineLimit(2)
                Text(ASUAdminMediaFormatting.price(video.price, currency: video.currency, onRequest: video.priceOnRequest, language: settings.language))
                    .font(.system(size: 14.5, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(17)

            Button {
                videoMuted.toggle()
            } label: {
                Image(systemName: videoMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(.black.opacity(0.50), in: Circle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(13)
        }
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.t("РЕКЛАМНЫЙ РОЛИК", "REKLAMA ROLIGI", settings.language))
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(.secondary)
                    Text(ASUAdminMediaFormatting.fileSize(video.size))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                Spacer()
                if isSaved {
                    Label(L10n.t("Сохранено", "Saqlandi", settings.language), systemImage: "checkmark.circle.fill")
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(ASUDesign.success)
                }
            }

            brandPicker

            VStack(spacing: 12) {
                fieldLabel(L10n.t("Модель / комплектация", "Model / komplektatsiya", settings.language))
                TextField("Cullinan Black Badge", text: $video.model)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15.5, weight: .medium, design: .rounded))
                    .padding(.horizontal, 14)
                    .frame(height: 50)
                    .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))
            }

            HStack(spacing: 10) {
                menuField(
                    title: L10n.t("Статус", "Status", settings.language),
                    value: video.status.title(settings.language)
                ) {
                    ForEach(ASUAdminHomeVideoStatus.allCases) { status in
                        Button(status.title(settings.language)) { video.status = status }
                    }
                }

                menuField(title: L10n.t("Валюта", "Valyuta", settings.language), value: video.currency.rawValue) {
                    ForEach(ASUAdminMediaCurrency.allCases) { currency in
                        Button(currency.rawValue) { video.currency = currency }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                fieldLabel(L10n.t("Цена", "Narx", settings.language))
                TextField(
                    "258000",
                    text: Binding(
                        get: { video.price.map { String($0) } ?? "" },
                        set: { raw in
                            let digits = raw.filter(\.isNumber)
                            video.price = digits.isEmpty ? nil : Int64(digits)
                        }
                    )
                )
                .keyboardType(.numberPad)
                .disabled(video.priceOnRequest)
                .opacity(video.priceOnRequest ? 0.46 : 1)
                .textFieldStyle(.plain)
                .font(.system(size: 15.5, weight: .medium, design: .rounded))
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))

                Toggle(L10n.t("Цена по запросу", "Narx so‘rov bo‘yicha", settings.language), isOn: $video.priceOnRequest)
                    .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                    .tint(ASUDesign.success)
            }

            HStack(spacing: 10) {
                Button(action: save) {
                    HStack(spacing: 8) {
                        if isSaving {
                            ProgressView().controlSize(.small).tint(.white)
                        } else {
                            Image(systemName: isSaved ? "checkmark" : "square.and.arrow.down")
                        }
                        Text(isSaving
                             ? L10n.t("Сохраняем…", "Saqlanmoqda…", settings.language)
                             : isSaved
                               ? L10n.t("Сохранено", "Saqlandi", settings.language)
                               : L10n.t("Сохранить подпись", "Yozuvni saqlash", settings.language))
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.primary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isSaving || isDeleting)

                Button(role: .destructive, action: delete) {
                    Group {
                        if isDeleting {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "trash")
                        }
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 52, height: 52)
                    .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isSaving || isDeleting)
            }
        }
        .padding(18)
    }

    private var brandPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldLabel(L10n.t("Марка", "Marka", settings.language))
            ScrollView(.horizontal) {
                HStack(spacing: 9) {
                    ForEach(brands, id: \.self) { brand in
                        Button {
                            video.brand = brand
                        } label: {
                            HStack(spacing: 8) {
                                brandLogo(brand)
                                    .frame(width: 32, height: 22)
                                Text(brand)
                                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(video.brand == brand ? Color(uiColor: .systemBackground) : Color.primary)
                            .padding(.horizontal, 12)
                            .frame(height: 44)
                            .background(video.brand == brand ? Color.primary : ASUDesign.soft, in: Capsule())
                            .overlay(Capsule().stroke(ASUDesign.line, lineWidth: video.brand == brand ? 0 : 0.7))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10.5, weight: .bold, design: .rounded))
            .tracking(0.6)
            .foregroundStyle(.secondary)
    }

    private func menuField<MenuContent: View>(
        title: String,
        value: String,
        @ViewBuilder menu: () -> MenuContent
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel(title)
            Menu(content: menu) {
                HStack {
                    Text(value)
                        .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 13)
                .frame(height: 48)
                .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
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
                .font(.system(size: 10, weight: .black, design: .rounded))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var previewTitle: String {
        let brand = video.brand.trimmingCharacters(in: .whitespacesAndNewlines)
        let model = video.model.trimmingCharacters(in: .whitespacesAndNewlines)
        let joined = [brand, model].filter { !$0.isEmpty }.joined(separator: " ")
        return joined.isEmpty ? "Auto Sale Umar" : joined
    }

    private var statusColor: Color {
        switch video.status {
        case .inStock, .inShowroom: return ASUDesign.success
        case .reserved: return ASUDesign.orange
        case .inTransit, .madeToOrder: return Color.white.opacity(0.72)
        }
    }
}
