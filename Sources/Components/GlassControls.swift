import SwiftUI

struct ASUGlassContainer<Content: View>: View {
    var spacing: CGFloat? = 12
    let content: Content

    init(spacing: CGFloat? = 12, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    @ViewBuilder
    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content
            }
        } else {
            content
        }
    }
}


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
                .modifier(ASUGlassCircle(interactive: true))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel ?? symbol)
    }
}

struct ASUGlassCircleSurface<Content: View>: View {
    var size: CGFloat = 46
    let content: Content

    init(size: CGFloat = 46, @ViewBuilder content: () -> Content) {
        self.size = size
        self.content = content()
    }

    var body: some View {
        content
            .frame(width: size, height: size)
            .modifier(ASUGlassCircle(interactive: false))
    }
}

private struct ASUGlassCircle: ViewModifier {
    let interactive: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if interactive {
                content.glassEffect(.regular.interactive(), in: Circle())
            } else {
                content.glassEffect(.regular, in: Circle())
            }
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

struct ASUGlassPanel<Content: View>: View {
    var radius: CGFloat = 30
    var padding: CGFloat = 0
    let content: Content

    init(radius: CGFloat = 30, padding: CGFloat = 0, @ViewBuilder content: () -> Content) {
        self.radius = radius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .modifier(ASUGlassRounded(radius: radius, interactive: false))
    }
}

struct ASUGlassPillButton<Label: View>: View {
    var isSelected = false
    let action: () -> Void
    let label: Label

    init(isSelected: Bool = false, action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.isSelected = isSelected
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button(action: action) {
            label
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? Color(uiColor: .systemBackground) : Color.primary)
                .padding(.horizontal, 16)
                .frame(height: 42)
                .modifier(ASUGlassCapsule(selected: isSelected))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct ASUGlassProminentPillButton<Label: View>: View {
    let action: () -> Void
    let label: Label

    init(action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button(action: action) {
            label
                .foregroundStyle(Color(uiColor: .systemBackground))
                .modifier(ASUGlassProminentCapsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct ASUGlassCapsule: ViewModifier {
    let selected: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if selected {
                content.glassEffect(.regular.tint(Color.primary).interactive(), in: Capsule())
            } else {
                content.glassEffect(.regular.interactive(), in: Capsule())
            }
        } else {
            if selected {
                content.background(Color.primary, in: Capsule())
            } else {
                content
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.20), lineWidth: 0.7))
                    .shadow(color: .black.opacity(0.06), radius: 12, y: 5)
            }
        }
    }
}

private struct ASUGlassProminentCapsule: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.tint(Color.primary).interactive(), in: Capsule())
        } else {
            content.background(Color.primary, in: Capsule())
        }
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
