import SwiftUI

struct ShowroomView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var showBooking = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(L10n.t("О ШОУРУМЕ", "SHOURUM HAQIDA", settings.language)).font(.system(size: 10.5, weight: .bold, design: .rounded)).tracking(1).foregroundStyle(.secondary)
                Text(L10n.t("Пространство для\nспокойного выбора.", "Xotirjam tanlov\nuchun makon.", settings.language)).font(.system(size: 34, weight: .bold, design: .rounded)).tracking(-1)
                feature("light.max", L10n.t("Свет подчёркивает главное", "Yorug‘lik asosiyni ko‘rsatadi", settings.language), L10n.t("Архитектура и свет помогают рассмотреть линии, материалы и детали автомобиля без визуального шума.", "Arxitektura va yorug‘lik avtomobil chiziqlari va detallarini xotirjam ko‘rishga yordam beradi.", settings.language))
                feature("sofa", L10n.t("Комфорт начинается до поездки", "Qulaylik safardan oldin boshlanadi", settings.language), L10n.t("Клиентская зона, персональное внимание и время для обдуманного решения.", "Mijozlar zonasi, shaxsiy e’tibor va o‘ylangan qaror uchun vaqt.", settings.language))
                feature("checkmark.seal", L10n.t("Доверие строится на деталях", "Ishonch detallardan boshlanadi", settings.language), L10n.t("Прозрачный статус автомобиля и ответственное сопровождение до передачи ключей.", "Avtomobilning aniq holati va kalit topshirilgunga qadar mas’uliyatli hamrohlik.", settings.language))
                Button { showBooking = true } label: { Label(L10n.t("Забронировать визит", "Tashrifni band qilish", settings.language), systemImage: "calendar.badge.plus") }.buttonStyle(ASUPrimaryButtonStyle())
                Button { openURL(AppConfig.yandexMaps) } label: { Label(L10n.t("Построить маршрут", "Yo‘nalish qurish", settings.language), systemImage: "location") }.frame(maxWidth: .infinity).frame(height: 52).background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 18, style: .continuous)).buttonStyle(.plain)
            }.padding(20)
        }
        .navigationTitle("Auto Sale Umar").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(L10n.t("Готово", "Tayyor", settings.language)) { dismiss() } } }
        .sheet(isPresented: $showBooking) { NavigationStack { BookingView() } }
    }
    private func feature(_ symbol: String, _ title: String, _ text: String) -> some View { HStack(alignment: .top, spacing: 14) { Image(systemName: symbol).font(.system(size: 20, weight: .semibold)).frame(width: 42, height: 42).background(ASUDesign.soft, in: Circle()); VStack(alignment: .leading, spacing: 5) { Text(title).font(.system(size: 17, weight: .bold, design: .rounded)); Text(text).font(.system(size: 14)).foregroundStyle(.secondary).lineSpacing(3) } }.padding(16).asuCard(radius: 22, shadow: false) }
}
