import SwiftUI
import UIKit

@MainActor
private final class ASURemoteImageLoader: ObservableObject {
    enum State {
        case idle
        case loading
        case success(UIImage)
        case failed
    }

    private static let memoryCache: NSCache<NSURL, UIImage> = {
        let cache = NSCache<NSURL, UIImage>()
        cache.countLimit = 80
        cache.totalCostLimit = 96 * 1024 * 1024
        return cache
    }()

    @Published var state: State = .idle
    private var task: Task<Void, Never>?
    private var loadedURL: URL?

    func load(_ url: URL?) {
        guard loadedURL != url else { return }
        task?.cancel()
        loadedURL = url

        guard let url else {
            state = .failed
            return
        }

        if let image = Self.memoryCache.object(forKey: url as NSURL) {
            state = .success(image)
            return
        }

        state = .loading
        task = Task {
            var request = URLRequest(url: url)
            request.cachePolicy = .returnCacheDataElseLoad
            request.timeoutInterval = 20
            request.setValue("image/avif,image/webp,image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")
            request.setValue("AutoSaleUmar-iOS/4.0", forHTTPHeaderField: "User-Agent")

            if let cached = URLCache.shared.cachedResponse(for: request),
               let image = UIImage(data: cached.data) {
                guard !Task.isCancelled else { return }
                Self.memoryCache.setObject(image, forKey: url as NSURL, cost: cached.data.count)
                state = .success(image)
                return
            }

            for attempt in 0..<2 {
                do {
                    let (data, response) = try await URLSession.shared.data(for: request)
                    guard !Task.isCancelled else { return }
                    guard let http = response as? HTTPURLResponse,
                          (200..<300).contains(http.statusCode),
                          !data.isEmpty,
                          let image = UIImage(data: data) else {
                        if attempt == 0 {
                            try? await Task.sleep(for: .milliseconds(450))
                            continue
                        }
                        state = .failed
                        return
                    }

                    let cached = CachedURLResponse(response: response, data: data)
                    URLCache.shared.storeCachedResponse(cached, for: request)
                    Self.memoryCache.setObject(image, forKey: url as NSURL, cost: data.count)
                    state = .success(image)
                    return
                } catch {
                    guard !Task.isCancelled else { return }
                    if attempt == 0 {
                        try? await Task.sleep(for: .milliseconds(450))
                    } else {
                        state = .failed
                    }
                }
            }
        }
    }

    deinit { task?.cancel() }
}

struct ASURemoteImage: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let url: URL?
    var contentMode: ContentMode = .fit
    var background: Color = ASUDesign.gallery
    var padding: CGFloat = 0

    @StateObject private var loader = ASURemoteImageLoader()

    var body: some View {
        ZStack {
            background

            switch loader.state {
            case .idle, .loading:
                ASUImageSkeleton()
            case .success(let image):
                rendered(image)
            case .failed:
                VStack(spacing: 8) {
                    Image(systemName: "car.side")
                        .font(.system(size: 46, weight: .light))
                    Text("Auto Sale Umar")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .tracking(0.5)
                }
                .foregroundStyle(.tertiary)
            }
        }
        .task(id: url) { loader.load(url) }
    }

    @ViewBuilder
    private func rendered(_ image: UIImage) -> some View {
        let content = Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: contentMode)
            .padding(padding)

        if reduceMotion {
            content
        } else {
            content.transition(.opacity.animation(.easeOut(duration: ASUDesign.navigationDuration)))
        }
    }
}

struct ASUImageSkeleton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ASUDesign.gallery

                if !reduceMotion {
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.14), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: proxy.size.width * 0.75)
                    .offset(x: phase * proxy.size.width)
                }
            }
            .clipped()
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 1.25).repeatForever(autoreverses: false)) {
                phase = 1.7
            }
        }
    }
}
