import SwiftUI

struct RequestCarView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var brand = ""
    @State private var model = ""
    @State private var budget = ""
    @State private var currency = "USD"
    @State private var timeframe = "30"
    @State private var name = ""
    @State private var phone = ""
    @State private var notes = ""
    @State private var preference: ContactPreference = .whatsapp

    var body: some View {
        Form {
            Section(L10n.t("Автомобиль", "Avtomobil", settings.language)) {
                TextField(L10n.t("Марка", "Marka", settings.language), text: $brand)
                TextField(L10n.t("Модель", "Model", settings.language), text: $model)
                HStack { TextField(L10n.t("Макс. бюджет", "Maks. budjet", settings.language), text: $budget).keyboardType(.numberPad); Picker("", selection: $currency) { Text("USD").tag("USD"); Text("UZS").tag("UZS"); Text("EUR").tag("EUR") }.labelsHidden() }
                Picker(L10n.t("Срок", "Muddat", settings.language), selection: $timeframe) { Text(L10n.t("7 дней", "7 kun", settings.language)).tag("7"); Text(L10n.t("30 дней", "30 kun", settings.language)).tag("30"); Text(L10n.t("3 месяца", "3 oy", settings.language)).tag("90"); Text(L10n.t("Не критично", "Muhim emas", settings.language)).tag("any") }
                TextField(L10n.t("Комплектация, цвет, пожелания", "Komplektatsiya, rang, istaklar", settings.language), text: $notes, axis: .vertical).lineLimit(3...6)
            }
            Section(L10n.t("Контакт", "Aloqa", settings.language)) {
                TextField(L10n.t("Ваше имя", "Ismingiz", settings.language), text: $name)
                TextField(L10n.t("Телефон", "Telefon", settings.language), text: $phone).keyboardType(.phonePad)
                Picker(L10n.t("Связаться через", "Aloqa usuli", settings.language), selection: $preference) { ForEach(ContactPreference.allCases) { Text($0.rawValue).tag($0) } }
            }
            Section { Button { submit() } label: { Text(L10n.t("Отправить запрос", "So‘rov yuborish", settings.language)).frame(maxWidth: .infinity).fontWeight(.semibold) }.disabled(brand.trimmingCharacters(in: .whitespaces).isEmpty || model.trimmingCharacters(in: .whitespaces).isEmpty || name.trimmingCharacters(in: .whitespaces).isEmpty || phone.trimmingCharacters(in: .whitespaces).isEmpty) }
        }
        .navigationTitle(L10n.t("Персональный подбор", "Shaxsiy tanlov", settings.language)).navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button(L10n.t("Закрыть", "Yopish", settings.language)) { dismiss() } } }
    }
    private func submit() {
        let detail = "\(brand) \(model) · \(budget.isEmpty ? "—" : budget + " " + currency)"
        store.recordRequest(kind: .vehicle, title: "\(brand) \(model)", detail: detail)
        let text = "Здравствуйте. Хочу автомобиль под заказ.\nМарка: \(brand)\nМодель: \(model)\nБюджет: \(budget.isEmpty ? "—" : budget + " " + currency)\nСрок: \(timeframe)\nИмя: \(name)\nТелефон: \(phone)\nПожелания: \(notes.isEmpty ? "—" : notes)"
        openURL(contactURL(text))
        dismiss()
    }
    private func contactURL(_ text: String) -> URL {
        let e = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        switch preference { case .whatsapp: return URL(string: "https://wa.me/\(AppConfig.whatsappPhone)?text=\(e)")!; case .telegram: return AppConfig.telegram; case .call: return URL(string: "tel:\(AppConfig.phone)")! }
    }
}
