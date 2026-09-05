import SwiftUI

@main
struct AutoSaleUmarApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settings = AppSettings()
    @StateObject private var store = AppStore()
    @StateObject private var router = AppRouter()

    init() {
        ASURuntime.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(store)
                .environmentObject(router)
                .preferredColorScheme(settings.preferredColorScheme)
        }
    }
}
