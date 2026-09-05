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

        state = .loading
        task = Task {
            var request = URLRequest(url: url)
            request.cachePolicy = .returnCacheDataElseLoad
            request.timeoutInterval = 20
            request.setValue("image/avif,image/webp,image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")
            request.setValue("AutoSaleUmar-iOS/2.0", forHTTPHeaderField: "User-Agent")

            if let cached = URLCache.shared.cachedResponse(for: request), let image = UIImage(data: cached.data) {
                guard !Task.isCancelled else { return }
                state = .success(image)
                return
            }

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard !Task.isCancelled else { return }
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode), let image = UIImage(data: data) else {
                    state = .failed
                    return
                }
                URLCache.shared.storeCachedResponse(CachedURLResponse(response: response, data: data), for: request)
                state = .success(image)
            } catch {
                guard !Task.isCancelled else { return }
                state = .failed
            }
        }
    }

    deinit { task?.cancel() }
}

struct ASURemoteImage: View {
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
                ProgressView()
                    .controlSize(.small)
                    .tint(.secondary)
            case .success(let image):
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .padding(padding)
                    .transition(.opacity.animation(.easeOut(duration: ASUDesign.navigationDuration)))
            case .failed:
                Image(systemName: "car.side")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(.tertiary)
            }
        }
        .task(id: url) { loader.load(url) }
    }
}

struct ASUImageSkeleton: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ASUDesign.gallery
                LinearGradient(
                    colors: [.clear, Color.white.opacity(0.14), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: proxy.size.width * 0.75)
                .offset(x: phase * proxy.size.width)
            }
            .clipped()
        }
        .onAppear {
            withAnimation(.linear(duration: 1.25).repeatForever(autoreverses: false)) { phase = 1.7 }
        }
    }
}
