import SwiftUI

enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case home, catalog, favorites, more
    var id: String { rawValue }
    func title(_ language: AppLanguage) -> String {
        switch self {
        case .home: return L10n.t("Главная", "Asosiy", language)
        case .catalog: return L10n.t("Каталог", "Katalog", language)
        case .favorites: return L10n.t("Избранное", "Saqlangan", language)
        case .more: return L10n.t("Ещё", "Yana", language)
        }
    }
    var symbol: String { switch self { case .home: return "house"; case .catalog: return "square.grid.2x2"; case .favorites: return "heart"; case .more: return "ellipsis" } }
    var selectedSymbol: String { switch self { case .home: return "house.fill"; case .catalog: return "square.grid.2x2.fill"; case .favorites: return "heart.fill"; case .more: return "ellipsis" } }
}

struct LiquidGlassTabBar: View {
    @EnvironmentObject private var settings: AppSettings
    @Binding var selection: AppTab
    @Namespace private var ns
    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                GlassEffectContainer(spacing: 6) { bar.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 30)) }
            } else {
                bar.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(Color.white.opacity(0.24), lineWidth: 0.7))
                    .shadow(color: .black.opacity(0.15), radius: 22, y: 10)
            }
        }
        .padding(.horizontal, 12).padding(.bottom, 7)
        .sensoryFeedback(.selection, trigger: selection)
    }
    private var bar: some View {
        HStack(spacing: 3) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) { selection = tab }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: selection == tab ? tab.selectedSymbol : tab.symbol).font(.system(size: 18, weight: .semibold))
                        Text(tab.title(settings.language)).font(.system(size: 10, weight: .semibold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.75)
                    }
                    .foregroundStyle(selection == tab ? Color.primary : Color.secondary)
                    .frame(maxWidth: .infinity).frame(height: 58)
                    .background {
                        if selection == tab { RoundedRectangle(cornerRadius: 23, style: .continuous).fill(Color.primary.opacity(0.07)).matchedGeometryEffect(id: "selected", in: ns) }
                    }
                }.buttonStyle(.plain)
            }
        }.padding(5)
    }
}
