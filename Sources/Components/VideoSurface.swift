import SwiftUI
import AVFoundation
import UIKit

struct ASUVideoSurface: UIViewRepresentable {
    let url: URL
    var isMuted: Bool = true
    var shouldPlay: Bool = true
    var loops: Bool = true
    var gravity: AVLayerVideoGravity = .resizeAspectFill
    var onEnded: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(onEnded: onEnded)
    }

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.playerLayer.videoGravity = gravity
        context.coordinator.configure(url: url, loops: loops, playerLayer: view.playerLayer)
        context.coordinator.player?.isMuted = isMuted
        if shouldPlay { context.coordinator.player?.play() }
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.playerLayer.videoGravity = gravity
        context.coordinator.onEnded = onEnded

        if context.coordinator.currentURL != url || context.coordinator.loops != loops {
            context.coordinator.configure(url: url, loops: loops, playerLayer: uiView.playerLayer)
        }

        context.coordinator.player?.isMuted = isMuted
        if shouldPlay {
            context.coordinator.player?.play()
        } else {
            context.coordinator.player?.pause()
        }
    }

    static func dismantleUIView(_ uiView: PlayerView, coordinator: Coordinator) {
        coordinator.teardown()
        uiView.playerLayer.player = nil
    }

    final class PlayerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }

    final class Coordinator: NSObject {
        var player: AVPlayer?
        var currentURL: URL?
        var loops = true
        var onEnded: (() -> Void)?
        private var endObserver: NSObjectProtocol?

        init(onEnded: (() -> Void)?) {
            self.onEnded = onEnded
        }

        func configure(url: URL, loops: Bool, playerLayer: AVPlayerLayer) {
            teardown()
            currentURL = url
            self.loops = loops

            let item = AVPlayerItem(url: url)
            let player = AVPlayer(playerItem: item)
            player.actionAtItemEnd = .pause
            playerLayer.player = player
            self.player = player

            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                if self.loops {
                    self.player?.seek(to: .zero)
                    self.player?.play()
                } else {
                    self.onEnded?()
                }
            }
        }

        func teardown() {
            player?.pause()
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
            }
            endObserver = nil
            player = nil
            currentURL = nil
        }

        deinit {
            teardown()
        }
    }
}
