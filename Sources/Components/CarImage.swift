import SwiftUI

struct CarImage: View {
    let url: URL?
    var height: CGFloat = 190
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.primary.opacity(0.025), Color.primary.opacity(0.085)], startPoint: .topLeading, endPoint: .bottomTrailing)
            if let url {
                AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.25))) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFit().padding(4).transition(.opacity)
                    case .failure: placeholder
                    case .empty: ProgressView().controlSize(.small)
                    @unknown default: placeholder
                    }
                }
            } else { placeholder }
        }
        .frame(maxWidth: .infinity).frame(height: height)
        .clipped()
    }
    private var placeholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "car.side.fill").font(.system(size: 44, weight: .light)).foregroundStyle(.tertiary)
            Text("AUTO SALE UMAR").font(.system(size: 10, weight: .bold, design: .rounded)).tracking(1.2).foregroundStyle(.tertiary)
        }
    }
}
