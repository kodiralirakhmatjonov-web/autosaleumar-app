import SwiftUI

struct CarDetailView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: AppStore
    @State private var showContact = false

    let car: Car

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                gallery
                summary
                specs
                if let description = car.description(settings.language), !description.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L10n.t("Об автомобиле", "Avtomobil haqida", settings.language))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Text(description).font(.system(size: 15)).foregroundStyle(.secondary).lineSpacing(4)
                    }
                    .padding(18).asuCard().padding(.horizontal, ASUDesign.pagePadding)
                }
                Button { showContact = true } label: {
                    Label(L10n.t("Связаться с менеджером", "Menejer bilan bog‘lanish", settings.language), systemImage: "message")
                }
                .buttonStyle(ASUPrimaryButtonStyle())
                .padding(.horizontal, ASUDesign.pagePadding)
            }
            .padding(.bottom, 28)
        }
        .background(ASUDesign.page)
        .navigationTitle(car.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { store.toggleFavorite(car) } label: {
                    Image(systemName: store.isFavorite(car) ? "heart.fill" : "heart")
                }
                ShareLink(item: AppConfig.carShareURL(car)) { Image(systemName: "square.and.arrow.up") }
            }
        }
        .sheet(isPresented: $showContact) { ContactSheet(car: car) }
    }

    private var gallery: some View {
        TabView {
            if car.galleryImageURLs.isEmpty {
                CarImage(url: car.primaryImageURL, height: 330)
            } else {
                ForEach(car.galleryImageURLs, id: \.self) { url in CarImage(url: url, height: 330) }
            }
        }
        .frame(height: 330)
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .background(ASUDesign.gallery)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, ASUDesign.pagePadding)
        .padding(.top, 6)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 10) {
            StatusPill(status: car.status, language: settings.language)
            Text(car.displayName).font(.system(size: 30, weight: .bold, design: .rounded)).tracking(-0.8)
            if let trim = car.trim, !trim.isEmpty { Text(trim).font(.system(size: 15.5)).foregroundStyle(.secondary) }
            Text(Format.price(car, language: settings.language)).font(.system(size: 25, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, ASUDesign.pagePadding)
    }

    private var specs: some View {
        let values: [(String, String, String?)] = [
            ("gauge.with.dots.needle.33percent", L10n.t("Пробег", "Yurgan", settings.language), car.mileageKm.map { "\($0) км" }),
            ("engine.combustion", L10n.t("Двигатель", "Dvigatel", settings.language), car.engineText),
            ("arrow.triangle.branch", L10n.t("Привод", "Privod", settings.language), car.driveType),
            ("gearshape.2", L10n.t("Коробка", "Uzatma", settings.language), car.transmission),
            ("person.2", L10n.t("Места", "O‘rin", settings.language), car.seats.map(String.init)),
            ("paintpalette", L10n.t("Цвет", "Rang", settings.language), car.exteriorColor)
        ]

        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(values.indices, id: \.self) { index in
                let item = values[index]
                VStack(alignment: .leading, spacing: 7) {
                    Image(systemName: item.0).font(.system(size: 18, weight: .medium))
                    Text(item.1).font(.system(size: 11)).foregroundStyle(.secondary)
                    Text(item.2 ?? "—")
                        .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
                .padding(13)
                .asuCard(radius: 20, shadow: false)
            }
        }
        .padding(.horizontal, ASUDesign.pagePadding)
    }
}

struct ContactSheet: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    let car: Car?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Capsule().fill(Color.secondary.opacity(0.35)).frame(width: 42, height: 5).frame(maxWidth: .infinity).padding(.top, 9)
            HStack {
                Text(L10n.t("Связаться", "Bog‘lanish", settings.language)).font(.system(size: 28, weight: .bold, design: .rounded))
                Spacer()
                ASUGlassIconButton(symbol: "xmark", size: 42, accessibilityLabel: L10n.t("Закрыть", "Yopish", settings.language)) { dismiss() }
            }
            if let car { Text(car.displayName).font(.system(size: 15, weight: .semibold)).foregroundStyle(.secondary) }
            contactButton("WhatsApp", "message.fill", primary: true) { openURL(whatsAppURL(car)) }
            contactButton("Telegram", "paperplane.fill") { openURL(AppConfig.telegram) }
            contactButton(L10n.t("Позвонить", "Qo‘ng‘iroq", settings.language), "phone.fill") { openURL(URL(string: "tel:\(AppConfig.phone)")!) }
            Spacer()
        }
        .padding(.horizontal, 20)
        .presentationDetents([.height(385)])
        .presentationCornerRadius(34)
    }

    private func contactButton(_ title: String, _ icon: String, primary: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .foregroundStyle(primary ? Color(uiColor: .systemBackground) : Color.primary)
                .background(primary ? Color.primary : ASUDesign.soft, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func whatsAppURL(_ car: Car?) -> URL {
        let text = car.map { "Здравствуйте. Интересует \($0.displayName)." } ?? "Здравствуйте. Хочу получить консультацию Auto Sale Umar."
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://wa.me/\(AppConfig.whatsappPhone)?text=\(encoded)")!
    }
}
