import SwiftUI

struct LaunchOverlay: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var reveal = false
    @State private var sweep = false

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            Circle().fill(Color.primary.opacity(0.035)).frame(width: 310, height: 310).scaleEffect(reveal ? 1 : 0.72).blur(radius: 1)
            Circle().stroke(Color.primary.opacity(0.08), lineWidth: 1).frame(width: 226, height: 226).scaleEffect(reveal ? 1 : 0.84)
            VStack(spacing: 24) {
                Image(scheme == .dark ? "WordmarkWhite" : "WordmarkBlack")
                    .resizable().scaledToFit().frame(width: 222)
                    .opacity(reveal ? 1 : 0).scaleEffect(reveal ? 1 : 0.96)
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.10)).frame(width: 108, height: 3)
                    Capsule().fill(ASUDesign.orange).frame(width: sweep ? 108 : 18, height: 3)
                }
                Text("TASHKENT · DIGITAL SHOWROOM").font(.system(size: 9.5, weight: .bold, design: .rounded)).tracking(1.6).foregroundStyle(.secondary).opacity(reveal ? 1 : 0)
            }
        }
        .onAppear {
            if reduceMotion { reveal = true; sweep = true } else {
                withAnimation(.easeOut(duration: 0.5)) { reveal = true }
                withAnimation(.easeInOut(duration: 0.9).delay(0.12)) { sweep = true }
            }
        }
    }
}
