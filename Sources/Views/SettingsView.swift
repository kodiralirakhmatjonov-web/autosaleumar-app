import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        Form {
            Section { HStack(spacing: 14) { Image(scheme == .dark ? "WordmarkWhite" : "WordmarkBlack").resizable().scaledToFit().frame(width: 150); Spacer() } }
            Section(L10n.t("Язык", "Til", settings.language)) { Picker(L10n.t("Язык", "Til", settings.language), selection: $settings.language) { ForEach(AppLanguage.allCases) { Text($0.title).tag($0) } }.pickerStyle(.segmented) }
            Section(L10n.t("Оформление", "Ko‘rinish", settings.language)) { Picker(L10n.t("Оформление", "Ko‘rinish", settings.language), selection: $settings.theme) { ForEach(AppTheme.allCases) { Text($0.title).tag($0) } }.pickerStyle(.segmented) }
            Section(L10n.t("Приложение", "Ilova", settings.language)) { LabeledContent(L10n.t("Версия", "Versiya", settings.language), value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"); LabeledContent("iOS", value: "SwiftUI · Native") }
        }
        .navigationTitle(L10n.t("Настройки", "Sozlamalar", settings.language)).navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button(L10n.t("Готово", "Tayyor", settings.language)) { dismiss() } } }
    }
}
