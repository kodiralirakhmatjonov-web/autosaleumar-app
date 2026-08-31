import SwiftUI

struct ContactsCompactCard: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.openURL) private var openURL
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.t("КОНТАКТЫ", "ALOQA", settings.language)).font(.system(size: 10.5, weight: .bold, design: .rounded)).tracking(1).foregroundStyle(.secondary)
            Text(L10n.t("Продолжим там, где удобно вам.", "Sizga qulay joyda davom etamiz.", settings.language)).font(.system(size: 25, weight: .bold, design: .rounded)).tracking(-0.5)
            HStack(spacing: 9) {
                contact("Instagram", "camera") { openURL(AppConfig.instagram) }
                contact("Telegram", "paperplane") { openURL(AppConfig.telegram) }
            }
            Button { openURL(URL(string: "tel:\(AppConfig.phone)")!) } label: { Label(AppConfig.phoneDisplay, systemImage: "phone.fill").font(.system(size: 15, weight: .semibold)).frame(maxWidth: .infinity).frame(height: 50).background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 17, style: .continuous)) }.buttonStyle(.plain)
        }.padding(22).asuCard().padding(.horizontal, ASUDesign.pagePadding)
    }
    private func contact(_ title: String, _ symbol: String, action: @escaping () -> Void) -> some View { Button(action: action) { Label(title, systemImage: symbol).font(.system(size: 13.5, weight: .semibold)).frame(maxWidth: .infinity).frame(height: 48).background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 17, style: .continuous)) }.buttonStyle(.plain) }
}
