import SwiftUI
import UIKit

enum ASUDesign {
    static let page = Color(uiColor: .systemBackground)
    static let surface = Color(uiColor: .secondarySystemBackground)
    static let elevated = Color(uiColor: .secondarySystemGroupedBackground)
    static let gallery = Color(uiColor: .secondarySystemBackground)
    static let soft = Color.primary.opacity(0.055)
    static let line = Color.primary.opacity(0.085)
    static let lineStrong = Color.primary.opacity(0.16)
    static let orange = Color(red: 0.957, green: 0.467, blue: 0.180)
    static let success = Color(red: 0.251, green: 0.588, blue: 0.420)
    static let pagePadding: CGFloat = 18
    static let corner: CGFloat = 30
    static let sectionSpacing: CGFloat = 56

    static let microDuration = 0.12
    static let navigationDuration = 0.22
    static let storyDuration = 0.36

    static let spring = Animation.spring(response: 0.40, dampingFraction: 0.84, blendDuration: 0.08)
    static let softSpring = Animation.spring(response: 0.50, dampingFraction: 0.88, blendDuration: 0.08)
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
            .shadow(color: shadow ? .black.opacity(0.05) : .clear, radius: 18, y: 8)
    }
}

struct ASUPrimaryButtonStyle: ButtonStyle {
    var prominent: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(prominent ? Color(uiColor: .systemBackground) : Color.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                prominent ? AnyShapeStyle(Color.primary) : AnyShapeStyle(ASUDesign.soft),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay {
                if !prominent {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(ASUDesign.line, lineWidth: 0.7)
                }
            }
            .scaleEffect(configuration.isPressed ? 0.982 : 1)
            .opacity(configuration.isPressed ? 0.90 : 1)
            .animation(.easeOut(duration: ASUDesign.microDuration), value: configuration.isPressed)
    }
}

struct ASUSectionTitleStyle: ViewModifier {
    var size: CGFloat = 36

    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: .bold, design: .rounded))
            .tracking(-size * 0.027)
            .lineSpacing(-2)
    }
}

extension View {
    func asuCard(radius: CGFloat = ASUDesign.corner, shadow: Bool = true) -> some View {
        modifier(ASUCardModifier(radius: radius, shadow: shadow))
    }

    func asuPageTitle() -> some View {
        modifier(ASUSectionTitleStyle(size: 36))
    }

    func asuSectionTitle(size: CGFloat = 36) -> some View {
        modifier(ASUSectionTitleStyle(size: size))
    }

    @ViewBuilder
    func asuStoryTransition(axis: Axis = .vertical) -> some View {
        if #available(iOS 17.0, *) {
            self.scrollTransition(.interactive, axis: axis) { content, phase in
                content
                    .opacity(phase.isIdentity ? 1 : 0.72)
                    .scaleEffect(phase.isIdentity ? 1 : 0.965)
            }
        } else {
            self
        }
    }
}

extension Color {
    init(asuHex: String?, fallback: Color = .primary) {
        guard let asuHex, !asuHex.isEmpty else {
            self = fallback
            return
        }
        let value = asuHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var integer: UInt64 = 0
        guard Scanner(string: value).scanHexInt64(&integer) else {
            self = fallback
            return
        }
        switch value.count {
        case 6:
            self.init(
                red: Double((integer >> 16) & 0xff) / 255,
                green: Double((integer >> 8) & 0xff) / 255,
                blue: Double(integer & 0xff) / 255
            )
        case 8:
            self.init(
                red: Double((integer >> 24) & 0xff) / 255,
                green: Double((integer >> 16) & 0xff) / 255,
                blue: Double((integer >> 8) & 0xff) / 255,
                opacity: Double(integer & 0xff) / 255
            )
        default:
            self = fallback
        }
    }
}
