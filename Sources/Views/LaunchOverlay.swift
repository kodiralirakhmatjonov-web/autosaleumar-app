import SwiftUI

struct LaunchOverlay: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("ASUHasSeenPremiumIntro") private var hasSeenPremiumIntro = false

    let onFinish: () -> Void

    @State private var didFinish = false
    @State private var reveal = false
    @State private var quickSweep = false

    private var introURL: URL? {
        Bundle.main.url(forResource: "intro", withExtension: "mp4")
    }

    var body: some View {
        ZStack {
            if !hasSeenPremiumIntro, let introURL, !reduceMotion {
                premiumVideo(url: introURL)
            } else {
                quickBrandSplash
            }
        }
        .ignoresSafeArea()
        .onAppear {
            guard !hasSeenPremiumIntro || reduceMotion || introURL == nil else {
                // Website source plays the full intro and provides an explicit Skip action.
                // A fallback timer protects startup if AVPlayer fails to report completion.
                DispatchQueue.main.asyncAfter(deadline: .now() + 15.5) { finish(markSeen: true) }
                return
            }

            reveal = true
            quickSweep = true
            let delay = reduceMotion ? 0.55 : 1.20
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { finish(markSeen: false) }
        }
    }

    private func premiumVideo(url: URL) -> some View {
        ZStack {
            Color.black

            Image("IntroPoster")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            ASUVideoSurface(
                url: url,
                isMuted: true,
                shouldPlay: true,
                loops: false,
                gravity: .resizeAspectFill,
                onEnded: { finish(markSeen: true) }
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [.black.opacity(0.28), .clear, .black.opacity(0.48)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                HStack {
                    Image("WordmarkWhite")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 184)
                    Spacer()

                    Button {
                        finish(markSeen: true)
                    } label: {
                        Text(L10n.t("Пропустить", "O‘tkazib yuborish", settings.language))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 15)
                            .frame(height: 42)
                            .modifier(LaunchGlassCapsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)

                Spacer()

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AUTO SALE UMAR")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(1.45)
                            .foregroundStyle(.white.opacity(0.67))
                        Text("TASHKENT")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                }
                .padding(22)
            }
        }
    }

    private var quickBrandSplash: some View {
        ZStack {
            Color(uiColor: .systemBackground)

            Circle()
                .fill(Color.primary.opacity(0.035))
                .frame(width: 320, height: 320)
                .scaleEffect(reveal ? 1 : 0.78)

            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                .frame(width: 230, height: 230)
                .scaleEffect(reveal ? 1 : 0.88)

            VStack(spacing: 22) {
                Image(colorScheme == .dark ? "WordmarkWhite" : "WordmarkBlack")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 222)
                    .opacity(reveal ? 1 : 0)
                    .scaleEffect(reveal ? 1 : 0.97)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.10))
                        .frame(width: 108, height: 3)
                    Capsule()
                        .fill(ASUDesign.orange)
                        .frame(width: quickSweep ? 108 : 16, height: 3)
                }

                Text("TASHKENT · DIGITAL SHOWROOM")
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .tracking(1.55)
                    .foregroundStyle(.secondary)
                    .opacity(reveal ? 1 : 0)
            }
        }
        .onAppear {
            if reduceMotion {
                reveal = true
                quickSweep = true
            } else {
                withAnimation(.easeOut(duration: 0.42)) { reveal = true }
                withAnimation(.easeInOut(duration: 0.78).delay(0.08)) { quickSweep = true }
            }
        }
    }

    private func finish(markSeen: Bool) {
        guard !didFinish else { return }
        didFinish = true
        if markSeen { hasSeenPremiumIntro = true }
        onFinish()
    }
}


private struct LaunchGlassCapsule: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: Capsule())
        } else {
            content
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 0.7))
        }
    }
}
