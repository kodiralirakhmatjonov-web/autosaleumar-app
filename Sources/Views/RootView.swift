import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selection: AppTab = .home
    @State private var showsLaunch = true

    var body: some View {
        ZStack(alignment: .bottom) {
            ASUDesign.page.ignoresSafeArea()
            Group {
                switch selection {
                case .home: HomeView(selectTab: { selection = $0 })
                case .catalog: CatalogView()
                case .favorites: FavoritesView()
                case .more: MoreView()
                }
            }
            .safeAreaPadding(.bottom, 78)
            LiquidGlassTabBar(selection: $selection)
            if showsLaunch { LaunchOverlay().transition(.opacity).zIndex(100) }
        }
        .task { await store.loadIfNeeded() }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
                withAnimation(.easeInOut(duration: 0.36)) { showsLaunch = false }
            }
        }
    }
}
