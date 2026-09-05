import Foundation
import UIKit

enum ASURuntime {
    private static var didConfigure = false

    static func configure() {
        guard !didConfigure else { return }
        didConfigure = true

        let memoryCapacity = 96 * 1024 * 1024
        let diskCapacity = 512 * 1024 * 1024
        URLCache.shared = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: "com.autosaleumar.image-cache")
    }
}

enum ASUHaptics {
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    static func impact() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred()
    }

    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
}

enum ASUImagePrefetcher {
    static func prefetch(_ urls: [URL]) {
        var seen = Set<URL>()
        let unique = Array(urls.filter { seen.insert($0).inserted }.prefix(12))
        guard !unique.isEmpty else { return }

        Task.detached(priority: .utility) {
            await withTaskGroup(of: Void.self) { group in
                for url in unique {
                    group.addTask {
                        var request = URLRequest(url: url)
                        request.cachePolicy = .returnCacheDataElseLoad
                        request.timeoutInterval = 15
                        request.setValue("image/avif,image/webp,image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")
                        request.setValue("AutoSaleUmar-iOS/4.0", forHTTPHeaderField: "User-Agent")

                        if URLCache.shared.cachedResponse(for: request) != nil { return }

                        do {
                            let (data, response) = try await URLSession.shared.data(for: request)
                            guard let http = response as? HTTPURLResponse,
                                  (200..<300).contains(http.statusCode),
                                  !data.isEmpty else { return }
                            URLCache.shared.storeCachedResponse(CachedURLResponse(response: response, data: data), for: request)
                        } catch {
                            // Prefetch is opportunistic; foreground image loading remains authoritative.
                        }
                    }
                }
            }
        }
    }
}
