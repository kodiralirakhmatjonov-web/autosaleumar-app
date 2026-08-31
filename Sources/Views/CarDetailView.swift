import SwiftUI

struct CarDetailView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: AppStore
    let car: Car
    @State private var showContact = false
    @State private var selectedImage = 0

    private var images: [URL?] { car.imageURLs.isEmpty ? [car.coverURL] : car.imageURLs.map(Optional.some) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                gallery
                VStack(alignment: .leading, spacing: 12) {
                    StatusPill(status: car.status, language: settings.language)
                    Text(car.displayName).font(.system(size: 30, weight: .bold, design: .rounded)).tracking(-0.8)
                    HStack(spacing: 8) { if let y = car.year { Text(String(y)) }; if let t = car.trim { Text("·"); Text(t) }; if let e = car.engineText { Text("·"); Text(e) } }.font(.system(size: 14)).foregroundStyle(.secondary)
                    Text(Format.price(car, language: settings.language)).font(.system(size: 27, weight: .bold, design: .rounded))
                }.frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, ASUDesign.pagePadding)
                specs
                if let description = car.localizedDescription(settings.language), !description.isEmpty { VStack(alignment: .leading, spacing: 8) { Text(L10n.t("Об автомобиле", "Avtomobil haqida", settings.language)).font(.system(size: 20, weight: .bold, design: .rounded)); Text(description).font(.system(size: 15)).foregroundStyle(.secondary).lineSpacing(4) }.padding(18).asuCard().padding(.horizontal, ASUDesign.pagePadding) }
                HStack(spacing: 10) {
                    Button { store.toggleCompare(car) } label: { Label(store.isCompared(car) ? L10n.t("В сравнении", "Taqqoslanmoqda", settings.language) : L10n.t("Сравнить", "Taqqoslash", settings.language), systemImage: "rectangle.split.2x1").frame(maxWidth: .infinity).frame(height: 50).background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 17, style: .continuous)) }.buttonStyle(.plain)
                    ShareLink(item: AppConfig.carShareURL(car)) { Image(systemName: "square.and.arrow.up").frame(width: 50, height: 50).background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 17, style: .continuous)) }
                }.padding(.horizontal, ASUDesign.pagePadding)
                Button { showContact = true } label: { Label(L10n.t("Связаться с менеджером", "Menejer bilan bog‘lanish", settings.language), systemImage: "message") }.buttonStyle(ASUPrimaryButtonStyle()).padding(.horizontal, ASUDesign.pagePadding)
            }.padding(.bottom, 28)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { store.toggleFavorite(car) } label: { Image(systemName: store.isFavorite(car) ? "heart.fill" : "heart").foregroundStyle(store.isFavorite(car) ? ASUDesign.orange : .primary) } } }
        .sheet(isPresented: $showContact) { ContactSheet(car: car) }
    }

    private var gallery: some View {
        TabView(selection: $selectedImage) { ForEach(Array(images.enumerated()), id: \.offset) { index, url in CarImage(url: url, height: 330).tag(index) } }
            .tabViewStyle(.page(indexDisplayMode: images.count > 1 ? .automatic : .never)).frame(height: 330).background(ASUDesign.soft).clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous)).padding(.horizontal, ASUDesign.pagePadding)
    }

    private var specs: some View {
        let values: [(String,String,String?)] = [
            ("gauge.with.dots.needle.50percent", L10n.t("Пробег", "Yurish", settings.language), car.mileageKm.map { "\($0) км" }),
            ("engine.combustion", L10n.t("Двигатель", "Dvigatel", settings.language), car.engineText),
            ("arrow.triangle.branch", L10n.t("Привод", "Privod", settings.language), car.driveType),
            ("gearshape.2", L10n.t("Коробка", "Uzatma", settings.language), car.transmission),
            ("person.2", L10n.t("Мест", "O‘rin", settings.language), car.seats.map(String.init)),
            ("paintpalette", L10n.t("Цвет", "Rang", settings.language), car.exteriorColor)
        ]
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(values.indices, id: \.self) { i in
                let v = values[i]
                VStack(alignment: .leading, spacing: 7) { Image(systemName: v.0).font(.system(size: 18, weight: .medium)); Text(v.1).font(.system(size: 11)).foregroundStyle(.secondary); Text(v.2 ?? "—").font(.system(size: 13.5, weight: .semibold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.72) }.frame(maxWidth: .infinity, minHeight: 92, alignment: .leading).padding(13).asuCard(radius: 20, shadow: false)
            }
        }.padding(.horizontal, ASUDesign.pagePadding)
    }
}

struct ContactSheet: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    let car: Car?
    @Environment(\.openURL) private var openURL
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Capsule().fill(Color.secondary.opacity(0.35)).frame(width: 42, height: 5).frame(maxWidth: .infinity).padding(.top, 9)
            HStack { Text(L10n.t("Связаться", "Bog‘lanish", settings.language)).font(.system(size: 28, weight: .bold, design: .rounded)); Spacer(); Button { dismiss() } label: { Image(systemName: "xmark").frame(width: 42, height: 42).background(ASUDesign.soft, in: Circle()) }.buttonStyle(.plain) }
            if let car { Text(car.displayName).font(.system(size: 15, weight: .semibold)).foregroundStyle(.secondary) }
            contactButton("WhatsApp", "message.fill", primary: true) { openURL(whatsAppURL(car)) }
            contactButton("Telegram", "paperplane.fill") { openURL(AppConfig.telegram) }
            contactButton(L10n.t("Позвонить", "Qo‘ng‘iroq", settings.language), "phone.fill") { openURL(URL(string: "tel:\(AppConfig.phone)")!) }
            Text(L10n.t("Персональный менеджер ответит и продолжит консультацию в удобном для вас канале.", "Shaxsiy menejer sizga qulay kanalda maslahatni davom ettiradi.", settings.language)).font(.system(size: 13)).foregroundStyle(.secondary).lineSpacing(3).padding(.top, 4)
            Spacer()
        }.padding(.horizontal, 20)
        .presentationDetents([.height(410)])
        .presentationCornerRadius(34)
    }
    private func contactButton(_ title: String, _ icon: String, primary: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) { Label(title, systemImage: icon).font(.system(size: 16, weight: .semibold)).frame(maxWidth: .infinity).frame(height: 54).foregroundStyle(primary ? Color(uiColor: .systemBackground) : Color.primary).background(primary ? Color.primary : ASUDesign.soft, in: RoundedRectangle(cornerRadius: 19, style: .continuous)) }.buttonStyle(.plain)
    }
    private func whatsAppURL(_ car: Car?) -> URL {
        let text = car.map { "Здравствуйте. Интересует \($0.displayName)." } ?? "Здравствуйте. Хочу получить консультацию Auto Sale Umar."
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://wa.me/\(AppConfig.whatsappPhone)?text=\(encoded)")!
    }
}
