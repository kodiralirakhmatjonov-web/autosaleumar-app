import SwiftUI
import Foundation

struct ASUAdminRequestsView: View {
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject var session: ASUAdminSessionStore

    @State private var requests: [ASUAdminVehicleRequest] = []
    @State private var filter: ASUAdminRequestStatus?
    @State private var isLoading = true
    @State private var updatingID: Int?
    @State private var errorMessage: String?

    private let api = ASUAdminOperationsAPI()

    private var filteredRequests: [ASUAdminVehicleRequest] {
        guard let filter else { return requests }
        return requests.filter { $0.status == filter }
    }

    private var activeRequests: [ASUAdminVehicleRequest] {
        requests.filter { $0.status != .completed && $0.status != .cancelled }
    }

    private var urgentCount: Int {
        activeRequests.lazy.filter { $0.purchaseTiming == .sevenDays || $0.purchaseTiming == .thirtyDays }.count
    }

    private var radar: [ASUAdminDemandSignal] {
        struct Key: Hashable { let brand: String; let model: String }
        struct MutableSignal { var brand: String; var model: String; var count: Int; var urgent: Int }

        var groups: [Key: MutableSignal] = [:]
        for item in activeRequests {
            let key = Key(
                brand: item.brand.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                model: item.model.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            )
            var group = groups[key] ?? MutableSignal(brand: item.brand, model: item.model, count: 0, urgent: 0)
            group.count += 1
            if item.purchaseTiming == .sevenDays || item.purchaseTiming == .thirtyDays { group.urgent += 1 }
            groups[key] = group
        }

        return groups.values
            .map { ASUAdminDemandSignal(brand: $0.brand, model: $0.model, count: $0.count, urgent: $0.urgent) }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                if lhs.urgent != rhs.urgent { return lhs.urgent > rhs.urgent }
                return "\(lhs.brand) \(lhs.model)" < "\(rhs.brand) \(rhs.model)"
            }
            .prefix(6)
            .map { $0 }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                hero
                demandRadar
                filters

                if let errorMessage { errorCard(errorMessage) }

                if isLoading && requests.isEmpty {
                    loadingState
                } else if filteredRequests.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredRequests) { item in
                            requestCard(item)
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
        .navigationTitle(L10n.t("Запросы", "So‘rovlar", settings.language))
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
                    colors: [Color.black, Color(red: 0.07, green: 0.07, blue: 0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Circle()
                .fill(ASUDesign.orange.opacity(0.20))
                .frame(width: 210, height: 210)
                .blur(radius: 44)
                .offset(x: 170, y: -105)

            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("AUTO SALE UMAR / DEMAND RADAR")
                        .font(.system(size: 9.3, weight: .bold, design: .rounded))
                        .tracking(1.0)
                    Spacer()
                    HStack(spacing: 6) {
                        Circle().fill(ASUDesign.success).frame(width: 7, height: 7)
                        Text("LIVE")
                    }
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white.opacity(0.60))

                Text(L10n.t("Запросы на автомобили", "Avtomobil so‘rovlari", settings.language))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .tracking(-1.15)
                    .foregroundStyle(.white)

                Text(L10n.t(
                    "Реальный спрос клиентов: модель, бюджет, срок покупки и параметры — без просмотров и лайков.",
                    "Mijozlarning real talabi: model, budjet, xarid muddati va parametrlar — ko‘rishlarsiz.",
                    settings.language
                ))
                .font(.system(size: 13.5))
                .foregroundStyle(.white.opacity(0.62))
                .lineSpacing(3)
            }
            .padding(21)
        }
        .frame(minHeight: 250)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 0.7))
    }

    private var demandRadar: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "gauge.with.dots.needle.67percent")
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(Color.primary.opacity(0.055), in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text("LIVE QUALIFIED DEMAND")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(1.0)
                        .foregroundStyle(.secondary)
                    Text("Demand Radar")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                }
                Spacer()
            }

            HStack(spacing: 9) {
                radarMetric(title: L10n.t("Активный спрос", "Faol talab", settings.language), value: activeRequests.count)
                radarMetric(title: L10n.t("До 30 дней", "30 kungacha", settings.language), value: urgentCount)
                radarMetric(title: L10n.t("Новые", "Yangi", settings.language), value: count(.new))
            }

            if radar.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                    Text(L10n.t(
                        "Пока недостаточно активных запросов для сводки.",
                        "Jamlanma uchun hozircha faol so‘rov yetarli emas.",
                        settings.language
                    ))
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            } else {
                VStack(spacing: 0) {
                    ForEach(radar.indices, id: \.self) { index in
                        let signal = radar[index]
                        HStack(spacing: 12) {
                            Text(String(format: "%02d", index + 1))
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(.secondary)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(signal.brand) \(signal.model)")
                                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                                    .lineLimit(1)
                                Text("\(signal.urgent) · \(L10n.t("до 30 дней", "30 kungacha", settings.language))")
                                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(signal.count) \(L10n.t("клиентов", "mijoz", settings.language))")
                                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        }
                        .padding(.vertical, 11)
                        if index < radar.count - 1 { Divider() }
                    }
                }
                .padding(.horizontal, 13)
                .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
        .padding(17)
        .asuCard(radius: 28)
    }

    private func radarMetric(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(String(value))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .tracking(-0.7)
            Text(title)
                .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 78, alignment: .topLeading)
        .padding(11)
        .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var filters: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                filterButton(status: nil, title: L10n.t("Все", "Barchasi", settings.language), count: requests.count)
                ForEach(ASUAdminRequestStatus.allCases) { status in
                    filterButton(status: status, title: status.shortTitle(settings.language), count: count(status))
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private func filterButton(status: ASUAdminRequestStatus?, title: String, count: Int) -> some View {
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

    private func requestCard(_ item: ASUAdminVehicleRequest) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(item.code) · \(dateTimeLabel(item.createdAt))")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .tracking(0.45)
                        .foregroundStyle(.secondary)
                    Text("\(item.brand) \(item.model)")
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                        .tracking(-0.45)
                    if let trim = cleanOptional(item.trim) {
                        Text(trim)
                            .font(.system(size: 12.5, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 8)
                requestStatusPill(item.status)
            }

            HStack(spacing: 9) {
                keyFact(symbol: "dollarsign.circle", label: L10n.t("Бюджет", "Budjet", settings.language), value: budgetLabel(item))
                keyFact(symbol: "clock", label: L10n.t("Срок", "Muddat", settings.language), value: timingLabel(item.purchaseTiming))
            }

            let chips = specificationChips(item)
            if !chips.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 7) {
                        ForEach(chips, id: \.self) { chip in
                            Text(chip)
                                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                                .padding(.horizontal, 10)
                                .frame(height: 30)
                                .background(ASUDesign.soft, in: Capsule())
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }

            if let options = cleanOptional(item.importantOptions) {
                textBlock(title: L10n.t("Опции", "Opsiyalar", settings.language), text: options)
            }
            if let note = cleanOptional(item.note) {
                textBlock(title: L10n.t("Комментарий", "Izoh", settings.language), text: note)
            }

            customerBlock(item)

            if let source = sourceURL(item.sourceUrl) {
                Link(destination: source) {
                    HStack(spacing: 8) {
                        Image(systemName: "link")
                        Text(L10n.t("Открыть пример", "Namunani ochish", settings.language))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 13)
                    .frame(height: 44)
                    .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                Text(L10n.t("Ссылка-пример не указана", "Namuna havolasi ko‘rsatilmagan", settings.language))
                    .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                if item.status == .cancelled {
                    statusAction(item, status: .new, title: L10n.t("Вернуть в новые", "Yangi holatga", settings.language), prominent: true)
                } else if item.status == .completed {
                    statusAction(item, status: .new, title: L10n.t("Вернуть в новые", "Yangi holatga", settings.language), prominent: false)
                    Menu { statusMenu(item) } label: { moreButton }
                } else {
                    let next = nextStatus(for: item.status)
                    statusAction(item, status: next.status, title: next.title, prominent: true)
                    Menu { statusMenu(item) } label: { moreButton }
                }
            }
        }
        .padding(17)
        .asuCard(radius: 28)
        .opacity(updatingID == item.id ? 0.62 : 1)
    }

    private func keyFact(symbol: String, label: String, value: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .tracking(0.6)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 11)
        .frame(height: 54)
        .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
    }

    private func textBlock(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased())
                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                .tracking(0.7)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.system(size: 12.5, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private func customerBlock(_ item: ASUAdminVehicleRequest) -> some View {
        let destination = contactURL(item)
        VStack(spacing: 0) {
            HStack(spacing: 11) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.contactChannel.rawValue.uppercased())
                        .font(.system(size: 8.5, weight: .bold, design: .rounded))
                        .tracking(0.7)
                        .foregroundStyle(.secondary)
                    Text(item.customerName)
                        .font(.system(size: 13.5, weight: .bold, design: .rounded))
                }
                Spacer()
            }
            .padding(.vertical, 11)

            Divider()

            if let destination {
                Link(destination: destination) {
                    HStack(spacing: 10) {
                        Image(systemName: contactSymbol(item.contactChannel))
                            .frame(width: 30)
                        Text(item.phone)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.primary)
                    .padding(.vertical, 11)
                }
                .buttonStyle(.plain)
            } else {
                HStack { Text(item.phone); Spacer() }
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .padding(.vertical, 11)
            }
        }
        .padding(.horizontal, 13)
        .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func statusAction(_ item: ASUAdminVehicleRequest, status: ASUAdminRequestStatus, title: String, prominent: Bool) -> some View {
        Button {
            Task { await update(item, to: status) }
        } label: {
            HStack(spacing: 8) {
                if updatingID == item.id {
                    ProgressView().controlSize(.mini).tint(prominent ? Color.white : Color.primary)
                } else {
                    Image(systemName: statusSymbol(status))
                }
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
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

    @ViewBuilder
    private func statusMenu(_ item: ASUAdminVehicleRequest) -> some View {
        ForEach(ASUAdminRequestStatus.allCases.filter { $0 != item.status }) { status in
            Button(role: status == .cancelled ? .destructive : nil) {
                Task { await update(item, to: status) }
            } label: {
                Label(status.title(settings.language), systemImage: statusSymbol(status))
            }
        }
    }

    private var moreButton: some View {
        Image(systemName: "ellipsis")
            .font(.system(size: 14, weight: .bold))
            .frame(width: 44, height: 44)
            .background(ASUDesign.soft, in: Circle())
    }

    private func requestStatusPill(_ status: ASUAdminRequestStatus) -> some View {
        HStack(spacing: 6) {
            Circle().fill(requestStatusColor(status)).frame(width: 7, height: 7)
            Text(status.title(settings.language))
                .font(.system(size: 10, weight: .bold, design: .rounded))
        }
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(requestStatusColor(status).opacity(0.11), in: Capsule())
    }

    private func requestStatusColor(_ status: ASUAdminRequestStatus) -> Color {
        switch status {
        case .new: return .blue
        case .contacted: return ASUDesign.orange
        case .sourcing: return .purple
        case .offered: return .indigo
        case .completed: return ASUDesign.success
        case .cancelled: return .secondary
        }
    }

    private func statusSymbol(_ status: ASUAdminRequestStatus) -> String {
        switch status {
        case .new: return "arrow.uturn.backward"
        case .contacted: return "message"
        case .sourcing: return "magnifyingglass"
        case .offered: return "checkmark.seal"
        case .completed: return "checkmark.circle"
        case .cancelled: return "xmark.circle"
        }
    }

    private func nextStatus(for current: ASUAdminRequestStatus) -> (status: ASUAdminRequestStatus, title: String) {
        switch current {
        case .new:
            return (.contacted, L10n.t("Связались", "Bog‘landik", settings.language))
        case .contacted:
            return (.sourcing, L10n.t("Начать подбор", "Qidiruvni boshlash", settings.language))
        case .sourcing:
            return (.offered, L10n.t("Предложение отправлено", "Taklif yuborildi", settings.language))
        case .offered:
            return (.completed, L10n.t("Сделка", "Savdo", settings.language))
        case .completed, .cancelled:
            return (.new, L10n.t("Вернуть в новые", "Yangi holatga", settings.language))
        }
    }

    private func count(_ status: ASUAdminRequestStatus) -> Int {
        requests.lazy.filter { $0.status == status }.count
    }

    private func budgetLabel(_ item: ASUAdminVehicleRequest) -> String {
        guard let value = item.maxBudget, value > 0 else { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = " "
        let number = formatter.string(from: NSNumber(value: value)) ?? String(Int64(value))
        switch item.currency {
        case .USD: return "\(number) $"
        case .EUR: return "\(number) €"
        case .UZS: return "\(number) \(L10n.t("сум", "so‘m", settings.language))"
        }
    }

    private func timingLabel(_ timing: PurchaseTiming) -> String {
        switch timing {
        case .sevenDays: return L10n.t("7 дней", "7 kun", settings.language)
        case .thirtyDays: return L10n.t("30 дней", "30 kun", settings.language)
        case .ninetyDays: return L10n.t("3 месяца", "3 oy", settings.language)
        case .flexible: return L10n.t("Без жёсткого срока", "Muddat erkin", settings.language)
        }
    }

    private func specificationChips(_ item: ASUAdminVehicleRequest) -> [String] {
        var result: [String] = []
        if let year = item.desiredYear { result.append(String(year)) }
        if let exterior = cleanOptional(item.exteriorColor) { result.append(exterior) }
        if let interior = cleanOptional(item.interiorColor) { result.append(interior) }
        result.append(item.acceptInTransit
            ? L10n.t("Готов рассмотреть авто в пути", "Yo‘ldagi avtomobilni ham ko‘radi", settings.language)
            : L10n.t("Только авто в продаже сейчас", "Faqat hozir sotuvdagi avtomobil", settings.language))
        return result
    }

    private func cleanOptional(_ value: String?) -> String? {
        guard let value else { return nil }
        let clean = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? nil : clean
    }

    private func sourceURL(_ raw: String?) -> URL? {
        guard let raw = cleanOptional(raw), let url = URL(string: raw), let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else { return nil }
        return url
    }

    private func contactURL(_ item: ASUAdminVehicleRequest) -> URL? {
        let digits = item.phone.filter { $0.isNumber }
        switch item.contactChannel {
        case .whatsapp:
            guard !digits.isEmpty else { return nil }
            return URL(string: "https://wa.me/\(digits)")
        case .telegram:
            let clean = item.phone.trimmingCharacters(in: .whitespacesAndNewlines)
            if clean.hasPrefix("@"), clean.count > 1 {
                return URL(string: "https://t.me/\(String(clean.dropFirst()))")
            }
            guard !digits.isEmpty else { return nil }
            return URL(string: "tel:\(digits)")
        case .phone:
            guard !digits.isEmpty else { return nil }
            return URL(string: "tel:\(digits)")
        }
    }

    private func contactSymbol(_ channel: ContactChannel) -> String {
        switch channel {
        case .whatsapp: return "message.fill"
        case .telegram: return "paperplane.fill"
        case .phone: return "phone.fill"
        }
    }

    private func dateTimeLabel(_ raw: String) -> String {
        let normalized = raw.contains("T") ? raw : raw.replacingOccurrences(of: " ", with: "T") + "Z"
        let isoFractional = ISO8601DateFormatter()
        isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        guard let date = isoFractional.date(from: normalized) ?? iso.date(from: normalized) else { return raw }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: settings.language == .ru ? "ru_RU" : "uz_UZ")
        formatter.dateFormat = "d MMM, HH:mm"
        return formatter.string(from: date)
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(L10n.t("Загружаем запросы…", "So‘rovlar yuklanmoqda…", settings.language))
                .font(.system(size: 13.5, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .asuCard(radius: 28)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28, weight: .light))
            Text(L10n.t("В этой категории запросов пока нет.", "Bu bo‘limda hozircha so‘rov yo‘q.", settings.language))
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
                Text(L10n.t("Не удалось обновить запросы", "So‘rovlarni yangilab bo‘lmadi", settings.language))
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
            requests = try await api.vehicleRequests(token: token)
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
    private func update(_ item: ASUAdminVehicleRequest, to status: ASUAdminRequestStatus) async {
        guard updatingID == nil else { return }
        guard let token = session.bearerToken else {
            session.invalidateSession()
            return
        }
        updatingID = item.id
        errorMessage = nil
        defer { updatingID = nil }

        do {
            let updated = try await api.updateVehicleRequest(id: item.id, status: status, token: token)
            if let index = requests.firstIndex(where: { $0.id == item.id }) {
                requests[index] = updated
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
