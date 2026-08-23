import SwiftUI

struct LaunchOverlay: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var expanded = false

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            VStack(spacing: 18) {
                Image(colorScheme == .dark ? "WordmarkWhite" : "WordmarkBlack")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 205)
                    .opacity(expanded ? 1 : 0.72)
                    .scaleEffect(expanded ? 1 : 0.96)

                Capsule()
                    .fill(Color.primary.opacity(0.82))
                    .frame(width: expanded ? 82 : 24, height: 3)
                    .animation(.easeInOut(duration: 0.72), value: expanded)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.42)) {
                expanded = true
            }
        }
    }
}
