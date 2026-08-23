import SwiftUI

enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case home
    case cars
    case visit
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Главная"
        case .cars: return "Автомобили"
        case .visit: return "Визит"
        case .settings: return "Настройки"
        }
    }

    var symbol: String {
        switch self {
        case .home: return "house.fill"
        case .cars: return "car.side.fill"
        case .visit: return "mappin.and.ellipse"
        case .settings: return "gearshape.fill"
        }
    }

    var path: String? {
        switch self {
        case .home: return "/"
        case .cars: return "/cars/"
        case .visit: return "/booking/"
        case .settings: return nil
        }
    }
}

struct LiquidGlassTabBar: View {
    @Binding var selection: AppTab
    @Namespace private var selectionNamespace

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                modernBar
            } else {
                fallbackBar
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .sensoryFeedback(.selection, trigger: selection)
    }

    @available(iOS 26.0, *)
    private var modernBar: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(AppTab.allCases) { tab in
                    tabButton(tab, modern: true)
                }
            }
            .padding(5)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 32))
        }
    }

    private var fallbackBar: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                tabButton(tab, modern: false)
            }
        }
        .padding(5)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 0.75)
        )
        .shadow(color: .black.opacity(0.14), radius: 24, y: 10)
    }

    @ViewBuilder
    private func tabButton(_ tab: AppTab, modern: Bool) -> some View {
        Button {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                selection = tab
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                Text(tab.title)
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .foregroundStyle(selection == tab ? Color.primary : Color.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .contentShape(Rectangle())
            .background {
                if selection == tab {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.primary.opacity(modern ? 0.075 : 0.065))
                        .matchedGeometryEffect(id: "selected-tab", in: selectionNamespace)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(selection == tab ? [.isSelected] : [])
    }
}
