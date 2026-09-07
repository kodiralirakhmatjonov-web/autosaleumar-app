import SwiftUI

struct LaunchOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let onFinish: () -> Void

    @State private var didFinish = false
    @State private var didStart = false
    @State private var revealLogo = false
    @State private var revealAccent = false
    @State private var imageScale: CGFloat = 1.045

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black
                    .ignoresSafeArea()

                Image("PremiumSplashBentley")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .scaleEffect(imageScale)
                    .clipped()
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [
                        .black.opacity(0.04),
                        .clear,
                        .black.opacity(0.12),
                        .black.opacity(0.32)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: 14) {
                        Image("WordmarkWhite")
                            .resizable()
                            .scaledToFit()
                            .frame(width: min(proxy.size.width * 0.58, 240))
                            .opacity(revealLogo ? 1 : 0)
                            .scaleEffect(revealLogo ? 1 : 0.965)
                            .offset(y: revealLogo ? 0 : 10)

                        Capsule()
                            .fill(Color.white.opacity(0.72))
                            .frame(width: revealAccent ? 54 : 10, height: 1)
                            .opacity(revealAccent ? 1 : 0)
                    }
                    .frame(height: max(190, proxy.size.height * 0.27), alignment: .top)
                    .padding(.top, 22)
                }
                .padding(.bottom, proxy.safeAreaInsets.bottom)
            }
        }
        .ignoresSafeArea()
        .onAppear(perform: start)
    }

    private func start() {
        guard !didStart else { return }
        didStart = true

        if reduceMotion {
            imageScale = 1
            revealLogo = true
            revealAccent = true
            ASUHaptics.impact()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.20) { finish() }
            return
        }

        withAnimation(.easeOut(duration: 2.25)) {
            imageScale = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            ASUHaptics.impact()
            withAnimation(.spring(response: 0.68, dampingFraction: 0.88)) {
                revealLogo = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.62) {
            withAnimation(.easeOut(duration: 0.72)) {
                revealAccent = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.30) {
            finish()
        }
    }

    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        onFinish()
    }
}
