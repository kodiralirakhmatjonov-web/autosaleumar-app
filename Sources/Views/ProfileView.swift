import SwiftUI
import UIKit

struct ProfileView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var profile = Persistence.customerProfile()
    @State private var activities = Persistence.clientActivities()
    @State private var showProfileEditor = false
    @State private var showRequest = false
    @State private var showBooking = false
    @State private var showCompare = false
    @State private var highlightedActivityCode: String?

    let selectTab: (AppTab) -> Void

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 22) {
                        BrandHeader()
                        profileHero
                        quickActions
                        activitySection
                        autoSaleUmarSection
                        contactSection
                        settingsSection
                        appFooter
                    }
                    .padding(.bottom, 34)
                }
                .background(ASUDesign.page)
                .onAppear {
                    reloadLocalState()
                    focusActivityIfNeeded(proxy)
                }
                .onChange(of: router.activityFocusCode) { _, _ in
                    focusActivityIfNeeded(proxy)
                }
            }
            .navigationDestination(for: ProfileDestination.self) { destination in
                switch destination {
                case .location: LocationView()
                case .trust: TrustView(openCatalog: { selectTab(.catalog) })
                case .gift: RamadanGiftView()
                }
            }
        }
        .sheet(isPresented: $showProfileEditor, onDismiss: reloadLocalState) {
            NavigationStack { CustomerProfileEditor() }
        }
        .sheet(isPresented: $showRequest, onDismiss: reloadLocalState) { NavigationStack { RequestCarView() } }
        .sheet(isPresented: $showBooking, onDismiss: reloadLocalState) { NavigationStack { BookingView() } }
        .sheet(isPresented: $showCompare) { CompareView() }
        .sensoryFeedback(.selection, trigger: settings.language)
        .sensoryFeedback(.selection, trigger: settings.theme)
    }

    private var profileHero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                ASUGlassCircleSurface(size: 64) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 25, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name.isEmpty ? L10n.t("Ваш профиль", "Profilingiz", settings.language) : profile.name)
                        .font(.system(size: 27, weight: .bold, design: .rounded))
                        .tracking(-0.7)
                    Text(profile.phone.isEmpty
                         ? L10n.t("Сохраните контакт для быстрых заявок и визитов.", "Tezkor so‘rov va tashriflar uchun kontaktni saqlang.", settings.language)
                         : profile.phone)
                        .font(.system(size: 13.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 4)

                ASUGlassIconButton(
                    symbol: "pencil",
                    size: 44,
                    accessibilityLabel: L10n.t("Редактировать профиль", "Profilni tahrirlash", settings.language)
                ) {
                    showProfileEditor = true
                }
            }

            HStack(spacing: 10) {
                profileMetric(value: "\(store.favoriteIDs.count)", label: L10n.t("Избранное", "Saqlangan", settings.language), symbol: "heart.fill")
                profileMetric(value: "\(store.compareIDs.count)", label: L10n.t("Сравнение", "Solishtirish", settings.language), symbol: "arrow.left.arrow.right")
                profileMetric(value: "\(activities.count)", label: L10n.t("Обращения", "Murojaatlar", settings.language), symbol: "text.bubble.fill")
            }
        }
        .padding(20)
        .asuCard(radius: 32)
        .padding(.horizontal, ASUDesign.pagePadding)
    }

    private func profileMetric(value: String, label: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, minHeight: 94, alignment: .leading)
        .padding(12)
        .modifier(ClientGlassField())
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionKicker(L10n.t("БЫСТРЫЕ ДЕЙСТВИЯ", "TEZKOR AMALLAR", settings.language))
            HStack(spacing: 10) {
                quickAction("sparkles", L10n.t("Подбор", "Tanlov", settings.language)) { showRequest = true }
                quickAction("calendar", L10n.t("Визит", "Tashrif", settings.language)) { showBooking = true }
                quickAction("arrow.left.arrow.right", L10n.t("Сравнить", "Solishtirish", settings.language)) { showCompare = true }
            }
        }
        .padding(.horizontal, ASUDesign.pagePadding)
    }

    private func quickAction(_ symbol: String, _ title: String, action: @escaping () -> Void) -> some View {
        ASUGlassActionTile(action: action) {
            VStack(spacing: 8) {
                Image(systemName: symbol).font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 76)
        }
    }

    private var displayedActivities: [ASUClientActivity] {
        var result = Array(activities.prefix(8))
        if let code = router.activityFocusCode,
           let focused = activities.first(where: { $0.code == code }),
           !result.contains(focused) {
            result.append(focused)
        }
        return result
    }

    private func focusActivityIfNeeded(_ proxy: ScrollViewProxy) {
        guard let code = router.activityFocusCode else { return }
        reloadLocalState()
        guard activities.contains(where: { $0.code == code }) else {
            router.clearActivityFocus()
            return
        }

        highlightedActivityCode = code
        DispatchQueue.main.async {
            withAnimation(reduceMotion ? nil : ASUDesign.softSpring) {
                proxy.scrollTo(code, anchor: .center)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            guard highlightedActivityCode == code else { return }
            withAnimation(reduceMotion ? nil : .easeOut(duration: ASUDesign.navigationDuration)) {
                highlightedActivityCode = nil
            }
            if router.activityFocusCode == code { router.clearActivityFocus() }
        }
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionKicker(L10n.t("МОИ ОБРАЩЕНИЯ", "MUROJAATLARIM", settings.language))
                Spacer()
                if !activities.isEmpty {
                    Text(L10n.t("На этом iPhone", "Ushbu iPhone’da", settings.language))
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
            }

            if activities.isEmpty {
                VStack(spacing: 14) {
                    ASUGlassCircleSurface(size: 66) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Text(L10n.t("История пока пустая", "Tarix hozircha bo‘sh", settings.language))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text(L10n.t(
                        "После персонального подбора или бронирования визита код обращения сохранится здесь.",
                        "Shaxsiy tanlov yoki tashrif band qilingandan keyin murojaat kodi shu yerda saqlanadi.",
                        settings.language
                    ))
                    .font(.system(size: 13.5))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 26)
                .padding(.horizontal, 18)
                .asuCard(radius: 28)
            } else {
                VStack(spacing: 0) {
                    ForEach(displayedActivities) { activity in
                        activityRow(activity)
                        if activity.id != displayedActivities.last?.id { Divider().padding(.leading, 56) }
                    }
                }
                .asuCard(radius: 28)
            }
        }
        .padding(.horizontal, ASUDesign.pagePadding)
    }

    private func activityRow(_ activity: ASUClientActivity) -> some View {
        HStack(spacing: 12) {
            ASUGlassCircleSurface(size: 42) {
                Image(systemName: activity.kind == .showroomVisit ? "calendar.badge.checkmark" : "sparkles")
                    .font(.system(size: 15, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.system(size: 14.5, weight: .bold, design: .rounded))
                    .lineLimit(1)
                Text(activityLine(activity))
                    .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(activity.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 10.5, design: .rounded))
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 6)

            Button {
                UIPasteboard.general.string = activity.code
                ASUHaptics.selection()
            } label: {
                VStack(alignment: .trailing, spacing: 3) {
                    Text(activity.code)
                        .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                        .lineLimit(1)
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 82)
        .id(activity.code)
        .overlay {
            if highlightedActivityCode == activity.code {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(ASUDesign.orange.opacity(0.82), lineWidth: 1.6)
                    .padding(4)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                if activity.kind == .showroomVisit { ASUVisitReminder.cancel(code: activity.code) }
                Persistence.removeActivity(id: activity.id)
                reloadLocalState()
            } label: {
                Label(L10n.t("Удалить", "O‘chirish", settings.language), systemImage: "trash")
            }
        }
    }

    private func activityLine(_ activity: ASUClientActivity) -> String {
        switch activity.kind {
        case .vehicleRequest:
            return L10n.t("Запрос отправлен · код сохранён", "So‘rov yuborildi · kod saqlandi", settings.language)
        case .showroomVisit:
            let date = activity.scheduledDate ?? ""
            let time = activity.timeSlot ?? activity.subtitle
            return L10n.t("Визит · \(date) · \(time)", "Tashrif · \(date) · \(time)", settings.language)
        }
    }

    private var autoSaleUmarSection: some View {
        profileSection(L10n.t("AUTO SALE UMAR", "AUTO SALE UMAR", settings.language)) {
            navigationRow("location.fill", L10n.t("Локация шоурума", "Shourum lokatsiyasi", settings.language), .location)
            Divider().padding(.leading, 54)
            navigationRow("checkmark.shield.fill", L10n.t("25 лет доверия", "25 yil ishonch", settings.language), .trust)
            Divider().padding(.leading, 54)
            navigationRow("gift.fill", "Ramadan Gift", .gift)
        }
    }

    private var contactSection: some View {
        profileSection(L10n.t("СВЯЗЬ", "ALOQA", settings.language)) {
            actionRow("message.fill", "WhatsApp") { openURL(URL(string: "https://wa.me/\(AppConfig.whatsappPhone)")!) }
            Divider().padding(.leading, 54)
            actionRow("paperplane.fill", "Telegram") { openURL(AppConfig.telegram) }
            Divider().padding(.leading, 54)
            actionRow("camera.fill", "Instagram") { openURL(AppConfig.instagram) }
            Divider().padding(.leading, 54)
            actionRow("phone.fill", AppConfig.phoneDisplay) { openURL(URL(string: "tel:\(AppConfig.phone)")!) }
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionKicker(L10n.t("НАСТРОЙКИ", "SOZLAMALAR", settings.language))

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.t("Язык", "Til", settings.language)).font(.system(size: 11.5, weight: .semibold, design: .rounded)).foregroundStyle(.secondary)
                    Picker("", selection: $settings.language) {
                        ForEach(AppLanguage.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.t("Оформление", "Ko‘rinish", settings.language)).font(.system(size: 11.5, weight: .semibold, design: .rounded)).foregroundStyle(.secondary)
                    Picker("", selection: $settings.theme) {
                        ForEach(AppTheme.allCases) { Text($0.title(settings.language)).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Toggle(isOn: $settings.visitRemindersEnabled) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.t("Напоминания о визитах", "Tashrif eslatmalari", settings.language))
                            .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                        Text(L10n.t("За 2 часа до забронированного времени", "Band qilingan vaqtdan 2 soat oldin", settings.language))
                            .font(.system(size: 10.5, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(ASUDesign.orange)
            }
            .padding(16)
            .asuCard(radius: 28)
        }
        .padding(.horizontal, ASUDesign.pagePadding)
    }

    private var appFooter: some View {
        VStack(spacing: 9) {
            Button { openURL(AppConfig.website) } label: {
                Image(colorScheme == .dark ? "WordmarkWhite" : "WordmarkBlack")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 146)
                    .opacity(0.76)
            }
            .buttonStyle(.plain)

            Text("iOS · \(versionText)")
                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                .foregroundStyle(.tertiary)
            Text(L10n.t("Нативный клиент Auto Sale Umar", "Auto Sale Umar native iOS ilovasi", settings.language))
                .font(.system(size: 10.5, design: .rounded))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func profileSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionKicker(title)
            VStack(spacing: 0) { content() }.asuCard(radius: 28)
        }
        .padding(.horizontal, ASUDesign.pagePadding)
    }

    private func sectionKicker(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10.5, weight: .bold, design: .rounded))
            .tracking(1)
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
    }

    private func actionRow(_ symbol: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { rowLabel(symbol, title) }.buttonStyle(.plain)
    }

    private func navigationRow(_ symbol: String, _ title: String, _ destination: ProfileDestination) -> some View {
        NavigationLink(value: destination) { rowLabel(symbol, title) }.buttonStyle(.plain)
    }

    private func rowLabel(_ symbol: String, _ title: String) -> some View {
        HStack(spacing: 12) {
            ASUGlassSurface(radius: 12) {
                Image(systemName: symbol).font(.system(size: 16, weight: .semibold)).frame(width: 34, height: 34)
            }
            Text(title).font(.system(size: 15.5, weight: .semibold, design: .rounded))
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 11, weight: .bold)).foregroundStyle(.tertiary)
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 14)
        .frame(minHeight: 62)
    }

    private func reloadLocalState() {
        profile = Persistence.customerProfile()
        activities = Persistence.clientActivities()
    }
}

private enum ProfileDestination: Hashable {
    case location
    case trust
    case gift
}

struct CustomerProfileEditor: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var name = Persistence.customerProfile().name
    @State private var phone = Persistence.customerProfile().phone
    @State private var channel = Persistence.customerProfile().preferredChannel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 9) {
                    Text(L10n.t("Ваши данные", "Ma’lumotlaringiz", settings.language)).asuSectionTitle(size: 32)
                    Text(L10n.t(
                        "Они хранятся на этом iPhone и автоматически подставляются в подбор и бронирование визита.",
                        "Ular ushbu iPhone’da saqlanadi va tanlov hamda tashrif formasiga avtomatik qo‘yiladi.",
                        settings.language
                    ))
                    .font(.system(size: 13.5))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                }

                VStack(spacing: 12) {
                    ASUFormField(title: L10n.t("Имя", "Ism", settings.language), text: $name)
                    ASUFormField(title: L10n.t("Телефон", "Telefon", settings.language), text: $phone, keyboard: .phonePad)

                    HStack(spacing: 8) {
                        channelButton(.whatsapp, "WhatsApp", "message.fill")
                        channelButton(.telegram, "Telegram", "paperplane.fill")
                        channelButton(.phone, L10n.t("Звонок", "Qo‘ng‘iroq", settings.language), "phone.fill")
                    }
                }
                .padding(16)
                .asuCard(radius: 28)

                Button {
                    Persistence.saveCustomerProfile(ASUCustomerProfile(name: name.trimmingCharacters(in: .whitespacesAndNewlines), phone: phone.trimmingCharacters(in: .whitespacesAndNewlines), preferredChannel: channel))
                    ASUHaptics.success()
                    dismiss()
                } label: {
                    Label(L10n.t("Сохранить", "Saqlash", settings.language), systemImage: "checkmark")
                }
                .buttonStyle(ASUPrimaryButtonStyle())
            }
            .padding(.horizontal, ASUDesign.pagePadding)
            .padding(.top, 8)
            .padding(.bottom, 34)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(ASUDesign.page)
        .navigationTitle(L10n.t("Профиль", "Profil", settings.language))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { dismiss() } label: { Image(systemName: "xmark") }
            }
        }
    }

    private func channelButton(_ value: ContactChannel, _ title: String, _ symbol: String) -> some View {
        Button { channel = value } label: {
            VStack(spacing: 7) {
                Image(systemName: symbol).font(.system(size: 16, weight: .semibold))
                Text(title).font(.system(size: 10.5, weight: .semibold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.7)
            }
            .foregroundStyle(channel == value ? Color(uiColor: .systemBackground) : .primary)
            .frame(maxWidth: .infinity)
            .frame(height: 68)
            .background(channel == value ? Color.primary : .clear, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .modifier(ClientGlassFieldFallbackOnly(active: channel != value))
        }
        .buttonStyle(.plain)
    }
}
