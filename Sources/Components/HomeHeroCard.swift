import SwiftUI

struct ASUHomeHeroSlide: Identifiable, Hashable {
    enum Source: Hashable {
        case builtIn(URL)
        case remote(ASUHomeMediaItem)
    }

    let id: String
    let source: Source

    static func builtIn(_ url: URL) -> ASUHomeHeroSlide {
        ASUHomeHeroSlide(id: "built-in-intro", source: .builtIn(url))
    }

    static func remote(_ item: ASUHomeMediaItem) -> ASUHomeHeroSlide {
        ASUHomeHeroSlide(id: item.key, source: .remote(item))
    }

    var videoURL: URL {
        switch source {
        case .builtIn(let url):
            return url
        case .remote(let item):
            return item.url
        }
    }

    var brand: String {
        switch source {
        case .builtIn:
            return "AUTO SALE UMAR"
        case .remote(let item):
            return item.brand
        }
    }

    func model(_ language: AppLanguage) -> String {
        switch source {
        case .builtIn:
            return L10n.t("Премиальный шоурум", "Premium shourum", language)
        case .remote(let item):
            return item.model
        }
    }

    func price(_ language: AppLanguage) -> String {
        switch source {
        case .builtIn:
            return L10n.t("Цена по запросу", "Narx so‘rov bo‘yicha", language)
        case .remote(let item):
            guard !item.priceOnRequest, let price = item.price else {
                return L10n.t("Цена по запросу", "Narx so‘rov bo‘yicha", language)
            }
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            formatter.groupingSeparator = " "
            let value = formatter.string(from: NSNumber(value: price)) ?? String(price)
            switch item.currency {
            case .USD: return "\(value) $"
            case .EUR: return "\(value) €"
            case .UZS: return "\(value) \(L10n.t("сум", "so‘m", language))"
            }
        }
    }

    var status: CarStatus {
        switch source {
        case .builtIn:
            return .inShowroom
        case .remote(let item):
            return item.status
        }
    }

    var hasPoster: Bool {
        if case .builtIn = source { return true }
        return false
    }
}

struct ASUHomeHeroCard: View {
    let slide: ASUHomeHeroSlide
    let index: Int
    let total: Int
    @Binding var selectedIndex: Int
    @Binding var isMuted: Bool
    let language: AppLanguage
    let reduceMotion: Bool
    let advance: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            videoStage
            caption
        }
        .background(ASUDesign.elevated)
    }

    private var videoStage: some View {
        ZStack(alignment: .bottom) {
            Color.black

            if slide.hasPoster {
                Image("IntroPoster")
                    .resizable()
                    .scaledToFill()
            }

            ASUVideoSurface(
                url: slide.videoURL,
                isMuted: isMuted,
                shouldPlay: selectedIndex == index,
                loops: total <= 1,
                gravity: .resizeAspectFill,
                onEnded: selectedIndex == index ? advance : nil
            )

            LinearGradient(
                colors: [.black.opacity(0.18), .clear, .black.opacity(0.44)],
                startPoint: .top,
                endPoint: .bottom
            )

            HStack(alignment: .bottom) {
                heroDots
                Spacer(minLength: 12)
                soundButton
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 350)
        .clipped()
    }

    private var heroDots: some View {
        HStack(spacing: 5) {
            ForEach(0..<total, id: \.self) { dot in
                Capsule()
                    .fill(Color.white.opacity(dot == selectedIndex ? 0.96 : 0.42))
                    .frame(width: dot == selectedIndex ? 18 : 5, height: 5)
            }
        }
        .padding(.horizontal, 9)
        .frame(height: 24)
        .background(.black.opacity(0.24), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 0.5))
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: selectedIndex)
    }

    private var soundButton: some View {
        Button {
            ASUHaptics.selection()
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) {
                isMuted.toggle()
            }
        } label: {
            Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.black.opacity(0.28), in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 0.6))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isMuted ? "Sound on" : "Sound off")
    }

    private var caption: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text(slide.brand.uppercased())
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .tracking(1.25)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(slide.model(language))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .tracking(-0.55)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 7) {
                Text(slide.price(language))
                    .font(.system(size: 16.5, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                StatusPill(status: slide.status, language: language, compact: true)
            }
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity)
        .frame(height: 112)
    }
}
