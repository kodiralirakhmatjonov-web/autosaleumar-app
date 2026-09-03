import SwiftUI

struct MoreView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.openURL) private var openURL
    @State private var showRequest = false
    @State private var showBooking = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    BrandHeader()
                    Text(L10n.t("Ещё", "Yana", settings.language)).asuPageTitle().padding(.horizontal, ASUDesign.pagePadding)

                    nativeSection(L10n.t("Быстрый доступ", "Tezkor kirish", settings.language)) {
                        row("sparkles", L10n.t("Персональный подбор", "Shaxsiy tanlov", settings.language)) { showRequest = true }
                        Divider().padding(.leading, 54)
                        row("calendar", L10n.t("Забронировать визит", "Tashrifni band qilish", settings.language)) { showBooking = true }
                        Divider().padding(.leading, 54)
                        row("map", L10n.t("Маршрут до шоурума", "Shourumga yo‘l", settings.language)) { openURL(AppConfig.yandexMaps) }
                    }

                    nativeSection(L10n.t("Связь", "Aloqa", settings.language)) {
                        row("message", "WhatsApp") { openURL(URL(string: "https://wa.me/\(AppConfig.whatsappPhone)")!) }
                        Divider().padding(.leading, 54)
                        row("paperplane", "Telegram") { openURL(AppConfig.telegram) }
                        Divider().padding(.leading, 54)
                        row("camera", "Instagram") { openURL(AppConfig.instagram) }
                        Divider().padding(.leading, 54)
                        row("phone", AppConfig.phoneDisplay) { openURL(URL(string: "tel:\(AppConfig.phone)")!) }
                    }

                    settingsSection

                    nativeSection(L10n.t("Система", "Tizim", settings.language)) {
                        row("globe", L10n.t("Открыть autosaleumar.com", "autosaleumar.com ni ochish", settings.language)) { openURL(AppConfig.website) }
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showRequest) { NavigationStack { RequestCarView() } }
        .sheet(isPresented: $showBooking) { NavigationStack { BookingView() } }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.t("НАСТРОЙКИ", "SOZLAMALAR", settings.language))
                .font(.system(size: 11, weight: .bold, design: .rounded)).tracking(0.9).foregroundStyle(.secondary).padding(.leading, 4)
            VStack(spacing: 14) {
                Picker(L10n.t("Язык", "Til", settings.language), selection: $settings.language) {
                    ForEach(AppLanguage.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                Picker(L10n.t("Оформление", "Ko‘rinish", settings.language), selection: $settings.theme) {
                    ForEach(AppTheme.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            .padding(14).asuCard()
        }
        .padding(.horizontal, ASUDesign.pagePadding)
    }

    private func nativeSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded)).tracking(0.9).foregroundStyle(.secondary).padding(.leading, 4)
            VStack(spacing: 0) { content() }.asuCard()
        }
        .padding(.horizontal, ASUDesign.pagePadding)
    }

    private func row(_ symbol: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ASUGlassSurface(radius: 12) {
                    Image(systemName: symbol).font(.system(size: 16, weight: .semibold)).frame(width: 34, height: 34)
                }
                Text(title).font(.system(size: 16, weight: .semibold, design: .rounded))
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundStyle(.tertiary)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .frame(minHeight: 62)
        }
        .buttonStyle(.plain)
    }
}
