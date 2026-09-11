import SwiftUI

struct ASUExperienceSwitcher: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let mode: ASUExperienceMode
    let switchMode: (ASUExperienceMode) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.t("ИНТЕРФЕЙС", "INTERFEYS", settings.language))
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                .tracking(1.05)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                modeButton(
                    .client,
                    title: L10n.t("Клиент", "Mijoz", settings.language),
                    symbol: "person.crop.circle"
                )
                modeButton(
                    .staff,
                    title: L10n.t("Сотрудник", "Xodim", settings.language),
                    symbol: "person.crop.circle.badge.checkmark"
                )
            }
            .padding(5)
            .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .stroke(ASUDesign.line, lineWidth: 0.7)
            )
        }
    }

    private func modeButton(_ target: ASUExperienceMode, title: String, symbol: String) -> some View {
        Button {
            guard target != mode else { return }
            if reduceMotion {
                switchMode(target)
            } else {
                withAnimation(ASUDesign.softSpring) {
                    switchMode(target)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundStyle(mode == target ? Color(uiColor: .systemBackground) : Color.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(mode == target ? Color.primary : Color.clear)
            }
            .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
