import SwiftUI

struct ASUGlassIconButton: View {
    let symbol: String
    var size: CGFloat = 46
    var fontSize: CGFloat = 17
    var accessibilityLabel: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: fontSize, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .frame(width: size, height: size)
                .contentShape(Circle())
                .modifier(ASUGlassCircle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel ?? symbol)
    }
}

private struct ASUGlassCircle: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: Circle())
        } else {
            content
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.22), lineWidth: 0.7))
                .shadow(color: .black.opacity(0.08), radius: 14, y: 6)
        }
    }
}

struct ASUGlassSearchField: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .modifier(ASUGlassRounded(radius: 19, interactive: true))
    }
}

struct ASUGlassActionTile<Label: View>: View {
    let action: () -> Void
    let label: Label

    init(action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button(action: action) {
            label
                .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .modifier(ASUGlassRounded(radius: 22, interactive: true))
        }
        .buttonStyle(.plain)
    }
}

struct ASUGlassSurface<Content: View>: View {
    var radius: CGFloat = 22
    let content: Content

    init(radius: CGFloat = 22, @ViewBuilder content: () -> Content) {
        self.radius = radius
        self.content = content()
    }

    var body: some View {
        content.modifier(ASUGlassRounded(radius: radius, interactive: false))
    }
}

private struct ASUGlassRounded: ViewModifier {
    let radius: CGFloat
    let interactive: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if interactive {
                content.glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            } else {
                content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            }
        } else {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .stroke(Color.white.opacity(0.20), lineWidth: 0.7)
                )
                .shadow(color: .black.opacity(0.07), radius: 14, y: 6)
        }
    }
}
