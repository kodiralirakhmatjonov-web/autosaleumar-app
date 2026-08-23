import SwiftUI
import UIKit

enum ASUDesign {
    static let page = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
    static let line = Color.primary.opacity(0.07)
    static let muted = Color.secondary
    static let corner: CGFloat = 24
}

struct ASUCardModifier: ViewModifier {
    var radius: CGFloat = ASUDesign.corner

    func body(content: Content) -> some View {
        content
            .background(ASUDesign.card)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(ASUDesign.line, lineWidth: 0.75)
            )
    }
}

extension View {
    func asuCard(radius: CGFloat = ASUDesign.corner) -> some View {
        modifier(ASUCardModifier(radius: radius))
    }
}
