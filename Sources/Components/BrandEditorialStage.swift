import SwiftUI

struct ASUBrandEditorialStage: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let brand: String
    let brandAsset: String?
    let covers: [ASUBrandCoverItem]
    let fallbackPhotoURL: URL?

    @State private var selectedIndex = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            if covers.isEmpty {
                fallbackStage
            } else {
                TabView(selection: $selectedIndex) {
                    ForEach(Array(covers.enumerated()), id: \.element.id) { index, cover in
                        ASURemoteImage(url: cover.url, contentMode: .fill, background: .black)
                            .overlay(stageShade)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }

            VStack(spacing: 12) {
                Spacer()
                brandIdentity
                if covers.count > 1 { pageDots }
            }
            .padding(.bottom, 24)
        }
        .frame(height: 300)
        .clipped()
        .background(Color.black)
        .task(id: covers.count) {
            guard covers.count > 1, !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_600_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        selectedIndex = (selectedIndex + 1) % covers.count
                    }
                }
            }
        }
        .onChange(of: covers.count) { _, count in
            guard count > 0, selectedIndex >= count else { return }
            selectedIndex = 0
        }
    }

    private var fallbackStage: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.06, green: 0.06, blue: 0.065)],
                startPoint: .top,
                endPoint: .bottom
            )

            if let fallbackPhotoURL {
                ASURemoteImage(url: fallbackPhotoURL, contentMode: .fill, background: .black)
                    .opacity(0.48)
                    .overlay(stageShade)
            }
        }
    }

    private var stageShade: some View {
        LinearGradient(
            colors: [.black.opacity(0.20), .clear, .black.opacity(0.58)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var brandIdentity: some View {
        VStack(spacing: 9) {
            if let brandAsset {
                Image(brandAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 176, maxHeight: 64)
                    .grayscale(1)
                    .colorInvert()
                    .blendMode(.screen)
            } else {
                Text(brand.uppercased())
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }

            Text("AUTO SALE UMAR · \(brand.uppercased())")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(1.85)
                .foregroundStyle(.white.opacity(0.76))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .shadow(color: .black.opacity(0.32), radius: 18, y: 8)
    }

    private var pageDots: some View {
        HStack(spacing: 5) {
            ForEach(covers.indices, id: \.self) { index in
                Capsule()
                    .fill(Color.white.opacity(index == selectedIndex ? 0.96 : 0.40))
                    .frame(width: index == selectedIndex ? 18 : 5, height: 5)
            }
        }
        .padding(.horizontal, 9)
        .frame(height: 24)
        .background(.black.opacity(0.22), in: Capsule())
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: selectedIndex)
    }
}
