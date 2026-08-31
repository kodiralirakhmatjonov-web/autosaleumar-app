import SwiftUI

@main
struct AutoSaleUmarApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(store)
                .preferredColorScheme(settings.preferredColorScheme)
        }
    }
}
