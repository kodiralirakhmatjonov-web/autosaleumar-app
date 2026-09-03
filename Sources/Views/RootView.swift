import SwiftUI

struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: AppStore
    @State private var selection: AppTab = .home
    @State private var showsLaunch = true

    var body: some View {
        ZStack {
            TabView(selection: $selection) {
                HomeView(selectTab: { selection = $0 })
                    .tag(AppTab.home)
                    .tabItem { Label(AppTab.home.title(settings.language), systemImage: AppTab.home.symbol) }

                CatalogView()
                    .tag(AppTab.catalog)
                    .tabItem { Label(AppTab.catalog.title(settings.language), systemImage: AppTab.catalog.symbol) }

                FavoritesView()
                    .tag(AppTab.favorites)
                    .tabItem { Label(AppTab.favorites.title(settings.language), systemImage: AppTab.favorites.symbol) }

                MoreView()
                    .tag(AppTab.more)
                    .tabItem { Label(AppTab.more.title(settings.language), systemImage: AppTab.more.symbol) }
            }
            .tint(.primary)

            if showsLaunch {
                LaunchOverlay()
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .task { await store.loadIfNeeded() }
        .sensoryFeedback(.selection, trigger: selection)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                withAnimation(.easeInOut(duration: 0.28)) { showsLaunch = false }
            }
        }
    }
}
