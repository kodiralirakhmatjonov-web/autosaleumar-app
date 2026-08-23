import SwiftUI

struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var selection: AppTab = .home
    @State private var webPath = "/"
    @State private var showsLaunch = true

    private var activeURL: URL {
        AppConfig.siteURL(path: webPath, language: settings.language, theme: settings.theme)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ASUDesign.page.ignoresSafeArea()

            Group {
                if selection == .settings {
                    SettingsView { path in
                        webPath = path
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                            selection = .home
                        }
                    }
                } else {
                    SiteWebView(url: activeURL)
                        .id("\(selection.rawValue)-\(settings.language.rawValue)-\(settings.theme.rawValue)-\(webPath)")
                        .ignoresSafeArea(edges: .bottom)
                }
            }

            LiquidGlassTabBar(selection: Binding(
                get: { selection },
                set: { next in
                    if let path = next.path {
                        webPath = path
                    }
                    selection = next
                }
            ))

            if showsLaunch {
                LaunchOverlay()
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
                withAnimation(.easeInOut(duration: 0.32)) {
                    showsLaunch = false
                }
            }
        }
    }
}
