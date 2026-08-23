import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.colorScheme) private var colorScheme
    let navigate: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                quickAccess
                languageCard
                appearanceCard
                aboutCard
            }
            .padding(.horizontal, 18)
            .padding(.top, 22)
            .padding(.bottom, 128)
        }
        .scrollIndicators(.hidden)
        .background(ASUDesign.page)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(colorScheme == .dark ? "WordmarkWhite" : "WordmarkBlack")
                .resizable()
                .scaledToFit()
                .frame(width: 176)
                .accessibilityLabel("Auto Sale Umar")

            Text("Настройки")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .tracking(-0.7)

            Text("Единая цифровая экосистема автомобилей")
                .font(.system(size: 15.5, weight: .regular))
                .foregroundStyle(.secondary)
        }
    }

    private var quickAccess: some View {
        SettingsSection(title: "БЫСТРЫЙ ДОСТУП") {
            SettingsLinkRow(title: "Control System", subtitle: "Управление автомобилями", symbol: "slider.horizontal.3") {
                navigate("/admin/cars/")
            }
            Divider().padding(.leading, 52)
            SettingsLinkRow(title: "Сотрудники", subtitle: "Администраторы и менеджеры", symbol: "person.2.fill") {
                navigate("/admin/staff/")
            }
            Divider().padding(.leading, 52)
            SettingsLinkRow(title: "Шоурум", subtitle: "Автомобили в шоуруме", symbol: "building.2.fill") {
                navigate("/#showroom")
            }
            Divider().padding(.leading, 52)
            SettingsLinkRow(title: "Забронировать визит", subtitle: nil, symbol: "calendar.badge.plus") {
                navigate("/booking/")
            }
            Divider().padding(.leading, 52)
            SettingsLinkRow(title: "Получить рекомендацию", subtitle: nil, symbol: "sparkles") {
                navigate("/request-car/")
            }
        }
    }

    private var languageCard: some View {
        SettingsSection(title: "ЯЗЫК") {
            Picker("Язык", selection: $settings.language) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.title).tag(language)
                }
            }
            .pickerStyle(.segmented)
            .padding(12)
        }
    }

    private var appearanceCard: some View {
        SettingsSection(title: "ОФОРМЛЕНИЕ") {
            Picker("Оформление", selection: $settings.theme) {
                ForEach(AppTheme.allCases) { theme in
                    Text(theme.title).tag(theme)
                }
            }
            .pickerStyle(.segmented)
            .padding(12)
        }
    }

    private var aboutCard: some View {
        SettingsSection(title: "ПРИЛОЖЕНИЕ") {
            HStack(spacing: 12) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 21, weight: .semibold))
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Auto Sale Umar for iOS")
                        .font(.system(size: 15.5, weight: .semibold))
                    Text("Native SwiftUI shell · TestFlight ready")
                        .font(.system(size: 12.5))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(16)
        }
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            VStack(spacing: 0) {
                content
            }
            .asuCard()
        }
    }
}

private struct SettingsLinkRow: View {
    let title: String
    let subtitle: String?
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 30, height: 30)
                    .background(Color.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 12.5))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .frame(minHeight: 62)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
