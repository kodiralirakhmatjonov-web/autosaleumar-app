import SwiftUI

struct StatusPill: View {
    let status: CarStatus
    let language: AppLanguage
    var compact = false
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(dotColor).frame(width: compact ? 6 : 7, height: compact ? 6 : 7)
            Text(status.title(language)).font(.system(size: compact ? 11 : 12.5, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, compact ? 9 : 11).padding(.vertical, compact ? 6 : 7)
        .background(.thinMaterial, in: Capsule())
        .overlay(Capsule().stroke(ASUDesign.line, lineWidth: 0.7))
    }
    private var dotColor: Color {
        switch status { case .inStock, .inShowroom: return ASUDesign.orange; case .inTransit: return .secondary; case .reserved: return .yellow; case .sold: return .secondary; default: return .secondary }
    }
}
