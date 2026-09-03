import SwiftUI
import UIKit

enum ASUDesign {
    static let page = Color(uiColor: .systemBackground)
    static let gallery = Color(uiColor: .secondarySystemBackground)
    static let elevated = Color(uiColor: .secondarySystemGroupedBackground)
    static let soft = Color.primary.opacity(0.055)
    static let line = Color.primary.opacity(0.075)
    static let orange = Color(red: 1.0, green: 0.353, blue: 0.122)
    static let pagePadding: CGFloat = 18
    static let corner: CGFloat = 28
}

struct ASUCardModifier: ViewModifier {
    var radius: CGFloat = ASUDesign.corner
    var shadow: Bool = true

    func body(content: Content) -> some View {
        content
            .background(ASUDesign.elevated)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(ASUDesign.line, lineWidth: 0.7)
            )
            .shadow(color: shadow ? .black.opacity(0.045) : .clear, radius: 18, y: 8)
    }
}

struct ASUPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(Color(uiColor: .systemBackground))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.primary, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

extension View {
    func asuCard(radius: CGFloat = ASUDesign.corner, shadow: Bool = true) -> some View {
        modifier(ASUCardModifier(radius: radius, shadow: shadow))
    }

    func asuPageTitle() -> some View {
        self
            .font(.system(size: 36, weight: .bold, design: .rounded))
            .tracking(-1.05)
    }
}
