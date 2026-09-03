import SwiftUI

struct RequestCarView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var model = ""
    @State private var budget = ""
    @State private var deadline = ""

    var body: some View {
        Form {
            Section(L10n.t("Автомобиль", "Avtomobil", settings.language)) {
                TextField(L10n.t("Марка и модель", "Marka va model", settings.language), text: $model)
                TextField(L10n.t("Бюджет", "Budjet", settings.language), text: $budget)
                TextField(L10n.t("Желаемый срок", "Muddat", settings.language), text: $deadline)
            }
            Section {
                Button(L10n.t("Отправить в WhatsApp", "WhatsApp orqali yuborish", settings.language)) { openURL(requestURL) }
                    .disabled(model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle(L10n.t("Персональный подбор", "Shaxsiy tanlov", settings.language))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(L10n.t("Закрыть", "Yopish", settings.language)) { dismiss() } } }
    }

    private var requestURL: URL {
        let text = "Здравствуйте. Нужен подбор автомобиля. Модель: \(model). Бюджет: \(budget). Срок: \(deadline)."
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://wa.me/\(AppConfig.whatsappPhone)?text=\(encoded)")!
    }
}

struct BookingView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var date = Date().addingTimeInterval(86_400)
    @State private var name = ""

    var body: some View {
        Form {
            Section(L10n.t("Визит", "Tashrif", settings.language)) {
                TextField(L10n.t("Ваше имя", "Ismingiz", settings.language), text: $name)
                DatePicker(L10n.t("Дата и время", "Sana va vaqt", settings.language), selection: $date, in: Date()...)
            }
            Section {
                Button(L10n.t("Подтвердить через WhatsApp", "WhatsApp orqali tasdiqlash", settings.language)) { openURL(bookingURL) }
            }
        }
        .navigationTitle(L10n.t("Забронировать визит", "Tashrifni band qilish", settings.language))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(L10n.t("Закрыть", "Yopish", settings.language)) { dismiss() } } }
    }

    private var bookingURL: URL {
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "ru_RU"); formatter.dateFormat = "dd.MM.yyyy HH:mm"
        let text = "Здравствуйте. Хочу забронировать визит в Auto Sale Umar. Имя: \(name). Время: \(formatter.string(from: date))."
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://wa.me/\(AppConfig.whatsappPhone)?text=\(encoded)")!
    }
}
