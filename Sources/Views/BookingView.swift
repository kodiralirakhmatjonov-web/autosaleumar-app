import SwiftUI

struct BookingView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var slot = "12:00–14:00"
    @State private var car = ""
    @State private var name = ""
    @State private var phone = ""
    @State private var comment = ""
    let slots = ["10:00–12:00", "12:00–14:00", "14:00–16:00", "16:00–18:00", "18:00–20:00"]

    var body: some View {
        Form {
            Section(L10n.t("Время визита", "Tashrif vaqti", settings.language)) {
                DatePicker(L10n.t("Дата", "Sana", settings.language), selection: $date, in: Date()..., displayedComponents: .date)
                Picker(L10n.t("Время", "Vaqt", settings.language), selection: $slot) { ForEach(slots, id: \.self) { Text($0) } }
                TextField(L10n.t("Автомобиль или марка", "Avtomobil yoki marka", settings.language), text: $car)
            }
            Section(L10n.t("Контакт", "Aloqa", settings.language)) {
                TextField(L10n.t("Ваше имя", "Ismingiz", settings.language), text: $name)
                TextField(L10n.t("Телефон", "Telefon", settings.language), text: $phone).keyboardType(.phonePad)
                TextField(L10n.t("Комментарий", "Izoh", settings.language), text: $comment, axis: .vertical).lineLimit(2...5)
            }
            Section { Button { submit() } label: { Text(L10n.t("Забронировать визит", "Tashrifni band qilish", settings.language)).frame(maxWidth: .infinity).fontWeight(.semibold) }.disabled(name.isEmpty || phone.isEmpty) }
        }
        .navigationTitle(L10n.t("Визит в шоурум", "Shourumga tashrif", settings.language)).navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button(L10n.t("Закрыть", "Yopish", settings.language)) { dismiss() } } }
    }
    private func submit() {
        let f = DateFormatter(); f.dateFormat = "dd.MM.yyyy"
        let title = "\(f.string(from: date)) · \(slot)"
        store.recordRequest(kind: .visit, title: title, detail: car.isEmpty ? name : car)
        let text = "Здравствуйте. Хочу забронировать визит в Auto Sale Umar.\nДата: \(f.string(from: date))\nВремя: \(slot)\nАвтомобиль: \(car.isEmpty ? "—" : car)\nИмя: \(name)\nТелефон: \(phone)\nКомментарий: \(comment.isEmpty ? "—" : comment)"
        let e = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        openURL(URL(string: "https://wa.me/\(AppConfig.whatsappPhone)?text=\(e)")!)
        dismiss()
    }
}
