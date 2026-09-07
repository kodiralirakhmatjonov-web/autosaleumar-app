import SwiftUI
import UIKit
import ImageIO
import Foundation

struct ASUCarShareButton<Label: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let car: Car
    let language: AppLanguage
    private let label: Label

    @State private var preparedImage: UIImage?
    @State private var isPreparing = false
    @State private var showShare = false
    @State private var shareItems: [Any] = []
    @State private var feedbackToken = 0

    init(car: Car, language: AppLanguage, @ViewBuilder label: () -> Label) {
        self.car = car
        self.language = language
        self.label = label()
    }

    var body: some View {
        Button {
            Task { await presentShare() }
        } label: {
            ZStack {
                label
                    .opacity(isPreparing ? 0.45 : 1)
                if isPreparing {
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isPreparing)
        .task(id: warmKey) {
            preparedImage = await ASUCarShareImageLoader.shared.image(for: car.primaryImageURL)
        }
        .sheet(isPresented: $showShare) {
            ASUActivityView(items: shareItems)
                .presentationDetents([.large])
        }
        .sensoryFeedback(.impact(weight: .light), trigger: feedbackToken)
        .accessibilityLabel(L10n.t("Поделиться автомобилем", "Avtomobilni ulashish", language))
    }

    private var warmKey: String {
        "\(car.id)|\(car.primaryImageURL?.absoluteString ?? "none")"
    }

    @MainActor
    private func presentShare() async {
        guard !isPreparing else { return }
        isPreparing = true
        defer { isPreparing = false }

        let image: UIImage?
        if let preparedImage {
            image = preparedImage
        } else {
            let loadedImage = await ASUCarShareImageLoader.shared.image(for: car.primaryImageURL)
            preparedImage = loadedImage
            image = loadedImage
        }

        let title = car.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = AppConfig.carShareURL(car)
        let details = [
            car.year.map(String.init),
            car.trim?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty
        ]
        .compactMap { $0 }
        .joined(separator: " · ")

        let caption = [
            title,
            details.isEmpty ? nil : details,
            Format.price(car, language: language),
            "Auto Sale Umar",
            url.absoluteString
        ]
        .compactMap { $0 }
        .joined(separator: "\n")

        if let image {
            shareItems = [image, caption]
        } else {
            shareItems = [caption, url]
        }
        feedbackToken += 1
        showShare = true
    }
}

private final class ASUCarShareImageLoader {
    static let shared = ASUCarShareImageLoader()
    private let cache = NSCache<NSURL, UIImage>()

    private init() {
        cache.countLimit = 28
        cache.totalCostLimit = 96 * 1024 * 1024
    }

    func image(for url: URL?) async -> UIImage? {
        guard let url else { return nil }
        if let cached = cache.object(forKey: url as NSURL) { return cached }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 18
            request.cachePolicy = .returnCacheDataElseLoad
            request.setValue("image/avif,image/webp,image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")
            request.setValue("AutoSaleUmar-iOS/3.0", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }
            guard let image = downsample(data: data, maxPixel: 1800) else { return nil }
            cache.setObject(image, forKey: url as NSURL, cost: imageCost(image))
            return image
        } catch {
            return nil
        }
    }

    private func downsample(data: Data, maxPixel: Int) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return UIImage(data: data)
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return UIImage(data: data)
        }
        return UIImage(cgImage: cgImage)
    }

    private func imageCost(_ image: UIImage) -> Int {
        let width = Int(image.size.width * image.scale)
        let height = Int(image.size.height * image.scale)
        return max(1, width * height * 4)
    }
}

private struct ASUActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
