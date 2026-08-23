import SwiftUI

@main
struct AutoSaleUmarApp: App {
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .preferredColorScheme(settings.preferredColorScheme)
        }
    }
}
