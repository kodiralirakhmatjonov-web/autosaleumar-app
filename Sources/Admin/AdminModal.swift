import SwiftUI

struct ASUAdminModal: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @StateObject private var session = ASUAdminSessionStore()

    var body: some View {
        Group {
            if session.isRestoring {
                restoringView
            } else if session.isSignedIn {
                ASUAdminControlSystemView(session: session) {
                    dismiss()
                }
            } else {
                ASUAdminLoginView(session: session) {
                    dismiss()
                }
            }
        }
        .background(ASUDesign.page)
        .task { await session.restoreIfNeeded() }
        .preferredColorScheme(settings.preferredColorScheme)
    }

    private var restoringView: some View {
        VStack(spacing: 18) {
            Image(colorScheme == .dark ? "WordmarkWhite" : "WordmarkBlack")
                .resizable()
                .scaledToFit()
                .frame(width: 190)
            ProgressView()
                .controlSize(.large)
            Text(L10n.t("Проверяем защищённую сессию…", "Himoyalangan sessiya tekshirilmoqda…", settings.language))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ASUDesign.page)
    }
}
