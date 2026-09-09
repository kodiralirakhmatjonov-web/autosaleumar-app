import SwiftUI
import PhotosUI
import UIKit

struct ASUAdminRamadanPhotoSection: View {
    @EnvironmentObject private var settings: AppSettings

    let group: ASUAdminRamadanPhotoGroup
    let media: [RamadanGiftMedia]
    let canUpload: Bool
    let isUploading: Bool
    let deletingID: Int?
    let upload: ([ASUAdminPendingPhoto]) -> Void
    let delete: (RamadanGiftMedia) -> Void

    @State private var selection: [PhotosPickerItem] = []
    @State private var isPreparing = false
    @State private var preparationError: String?
    @State private var pendingDelete: RamadanGiftMedia?

    private var groupMedia: [RamadanGiftMedia] {
        media
            .filter { $0.photoGroup == group.rawValue }
            .sorted { lhs, rhs in
                if lhs.isCover != rhs.isCover { return lhs.isCover && !rhs.isCover }
                if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
                return lhs.id < rhs.id
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.title(settings.language))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text(group == .exterior
                         ? L10n.t("Обложка и фотографии кузова", "Muqova va kuzov suratlari", settings.language)
                         : L10n.t("Интерьер подарочного автомобиля", "Sovg‘a avtomobil interyeri", settings.language))
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(String(groupMedia.count))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 30, minHeight: 30)
                    .background(ASUDesign.soft, in: Capsule())
            }

            if groupMedia.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 22, weight: .light))
                    Text(L10n.t("Фотографий пока нет", "Hozircha suratlar yo‘q", settings.language))
                        .font(.system(size: 12.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
                .padding(.horizontal, 14)
                .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(groupMedia) { item in
                            mediaTile(item)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
            }

            PhotosPicker(selection: $selection, maxSelectionCount: 12, matching: .images) {
                HStack(spacing: 9) {
                    if isPreparing || isUploading {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "plus")
                    }
                    Text(buttonTitle)
                    Spacer()
                    Text("JPG · 20 MB")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))
            }
            .buttonStyle(.plain)
            .disabled(!canUpload || isPreparing || isUploading)
            .opacity(canUpload ? 1 : 0.52)
            .onChange(of: selection) { _, items in
                guard !items.isEmpty else { return }
                Task { await prepare(items) }
            }

            if !canUpload {
                Text(L10n.t(
                    "Сначала сохраните Ramadan Gift — после этого станет доступна загрузка в R2.",
                    "Avval Ramadan Gift’ni saqlang — keyin R2 ga yuklash ochiladi.",
                    settings.language
                ))
                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            }

            if let preparationError {
                Label(preparationError, systemImage: "exclamationmark.triangle")
                    .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.red)
            }
        }
        .confirmationDialog(
            L10n.t("Удалить фотографию?", "Surat o‘chirilsinmi?", settings.language),
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(L10n.t("Удалить", "O‘chirish", settings.language), role: .destructive) {
                if let pendingDelete { delete(pendingDelete) }
                pendingDelete = nil
            }
            Button(L10n.t("Отмена", "Bekor qilish", settings.language), role: .cancel) {
                pendingDelete = nil
            }
        } message: {
            Text(L10n.t(
                "Фотография будет удалена из D1 и R2.",
                "Surat D1 va R2 dan o‘chiriladi.",
                settings.language
            ))
        }
    }

    private var buttonTitle: String {
        if isPreparing { return L10n.t("Подготавливаем…", "Tayyorlanmoqda…", settings.language) }
        if isUploading { return L10n.t("Загружаем в R2…", "R2 ga yuklanmoqda…", settings.language) }
        return L10n.t("Добавить фотографии", "Surat qo‘shish", settings.language)
    }

    private func mediaTile(_ item: RamadanGiftMedia) -> some View {
        ZStack(alignment: .topTrailing) {
            ASURemoteImage(
                url: ASUAdminRamadanMediaURL.resolve(item.publicUrl),
                contentMode: .fill,
                background: ASUDesign.gallery
            )
            .frame(width: 150, height: 106)
            .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 19, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))

            if item.isCover {
                Label(L10n.t("Обложка", "Muqova", settings.language), systemImage: "star.fill")
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .frame(height: 25)
                    .background(.black.opacity(0.64), in: Capsule())
                    .padding(7)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }

            if ASUAdminRamadanMediaURL.isManaged(item) {
                Button {
                    pendingDelete = item
                } label: {
                    Group {
                        if deletingID == item.id {
                            ProgressView().controlSize(.mini).tint(.white)
                        } else {
                            Image(systemName: "trash")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 31, height: 31)
                    .background(.black.opacity(0.64), in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(deletingID != nil || isUploading)
                .padding(7)
            } else {
                Text("DEFAULT")
                    .font(.system(size: 7.5, weight: .bold, design: .rounded))
                    .tracking(0.6)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .frame(height: 24)
                    .background(.black.opacity(0.58), in: Capsule())
                    .padding(7)
            }
        }
    }

    @MainActor
    private func prepare(_ items: [PhotosPickerItem]) async {
        isPreparing = true
        preparationError = nil
        defer {
            isPreparing = false
            selection = []
        }

        var photos: [ASUAdminPendingPhoto] = []
        for item in items.prefix(12) {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let optimized = Self.optimizedPhoto(data: data) else {
                    continue
                }
                photos.append(optimized)
            } catch {
                preparationError = L10n.t(
                    "Одну из фотографий не удалось прочитать.",
                    "Suratlardan birini o‘qib bo‘lmadi.",
                    settings.language
                )
            }
        }

        guard !photos.isEmpty else {
            if preparationError == nil {
                preparationError = L10n.t(
                    "Не удалось подготовить выбранные фотографии.",
                    "Tanlangan suratlarni tayyorlab bo‘lmadi.",
                    settings.language
                )
            }
            return
        }
        upload(photos)
    }

    private static func optimizedPhoto(data: Data) -> ASUAdminPendingPhoto? {
        guard let image = UIImage(data: data) else { return nil }
        let maxDimension: CGFloat = 2400
        let originalSize = image.size
        let longest = max(originalSize.width, originalSize.height)
        let output: UIImage

        if longest > maxDimension, originalSize.width > 0, originalSize.height > 0 {
            let ratio = maxDimension / longest
            let target = CGSize(width: max(1, originalSize.width * ratio), height: max(1, originalSize.height * ratio))
            let renderer = UIGraphicsImageRenderer(size: target)
            output = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: target))
            }
        } else {
            output = image
        }

        guard let jpeg = output.jpegData(compressionQuality: 0.86), !jpeg.isEmpty else { return nil }
        return ASUAdminPendingPhoto(
            data: jpeg,
            filename: "ramadan-\(UUID().uuidString.lowercased()).jpg",
            mimeType: "image/jpeg"
        )
    }
}
