import SwiftUI

struct MoreView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: AppStore
    @Environment(\.openURL) private var openURL
    @State private var showRequest = false
    @State private var showBooking = false
    @State private var showShowroom = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    BrandHeader()
                    HStack { Text(L10n.t("Auto Sale Umar", "Auto Sale Umar", settings.language)).asuPageTitle(); Spacer() }.padding(.horizontal, ASUDesign.pagePadding)
                    menuSection
                    if !store.clientRequests.isEmpty { requestHistory }
                    ContactsCompactCard()
                    VStack(alignment: .leading, spacing: 9) { Text(L10n.t("Тихая точность", "Sokin aniqlik", settings.language)).font(.system(size: 23, weight: .bold, design: .rounded)); Text(L10n.t("Точный выбор, ясная информация и личная ответственность. Роскошь — это отсутствие сомнений.", "Aniq tanlov, tushunarli ma’lumot va shaxsiy mas’uliyat. Hashamat — shubhaning yo‘qligi.", settings.language)).font(.system(size: 14.5)).foregroundStyle(.secondary).lineSpacing(4) }.padding(22).asuCard().padding(.horizontal, ASUDesign.pagePadding)
                    Text("AUTO SALE UMAR · 2026").font(.system(size: 10, weight: .bold, design: .rounded)).tracking(1.3).foregroundStyle(.tertiary).padding(.vertical, 16)
                }.padding(.bottom, 28)
            }
        }
        .sheet(isPresented: $showRequest) { NavigationStack { RequestCarView() } }
        .sheet(isPresented: $showBooking) { NavigationStack { BookingView() } }
        .sheet(isPresented: $showShowroom) { NavigationStack { ShowroomView() } }
        .sheet(isPresented: $showSettings) { NavigationStack { SettingsView() } }
    }

    private var menuSection: some View {
        VStack(spacing: 0) {
            row("sparkles", L10n.t("Персональный подбор", "Shaxsiy tanlov", settings.language), L10n.t("Найдём нужную комплектацию", "Kerakli komplektatsiyani topamiz", settings.language)) { showRequest = true }
            Divider().padding(.leading, 60)
            row("calendar", L10n.t("Забронировать визит", "Tashrifni band qilish", settings.language), L10n.t("Шоурум в Ташкенте", "Toshkentdagi shourum", settings.language)) { showBooking = true }
            Divider().padding(.leading, 60)
            row("building.2", L10n.t("О шоуруме", "Shourum haqida", settings.language), L10n.t("Пространство и подход", "Makon va yondashuv", settings.language)) { showShowroom = true }
            Divider().padding(.leading, 60)
            row("gearshape", L10n.t("Настройки", "Sozlamalar", settings.language), L10n.t("Язык и оформление", "Til va ko‘rinish", settings.language)) { showSettings = true }
            Divider().padding(.leading, 60)
            row("safari", L10n.t("Сайт", "Veb-sayt", settings.language), "autosaleumar.com") { openURL(AppConfig.website) }
        }.asuCard().padding(.horizontal, ASUDesign.pagePadding)
    }
    private func row(_ symbol: String, _ title: String, _ subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { HStack(spacing: 12) { Image(systemName: symbol).font(.system(size: 17, weight: .semibold)).frame(width: 34, height: 34).background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 11, style: .continuous)); VStack(alignment: .leading, spacing: 2) { Text(title).font(.system(size: 15.5, weight: .semibold)); Text(subtitle).font(.system(size: 12)).foregroundStyle(.secondary) }; Spacer(); Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(.tertiary) }.padding(.horizontal, 14).frame(minHeight: 64) }.buttonStyle(.plain)
    }
    private var requestHistory: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.t("МОИ ДЕЙСТВИЯ", "MENING SO‘ROVLARIM", settings.language)).font(.system(size: 10.5, weight: .bold, design: .rounded)).tracking(1).foregroundStyle(.secondary).padding(.leading, 4)
            VStack(spacing: 0) { ForEach(Array(store.clientRequests.prefix(4)).indices, id: \.self) { i in let item = store.clientRequests[i]; HStack(spacing: 12) { Image(systemName: item.kind == .visit ? "calendar" : "sparkles").frame(width: 32, height: 32).background(ASUDesign.soft, in: Circle()); VStack(alignment: .leading, spacing: 2) { Text(item.title).font(.system(size: 14.5, weight: .semibold)); Text(item.detail).font(.system(size: 11.5)).foregroundStyle(.secondary) }; Spacer(); Text(item.createdAt, style: .date).font(.system(size: 10.5)).foregroundStyle(.tertiary) }.padding(13); if i < min(3, store.clientRequests.count - 1) { Divider().padding(.leading, 56) } } }.asuCard(radius: 22, shadow: false)
        }.padding(.horizontal, ASUDesign.pagePadding)
    }
}
