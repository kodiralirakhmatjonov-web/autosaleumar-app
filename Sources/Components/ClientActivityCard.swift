import SwiftUI
import UIKit

struct ASUClientActivityCard: View {
    let activity: ASUClientActivity
    let language: AppLanguage
    let highlighted: Bool
    let onDelete: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var status: String {
        ASUClientStatusPresentation.normalized(activity.status, kind: activity.kind)
    }

    private var accent: Color {
        if status == "cancelled" { return Color(red: 0.67, green: 0.22, blue: 0.19) }
        switch activity.kind {
        case .vehicleRequest:
            switch status {
            case "contacted": return Color(red: 0.31, green: 0.39, blue: 0.68)
            case "sourcing": return ASUDesign.success
            case "offered": return Color(red: 0.43, green: 0.31, blue: 0.68)
            case "completed": return Color(red: 0.15, green: 0.48, blue: 0.34)
            default: return ASUDesign.orange
            }
        case .showroomVisit:
            switch status {
            case "confirmed": return ASUDesign.success
            case "completed": return Color(red: 0.15, green: 0.48, blue: 0.34)
            default: return ASUDesign.orange
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            statusBlock
            journey
            if activity.kind == .showroomVisit { visitSchedule }
            footer
        }
        .padding(18)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(highlighted ? ASUDesign.orange.opacity(0.88) : ASUDesign.line, lineWidth: highlighted ? 1.6 : 0.7)
        }
        .shadow(color: colorScheme == .light ? .black.opacity(0.045) : .clear, radius: 18, y: 8)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label(L10n.t("Удалить из истории", "Tarixdan o‘chirish", language), systemImage: "trash")
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 13) {
            ZStack {
                Circle().fill(accent.opacity(colorScheme == .dark ? 0.18 : 0.10))
                Image(systemName: ASUClientStatusPresentation.symbol(activity.status, kind: activity.kind))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(accent)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 5) {
                Text(activity.kind == .showroomVisit
                     ? L10n.t("ВИЗИТ В ШОУРУМ", "SHOURUM TASHRIFI", language)
                     : L10n.t("ПЕРСОНАЛЬНЫЙ ПОДБОР", "SHAXSIY TANLOV", language))
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .tracking(0.9)
                    .foregroundStyle(.secondary)

                Text(activity.title)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .tracking(-0.35)
                    .lineLimit(2)
            }

            Spacer(minLength: 6)
            statusPill
        }
    }

    private var statusPill: some View {
        HStack(spacing: 6) {
            Circle().fill(accent).frame(width: 6, height: 6)
            Text(ASUClientStatusPresentation.compactStatusTitle(activity.status, kind: activity.kind, language: language))
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .foregroundStyle(accent)
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(accent.opacity(colorScheme == .dark ? 0.16 : 0.09), in: Capsule())
        .overlay(Capsule().stroke(accent.opacity(0.14), lineWidth: 0.6))
    }

    private var statusBlock: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(ASUClientStatusPresentation.statusTitle(activity.status, kind: activity.kind, language: language))
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .tracking(-0.65)
            Text(ASUClientStatusPresentation.statusCaption(activity.status, kind: activity.kind, language: language))
                .font(.system(size: 13.5))
                .foregroundStyle(.secondary)
                .lineSpacing(3)
        }
    }

    private var journey: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(L10n.t("ПУТЬ ОБРАЩЕНИЯ", "MUROJAAT YO‘LI", language))
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(progressLabel)
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
            }

            GeometryReader { proxy in
                let width = max(0, proxy.size.width * ASUClientStatusPresentation.progress(activity.status, kind: activity.kind))
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.07))
                    Capsule().fill(accent).frame(width: width)
                }
            }
            .frame(height: 7)

            HStack {
                Text(startLabel)
                Spacer()
                Text(endLabel)
            }
            .font(.system(size: 10.5, weight: .medium, design: .rounded))
            .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color.primary.opacity(colorScheme == .dark ? 0.055 : 0.035), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var visitSchedule: some View {
        HStack(spacing: 10) {
            infoTile(
                symbol: "calendar",
                label: L10n.t("Дата", "Sana", language),
                value: activity.scheduledDate?.isEmpty == false ? activity.scheduledDate! : "—"
            )
            infoTile(
                symbol: "clock",
                label: L10n.t("Время", "Vaqt", language),
                value: activity.timeSlot?.isEmpty == false ? activity.timeSlot! : activity.subtitle
            )
        }
    }

    private func infoTile(symbol: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 3) {
                Text(label).font(.system(size: 9.5, weight: .medium, design: .rounded)).foregroundStyle(.tertiary)
                Text(value).font(.system(size: 12.5, weight: .bold, design: .rounded)).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.primary.opacity(colorScheme == .dark ? 0.055 : 0.035), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var footer: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(lastUpdateTitle)
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
                Text(lastUpdateValue)
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Button {
                UIPasteboard.general.string = activity.code
                ASUHaptics.selection()
            } label: {
                HStack(spacing: 7) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(L10n.t("КОД", "KOD", language))
                            .font(.system(size: 8.5, weight: .bold, design: .rounded))
                            .tracking(0.7)
                            .foregroundStyle(.tertiary)
                        Text(activity.code)
                            .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                    }
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 11)
                .frame(height: 42)
                .background(Color.primary.opacity(colorScheme == .dark ? 0.07 : 0.04), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 1)
    }

    private var progressLabel: String {
        if status == "cancelled" { return L10n.t("Закрыто", "Yopildi", language) }
        let value = Int((ASUClientStatusPresentation.progress(activity.status, kind: activity.kind) * 100).rounded())
        return "\(value)%"
    }

    private var startLabel: String {
        activity.kind == .showroomVisit
            ? L10n.t("Бронирование", "Band qilish", language)
            : L10n.t("Запрос", "So‘rov", language)
    }

    private var endLabel: String {
        activity.kind == .showroomVisit
            ? L10n.t("Визит", "Tashrif", language)
            : L10n.t("Результат", "Natija", language)
    }

    private var lastUpdateTitle: String {
        activity.lastSyncedAt == nil
            ? L10n.t("СОХРАНЕНО В ПРИЛОЖЕНИИ", "ILOVADA SAQLANGAN", language)
            : L10n.t("CONTROL SYSTEM · ОБНОВЛЕНО", "CONTROL SYSTEM · YANGILANDI", language)
    }

    private var lastUpdateValue: String {
        if let raw = activity.serverUpdatedAt, let date = Self.serverDateFormatter.date(from: raw) {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
        if let date = activity.lastSyncedAt {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
        return activity.createdAt.formatted(date: .abbreviated, time: .shortened)
    }

    private static let serverDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    private var cardBackground: some ShapeStyle {
        colorScheme == .dark ? AnyShapeStyle(ASUDesign.elevated) : AnyShapeStyle(Color.white)
    }
}

struct ASUClientCenterHandoff: View {
    let kind: ASUClientActivityKind
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.white.opacity(0.09))
                Circle().fill(ASUDesign.success).frame(width: 8, height: 8)
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 3) {
                Text("AUTO SALE UMAR · CLIENT CENTER")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(0.7)
                    .foregroundStyle(Color.white.opacity(0.54))
                Text(message)
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            Spacer(minLength: 4)
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.55))
        }
        .padding(13)
        .background(Color(red: 0.055, green: 0.058, blue: 0.063), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var message: String {
        switch kind {
        case .vehicleRequest:
            return L10n.t("Следите за подбором в Профиле", "Tanlov holatini Profil’da kuzating", language)
        case .showroomVisit:
            return L10n.t("Подтверждение появится в Профиле", "Tasdiq Profil’da paydo bo‘ladi", language)
        }
    }
}
