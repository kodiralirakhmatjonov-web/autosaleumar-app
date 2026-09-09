import SwiftUI
import Foundation

struct ASUAdminVisitsView: View {
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject var session: ASUAdminSessionStore

    @State private var visits: [ASUAdminVisit] = []
    @State private var filter: ASUAdminVisitStatus?
    @State private var isLoading = true
    @State private var updatingID: Int?
    @State private var errorMessage: String?

    private let api = ASUAdminOperationsAPI()

    private var filteredVisits: [ASUAdminVisit] {
        guard let filter else { return visits }
        return visits.filter { $0.status == filter }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                hero
                filters

                if let errorMessage {
                    errorCard(errorMessage)
                }

                if isLoading && visits.isEmpty {
                    loadingState
                } else if filteredVisits.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredVisits) { visit in
                            visitCard(visit)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 38)
        }
        .scrollIndicators(.hidden)
        .background(ASUDesign.page)
        .navigationTitle(L10n.t("Визиты", "Tashriflar", settings.language))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await load(silent: true) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .refreshable { await load(silent: true) }
        .task { await load() }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color.black, Color(red: 0.08, green: 0.08, blue: 0.09)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Circle()
                .fill(ASUDesign.success.opacity(0.18))
                .frame(width: 190, height: 190)
                .blur(radius: 42)
                .offset(x: 170, y: -90)

            VStack(alignment: .leading, spacing: 17) {
                HStack {
                    Text("SHOWROOM OPERATIONS")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .tracking(1.2)
                    Spacer()
                    HStack(spacing: 6) {
                        Circle().fill(ASUDesign.success).frame(width: 7, height: 7)
                        Text("D1 LIVE")
                    }
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .tracking(0.7)
                }
                .foregroundStyle(.white.opacity(0.60))

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.t("Забронированные визиты", "Band qilingan tashriflar", settings.language))
                        .font(.system(size: 33, weight: .bold, design: .rounded))
                        .tracking(-1.1)
                        .foregroundStyle(.white)
                    Text(L10n.t(
                        "Дата, время, интересующий автомобиль и контакт клиента — в одной рабочей ленте.",
                        "Sana, vaqt, avtomobil va mijoz kontakti — bitta ish lentasida.",
                        settings.language
                    ))
                    .font(.system(size: 13.5))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineSpacing(3)
                }

                HStack(spacing: 10) {
                    heroMetric(value: visits.count, title: L10n.t("Всего", "Jami", settings.language))
                    heroMetric(value: count(.new), title: L10n.t("Новые", "Yangi", settings.language))
                    heroMetric(value: count(.confirmed), title: L10n.t("Подтверждены", "Tasdiqlangan", settings.language))
                }
            }
            .padding(21)
        }
        .frame(minHeight: 288)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 0.7))
    }

    private func heroMetric(value: Int, title: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(String(value))
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text(title)
                .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .frame(height: 62)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var filters: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                filterButton(status: nil, title: L10n.t("Все", "Barchasi", settings.language), count: visits.count)
                ForEach(ASUAdminVisitStatus.allCases) { status in
                    filterButton(status: status, title: status.title(settings.language), count: count(status))
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private func filterButton(status: ASUAdminVisitStatus?, title: String, count: Int) -> some View {
        let selected = filter == status
        return Button {
            withAnimation(.snappy(duration: 0.22)) { filter = status }
        } label: {
            HStack(spacing: 7) {
                Text(title)
                Text(String(count))
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundStyle(selected ? .white.opacity(0.72) : .secondary)
            }
            .font(.system(size: 12.5, weight: .bold, design: .rounded))
            .foregroundStyle(selected ? .white : .primary)
            .padding(.horizontal, 13)
            .frame(height: 42)
            .background(selected ? Color.black : ASUDesign.elevated, in: Capsule())
            .overlay(Capsule().stroke(selected ? Color.clear : ASUDesign.line, lineWidth: 0.7))
        }
        .buttonStyle(.plain)
    }

    private func visitCard(_ visit: ASUAdminVisit) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(L10n.t("БРОНИРОВАНИЕ", "BRON", settings.language)) · \(visit.code)")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .tracking(0.75)
                        .foregroundStyle(.secondary)
                    Text(visit.customerName)
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                        .tracking(-0.4)
                }
                Spacer(minLength: 8)
                statusPill(visit.status)
            }

            HStack(spacing: 9) {
                fact(symbol: "calendar", title: formattedVisitDate(visit.visitDate))
                fact(symbol: "clock", title: visit.timeSlot)
            }

            VStack(spacing: 0) {
                contactRow(visit)
                Divider().padding(.leading, 42)
                detailRow(
                    symbol: "car.side",
                    label: L10n.t("Интерес", "Qiziqish", settings.language),
                    value: interestText(visit)
                )
                if let note = cleanOptional(visit.note) {
                    Divider().padding(.leading, 42)
                    detailRow(symbol: "text.bubble", label: L10n.t("Комментарий", "Izoh", settings.language), value: note)
                }
            }
            .padding(.horizontal, 14)
            .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

            HStack(spacing: 8) {
                if visit.status == .cancelled {
                    actionButton(
                        title: L10n.t("Вернуть в новые", "Yangi holatga", settings.language),
                        symbol: "arrow.uturn.backward",
                        visit: visit,
                        status: .new,
                        prominent: true
                    )
                } else {
                    if visit.status != .confirmed {
                        actionButton(
                            title: L10n.t("Подтвердить", "Tasdiqlash", settings.language),
                            symbol: "checkmark",
                            visit: visit,
                            status: .confirmed,
                            prominent: visit.status == .new
                        )
                    }
                    if visit.status != .completed {
                        actionButton(
                            title: L10n.t("Завершить", "Yakunlash", settings.language),
                            symbol: "checkmark.circle",
                            visit: visit,
                            status: .completed,
                            prominent: visit.status == .confirmed
                        )
                    }
                    Menu {
                        Button(role: .destructive) {
                            Task { await update(visit, to: .cancelled) }
                        } label: {
                            Label(L10n.t("Отменить визит", "Tashrifni bekor qilish", settings.language), systemImage: "xmark.circle")
                        }
                        ForEach(ASUAdminVisitStatus.allCases.filter { $0 != visit.status && $0 != .cancelled }) { status in
                            Button {
                                Task { await update(visit, to: status) }
                            } label: {
                                Text(status.title(settings.language))
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .bold))
                            .frame(width: 44, height: 44)
                            .background(ASUDesign.soft, in: Circle())
                    }
                    .disabled(updatingID != nil)
                }
            }
        }
        .padding(17)
        .asuCard(radius: 28)
        .opacity(updatingID == visit.id ? 0.62 : 1)
    }

    private func fact(symbol: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .frame(height: 45)
        .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func contactRow(_ visit: ASUAdminVisit) -> some View {
        if let url = phoneURL(visit.phone) {
            Link(destination: url) {
                detailRowContent(
                    symbol: "phone.fill",
                    label: L10n.t("Телефон", "Telefon", settings.language),
                    value: visit.phone,
                    trailing: "arrow.up.right"
                )
            }
            .buttonStyle(.plain)
        } else {
            detailRow(symbol: "phone", label: L10n.t("Телефон", "Telefon", settings.language), value: visit.phone)
        }
    }

    private func detailRow(symbol: String, label: String, value: String) -> some View {
        detailRowContent(symbol: symbol, label: label, value: value, trailing: nil)
    }

    private func detailRowContent(symbol: String, label: String, value: String, trailing: String?) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(label.uppercased())
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .tracking(0.7)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 6)
            if let trailing {
                Image(systemName: trailing)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func actionButton(
        title: String,
        symbol: String,
        visit: ASUAdminVisit,
        status: ASUAdminVisitStatus,
        prominent: Bool
    ) -> some View {
        Button {
            Task { await update(visit, to: status) }
        } label: {
            HStack(spacing: 7) {
                if updatingID == visit.id {
                    ProgressView().controlSize(.mini).tint(prominent ? Color.white : Color.primary)
                } else {
                    Image(systemName: symbol)
                }
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .font(.system(size: 12.5, weight: .bold, design: .rounded))
            .foregroundStyle(prominent ? .white : .primary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(prominent ? Color.black : ASUDesign.soft, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(updatingID != nil)
    }

    private func statusPill(_ status: ASUAdminVisitStatus) -> some View {
        HStack(spacing: 6) {
            Circle().fill(statusColor(status)).frame(width: 7, height: 7)
            Text(status.title(settings.language))
                .font(.system(size: 10, weight: .bold, design: .rounded))
        }
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(statusColor(status).opacity(0.11), in: Capsule())
    }

    private func statusColor(_ status: ASUAdminVisitStatus) -> Color {
        switch status {
        case .new: return .blue
        case .confirmed: return ASUDesign.orange
        case .completed: return ASUDesign.success
        case .cancelled: return .secondary
        }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(L10n.t("Загружаем визиты…", "Tashriflar yuklanmoqda…", settings.language))
                .font(.system(size: 13.5, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .asuCard(radius: 28)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 28, weight: .light))
            Text(L10n.t("В этой категории визитов пока нет.", "Bu bo‘limda hozircha tashrif yo‘q.", settings.language))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 170)
        .asuCard(radius: 28)
    }

    private func errorCard(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(ASUDesign.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.t("Не удалось обновить визиты", "Tashriflarni yangilab bo‘lmadi", settings.language))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Text(message)
                    .font(.system(size: 12.5))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(15)
        .asuCard(radius: 22)
    }

    private func count(_ status: ASUAdminVisitStatus) -> Int {
        visits.lazy.filter { $0.status == status }.count
    }

    private func interestText(_ visit: ASUAdminVisit) -> String {
        if let label = cleanOptional(visit.carLabel) { return label }
        if let brand = cleanOptional(visit.brand) { return brand }
        return L10n.t("Без конкретного автомобиля", "Aniq avtomobilsiz", settings.language)
    }

    private func cleanOptional(_ value: String?) -> String? {
        guard let value else { return nil }
        let clean = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? nil : clean
    }

    private func phoneURL(_ phone: String) -> URL? {
        let allowed = phone.filter { $0.isNumber || $0 == "+" }
        guard allowed.contains(where: { $0.isNumber }) else { return nil }
        return URL(string: "tel:\(allowed)")
    }

    private func formattedVisitDate(_ value: String) -> String {
        let input = DateFormatter()
        input.locale = Locale(identifier: "en_US_POSIX")
        input.dateFormat = "yyyy-MM-dd"
        guard let date = input.date(from: value) else { return value }

        let output = DateFormatter()
        output.locale = Locale(identifier: settings.language == .ru ? "ru_RU" : "uz_UZ")
        output.dateFormat = "EEE, d MMMM"
        return output.string(from: date)
    }

    @MainActor
    private func load(silent: Bool = false) async {
        guard let token = session.bearerToken else {
            session.invalidateSession()
            return
        }
        if !silent { isLoading = true }
        errorMessage = nil
        defer { isLoading = false }

        do {
            visits = try await api.visits(token: token)
        } catch let error as ASUAdminAPI.APIError {
            if error.shouldDiscardSession {
                session.invalidateSession(notice: error.localizedDescription)
            } else {
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func update(_ visit: ASUAdminVisit, to status: ASUAdminVisitStatus) async {
        guard updatingID == nil else { return }
        guard let token = session.bearerToken else {
            session.invalidateSession()
            return
        }
        updatingID = visit.id
        errorMessage = nil
        defer { updatingID = nil }

        do {
            let updated = try await api.updateVisit(id: visit.id, status: status, token: token)
            if let index = visits.firstIndex(where: { $0.id == visit.id }) {
                visits[index] = updated
            }
        } catch let error as ASUAdminAPI.APIError {
            if error.shouldDiscardSession {
                session.invalidateSession(notice: error.localizedDescription)
            } else {
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
