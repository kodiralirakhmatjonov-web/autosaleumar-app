import SwiftUI
import UIKit

enum ASUDesign {
    static let page = Color(uiColor: .systemBackground)
    static let elevated = Color(uiColor: .secondarySystemBackground)
    static let soft = Color(uiColor: .systemGray6)
    static let line = Color.primary.opacity(0.075)
    static let muted = Color.secondary
    static let orange = Color(red: 1.0, green: 0.34, blue: 0.04)
    static let corner: CGFloat = 28
    static let smallCorner: CGFloat = 18
    static let pagePadding: CGFloat = 18
}

struct ASUCardModifier: ViewModifier {
    var radius: CGFloat = ASUDesign.corner
    var shadow: Bool = true
    func body(content: Content) -> some View {
        content
            .background(ASUDesign.elevated)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.75))
            .shadow(color: shadow ? .black.opacity(0.055) : .clear, radius: 18, y: 8)
    }
}

extension View {
    func asuCard(radius: CGFloat = ASUDesign.corner, shadow: Bool = true) -> some View { modifier(ASUCardModifier(radius: radius, shadow: shadow)) }
    func asuPageTitle() -> some View { font(.system(size: 34, weight: .bold, design: .rounded)).tracking(-1.0) }
}

struct ASUPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(Color(uiColor: .systemBackground))
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Color.primary.opacity(configuration.isPressed ? 0.76 : 0.96), in: RoundedRectangle(cornerRadius: 19, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}
