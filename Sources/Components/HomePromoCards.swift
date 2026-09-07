import SwiftUI

struct ASURamadanHomeFeature: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let gift: RamadanGift
    let language: AppLanguage
    let open: () -> Void

    private var coverURL: URL? {
        guard let value = gift.coverMedia?.publicUrl else { return nil }
        return URL(string: value)
    }

    var body: some View {
        Button(action: open) {
            VStack(spacing: 0) {
                visual
                copy
            }
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .stroke(Color(red: 1.0, green: 0.91, blue: 0.76).opacity(0.26), lineWidth: 0.8)
            }
            .shadow(color: Color(red: 0.31, green: 0.17, blue: 0.06).opacity(0.22), radius: 28, y: 15)
            .contentShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        }
        .buttonStyle(ASURamadanPressStyle(reduceMotion: reduceMotion))
        .accessibilityLabel("Ramadan Gift · \(gift.subtitle(language))")
    }

    private var visual: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.94, blue: 0.87),
                    Color(red: 0.91, green: 0.79, blue: 0.64)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [Color.white.opacity(0.78), Color.white.opacity(0)],
                center: .topTrailing,
                startRadius: 4,
                endRadius: 230
            )

            if let coverURL {
                ASURemoteImage(url: coverURL, contentMode: .fill, background: .clear, padding: 0)
                    .frame(maxWidth: .infinity)
                    .frame(height: 246)
                    .clipped()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 40, weight: .light))
                    Text(gift.subtitle(language))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Color.black.opacity(0.72))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            LinearGradient(
                colors: [.clear, Color(red: 0.18, green: 0.10, blue: 0.05).opacity(0.18)],
                startPoint: .center,
                endPoint: .bottom
            )

            HStack(spacing: 7) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .bold))
                Text("RAMADAN GIFT")
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .tracking(1.55)
            }
            .foregroundStyle(Color.white.opacity(0.92))
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(Color.black.opacity(0.38), in: Capsule())
            .padding(16)
        }
        .frame(height: 246)
        .clipped()
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(L10n.t(
                "Премиальный подарок\nкак знак уважения.",
                "Hurmat ramzi bo‘lgan\npremium sovg‘a.",
                language
            ))
            .font(.system(size: 31, weight: .bold, design: .rounded))
            .tracking(-1.05)
            .lineSpacing(-2)
            .foregroundStyle(.white)

            Text(L10n.t(
                "Один автомобиль. Один клиент. Благодарность за доверие Auto Sale Umar.",
                "Bitta avtomobil. Bitta mijoz. Auto Sale Umarga bo‘lgan ishonch uchun minnatdorchilik.",
                language
            ))
            .font(.system(size: 14.5, weight: .regular, design: .rounded))
            .foregroundStyle(.white.opacity(0.72))
            .lineSpacing(3.5)

            VStack(alignment: .leading, spacing: 5) {
                Text(gift.subtitle(language))
                    .font(.system(size: 18.5, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text(gift.shortPhrase(language))
                    .font(.system(size: 13.5, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 1.0, green: 0.89, blue: 0.74).opacity(0.88))
                    .lineLimit(2)
            }

            HStack(spacing: 10) {
                Text(gift.subtitle(language).uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.9)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 12)
                    .frame(height: 38)
                    .background(.white.opacity(0.09), in: Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.14), lineWidth: 0.6))

                Spacer(minLength: 6)

                HStack(spacing: 7) {
                    Text(L10n.t("Открыть", "Ochish", language))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                }
                .font(.system(size: 13.5, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
        }
        .padding(22)
        .background(Color(red: 0.14, green: 0.08, blue: 0.045).opacity(0.94))
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.13, green: 0.075, blue: 0.04),
                Color(red: 0.38, green: 0.22, blue: 0.11),
                Color(red: 0.66, green: 0.42, blue: 0.21)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct ASURamadanPressStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.986 : 1)
            .opacity(configuration.isPressed ? 0.96 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

struct ASUComparePromoCarousel: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: AppStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let openCompare: () -> Void

    @State private var page = 0
    @State private var pulse = false

    private var previewCars: [Car] {
        let preferred = store.cars.filter { $0.status.isAvailable && $0.primaryImageURL != nil }
        return Array((preferred.isEmpty ? store.cars : preferred).prefix(2))
    }

    var body: some View {
        VStack(spacing: 13) {
            TabView(selection: $page) {
                compareCard.tag(0)
                consultantCard.tag(1)
            }
            .frame(height: 620)
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 7) {
                ForEach(0..<2, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? Color.primary.opacity(0.82) : Color.secondary.opacity(0.24))
                        .frame(width: index == page ? 25 : 7, height: 7)
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: page)
        }
        .sensoryFeedback(.selection, trigger: page)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private var compareCard: some View {
        Button(action: openCompare) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 15) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left.arrow.right")
                        Text(L10n.t("СРАВНИТЕ ПЕРЕД ВЫБОРОМ", "TANLOVDAN OLDIN SOLISHTIRING", settings.language))
                    }
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .tracking(1.05)
                    .foregroundStyle(.white.opacity(0.52))

                    Text(L10n.t(
                        "Два автомобиля.\nОдин понятный выбор.",
                        "Ikki avtomobil.\nBitta tushunarli tanlov.",
                        settings.language
                    ))
                    .font(.system(size: 35, weight: .bold, design: .rounded))
                    .tracking(-1.25)
                    .lineSpacing(-3)
                    .foregroundStyle(.white)

                    Text(L10n.t(
                        "Цена, характеристики и комплектации конкретных автомобилей — рядом, без лишнего шума.",
                        "Aniq avtomobillarning narxi, xususiyatlari va komplektatsiyasi — yonma-yon, ortiqcha shovqinsiz.",
                        settings.language
                    ))
                    .font(.system(size: 14.5, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.66))
                    .lineSpacing(3.5)

                    actionPill(L10n.t("Сравнить автомобили", "Avtomobillarni solishtirish", settings.language), symbol: "arrow.left.arrow.right")
                }
                .padding(.horizontal, 22)
                .padding(.top, 27)

                Spacer(minLength: 22)
                comparisonVisual
                    .padding(.horizontal, 18)
                    .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(compareBackground)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 34, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 0.7))
            .shadow(color: .black.opacity(0.18), radius: 26, y: 14)
        }
        .buttonStyle(ASUPromoPressStyle(reduceMotion: reduceMotion))
    }

    private var comparisonVisual: some View {
        HStack(spacing: 8) {
            miniCar(previewCars.indices.contains(0) ? previewCars[0] : nil, index: "01")

            ZStack {
                Circle().fill(.white.opacity(0.10))
                Circle().stroke(.white.opacity(0.12), lineWidth: 0.7)
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .frame(width: 42, height: 42)

            miniCar(previewCars.indices.contains(1) ? previewCars[1] : nil, index: "02")
        }
        .frame(height: 215)
    }

    private func miniCar(_ car: Car?, index: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                if let car {
                    ASURemoteImage(url: car.primaryImageURL, contentMode: .fill, background: Color.white.opacity(0.06), padding: 0)
                } else {
                    LinearGradient(colors: [.white.opacity(0.12), .white.opacity(0.035)], startPoint: .topLeading, endPoint: .bottomTrailing)
                }

                Text(index)
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 9)
                    .frame(height: 26)
                    .background(.black.opacity(0.38), in: Capsule())
                    .padding(9)
            }
            .frame(height: 132)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(car?.brand.uppercased() ?? "AUTO SALE UMAR")
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .tracking(0.75)
                    .foregroundStyle(.white.opacity(0.48))
                    .lineLimit(1)
                Text(car?.model ?? L10n.t("Ваш выбор", "Sizning tanlovingiz", settings.language))
                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            .padding(11)
        }
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 23, style: .continuous).stroke(.white.opacity(0.10), lineWidth: 0.7))
    }

    private var consultantCard: some View {
        Button(action: openCompare) {
            ZStack {
                consultantBackground

                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(Color(red: 1.0, green: 0.48, blue: 0.20))
                            Text("AUTO SALE UMAR · SMART CONSULTANT")
                        }
                        .font(.system(size: 10.2, weight: .bold, design: .rounded))
                        .tracking(0.85)
                        .foregroundStyle(.white.opacity(0.56))

                        Text(L10n.t(
                            "Не ещё одна таблица.\nА понятный совет.",
                            "Yana bir jadval emas.\nAniq maslahat.",
                            settings.language
                        ))
                        .font(.system(size: 35, weight: .bold, design: .rounded))
                        .tracking(-1.3)
                        .lineSpacing(-3)
                        .foregroundStyle(.white)

                        Text(L10n.t(
                            "Скажите, что для вас важнее: комфорт, динамика, семья, технологии или бюджет. Консультант сопоставит выбранные автомобили.",
                            "Siz uchun nima muhimligini ayting: qulaylik, dinamika, oila, texnologiya yoki budjet. Maslahatchi tanlangan avtomobillarni solishtiradi.",
                            settings.language
                        ))
                        .font(.system(size: 14.5, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.68))
                        .lineSpacing(3.5)

                        actionPill(L10n.t("Получить совет", "Maslahat olish", settings.language), symbol: "sparkles")
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 27)

                    Spacer(minLength: 12)
                    consultantVisual
                        .padding(.bottom, 16)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 34, style: .continuous).stroke(Color(red: 1.0, green: 0.47, blue: 0.18).opacity(0.26), lineWidth: 0.8))
            .shadow(color: .black.opacity(0.22), radius: 28, y: 15)
        }
        .buttonStyle(ASUPromoPressStyle(reduceMotion: reduceMotion))
    }

    private var consultantVisual: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.10), lineWidth: 0.8)
                .frame(width: 210, height: 210)
            Circle()
                .stroke(Color(red: 1.0, green: 0.48, blue: 0.20).opacity(0.36), lineWidth: 0.9)
                .frame(width: 154, height: 154)

            Rectangle()
                .fill(LinearGradient(colors: [.clear, Color(red: 1.0, green: 0.47, blue: 0.18).opacity(0.70), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(width: 255, height: 1)
                .rotationEffect(.degrees(-24))

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.0, green: 0.64, blue: 0.39),
                                Color(red: 0.95, green: 0.35, blue: 0.08),
                                Color(red: 0.17, green: 0.05, blue: 0.02),
                                .black
                            ],
                            center: UnitPoint(x: 0.35, y: 0.28),
                            startRadius: 2,
                            endRadius: 70
                        )
                    )
                Circle().stroke(.white.opacity(0.22), lineWidth: 0.8)
                Image(systemName: "sparkles")
                    .font(.system(size: 31, weight: .medium))
                    .foregroundStyle(.white)
            }
            .frame(width: 94, height: 94)
            .shadow(color: Color(red: 1.0, green: 0.36, blue: 0.09).opacity(0.28), radius: 28)
            .scaleEffect(pulse ? 1.045 : 0.98)

            Text("01")
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.34))
                .offset(x: -128, y: -72)
            Text("02")
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.34))
                .offset(x: 128, y: 72)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
    }

    private func actionPill(_ title: String, symbol: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: symbol)
                .font(.system(size: 12.5, weight: .semibold))
            Text(title)
            Spacer(minLength: 6)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
        }
        .font(.system(size: 13.5, weight: .bold, design: .rounded))
        .foregroundStyle(.black)
        .padding(.horizontal, 17)
        .frame(height: 50)
        .background(Color(red: 0.97, green: 0.97, blue: 0.955), in: Capsule())
        .padding(.top, 5)
    }

    private var compareBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.095, green: 0.10, blue: 0.105), .black, Color(red: 0.065, green: 0.067, blue: 0.073)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(colors: [.white.opacity(0.16), .clear], center: .topTrailing, startRadius: 4, endRadius: 260)
        }
    }

    private var consultantBackground: some View {
        ZStack {
            LinearGradient(
                colors: [.black, Color(red: 0.085, green: 0.07, blue: 0.06), Color(red: 0.19, green: 0.07, blue: 0.025), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [Color(red: 1.0, green: 0.42, blue: 0.14).opacity(0.42), .clear],
                center: UnitPoint(x: 0.85, y: 0.18),
                startRadius: 8,
                endRadius: 250
            )
            RadialGradient(
                colors: [Color(red: 0.55, green: 0.18, blue: 0.04).opacity(0.35), .clear],
                center: UnitPoint(x: 0.70, y: 0.88),
                startRadius: 10,
                endRadius: 235
            )
        }
    }
}

private struct ASUPromoPressStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.987 : 1)
            .opacity(configuration.isPressed ? 0.965 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.14), value: configuration.isPressed)
    }
}
