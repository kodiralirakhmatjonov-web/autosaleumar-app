import SwiftUI

private enum ASUGlobalSheet: String, Identifiable {
    case compare
    case requestCar
    case visit
    case location
    case trust
    case ramadanGift

    var id: String { rawValue }
}

struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var selection: AppTab = AppTab(
        rawValue: UserDefaults.standard.string(forKey: "ASULastSelectedTabV1") ?? ""
    ) ?? .home
    @State private var showsLaunch = true
    @State private var globalSheet: ASUGlobalSheet?

    var body: some View {
        ZStack {
            TabView(selection: $selection) {
                HomeView(selectTab: selectTab)
                    .tag(AppTab.home)
                    .tabItem { Label(AppTab.home.title(settings.language), systemImage: AppTab.home.symbol) }

                CatalogView()
                    .tag(AppTab.catalog)
                    .tabItem { Label(AppTab.catalog.title(settings.language), systemImage: AppTab.catalog.symbol) }

                FavoritesView()
                    .tag(AppTab.favorites)
                    .tabItem { Label(AppTab.favorites.title(settings.language), systemImage: AppTab.favorites.symbol) }

                ProfileView(selectTab: selectTab)
                    .tag(AppTab.profile)
                    .tabItem { Label(AppTab.profile.title(settings.language), systemImage: AppTab.profile.symbol) }
            }
            .tint(.primary)

            if showsLaunch {
                LaunchOverlay {
                    if reduceMotion {
                        showsLaunch = false
                    } else {
                        withAnimation(.easeInOut(duration: ASUDesign.navigationDuration)) {
                            showsLaunch = false
                        }
                    }
                }
                .transition(reduceMotion ? .identity : .opacity)
                .zIndex(100)
            }
        }
        .task {
            await store.loadIfNeeded()
            consumePendingNotificationIfNeeded()
            handleRoute(router.route)
        }
        .onOpenURL { url in
            _ = router.handle(url: url)
        }
        .onReceive(NotificationCenter.default.publisher(for: .asuNotificationRoute)) { notification in
            if let deepLink = notification.userInfo?["asu_deep_link"] as? String,
               let url = URL(string: deepLink),
               router.handle(url: url) {
                return
            }

            let code = notification.userInfo?["asu_activity_code"] as? String
            router.open(.profile(activityCode: code))
        }
        .onChange(of: router.route) { _, route in
            handleRoute(route)
        }
        .onChange(of: selection) { _, newValue in
            UserDefaults.standard.set(newValue.rawValue, forKey: "ASULastSelectedTabV1")
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, !showsLaunch else { return }
            consumePendingNotificationIfNeeded()
            Task { await store.refreshIfStale() }
        }
        .sheet(item: $globalSheet) { destination in
            globalSheetContent(destination)
        }
        .sensoryFeedback(.selection, trigger: selection)
    }

    @ViewBuilder
    private func globalSheetContent(_ destination: ASUGlobalSheet) -> some View {
        switch destination {
        case .compare:
            CompareView()
        case .requestCar:
            NavigationStack { RequestCarView() }
        case .visit:
            NavigationStack { BookingView() }
        case .location:
            NavigationStack { LocationView() }
        case .trust:
            NavigationStack {
                TrustView(openCatalog: {
                    globalSheet = nil
                    store.requestCatalog()
                    selectTab(.catalog)
                })
            }
        case .ramadanGift:
            NavigationStack { RamadanGiftView() }
        }
    }

    private func selectTab(_ tab: AppTab) {
        if reduceMotion {
            selection = tab
        } else {
            withAnimation(.easeInOut(duration: ASUDesign.navigationDuration)) {
                selection = tab
            }
        }
    }

    private func consumePendingNotificationIfNeeded() {
        if let pendingURL = ASUNotificationBridge.consumePendingRouteURL(),
           router.handle(url: pendingURL) {
            return
        }
        guard let code = ASUNotificationBridge.consumePendingActivityCode() else { return }
        router.open(.profile(activityCode: code))
    }

    private func handleRoute(_ route: ASURoute?) {
        guard let route else { return }

        // A deliberate deep link or notification should never be hidden behind the launch film.
        if showsLaunch { showsLaunch = false }

        switch route {
        case .home:
            globalSheet = nil
            selectTab(.home)

        case .catalog(let brand, let status):
            globalSheet = nil
            store.requestCatalog(brand: brand, status: status)
            selectTab(.catalog)

        case .favorites:
            globalSheet = nil
            selectTab(.favorites)

        case .profile(let activityCode):
            globalSheet = nil
            router.focusActivity(activityCode)
            selectTab(.profile)

        case .car(let slug):
            globalSheet = nil
            store.requestCar(slug: slug)
            selectTab(.catalog)

        case .compare:
            globalSheet = .compare

        case .requestCar:
            globalSheet = .requestCar

        case .visit:
            globalSheet = .visit

        case .location:
            globalSheet = .location

        case .trust:
            globalSheet = .trust

        case .ramadanGift:
            globalSheet = .ramadanGift
        }

        router.consumeRoute()
    }
}
