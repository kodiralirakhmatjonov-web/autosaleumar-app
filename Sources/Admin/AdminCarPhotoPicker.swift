import SwiftUI
import PhotosUI
import UIKit

struct ASUAdminCarPhotoRail: View {
    @EnvironmentObject private var settings: AppSettings

    let group: ASUAdminPhotoGroup
    @Binding var existingPhotos: [ASUAdminCarDetailMedia]
    @Binding var newPhotos: [ASUAdminPendingPhoto]
    let deletingPhotoID: Int?
    let deleteExisting: (ASUAdminCarDetailMedia) -> Void

    @State private var selection: [PhotosPickerItem] = []
    @State private var isImporting = false
    @State private var importError: String?
    @State private var pendingDelete: ASUAdminCarDetailMedia?

    private var totalCount: Int { existingPhotos.count + newPhotos.count }
    private var remaining: Int { max(0, 16 - totalCount) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(group.title(settings.language))
                        .font(.system(size: 14.5, weight: .bold, design: .rounded))
                    Text(group.subtitle(settings.language))
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Text("\(totalCount)/16")
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            if totalCount > 0 {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(existingPhotos) { photo in
                            existingTile(photo)
                        }
                        ForEach(newPhotos) { photo in
                            pendingTile(photo)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 22, weight: .light))
                    Text(L10n.t("Фотографии ещё не добавлены", "Suratlar hali qo‘shilmagan", settings.language))
                        .font(.system(size: 12.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 78, alignment: .leading)
                .padding(.horizontal, 14)
                .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }

            PhotosPicker(
                selection: $selection,
                maxSelectionCount: max(1, remaining),
                matching: .images
            ) {
                HStack(spacing: 9) {
                    if isImporting {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "plus")
                    }
                    Text(isImporting
                         ? L10n.t("Подготавливаем фото…", "Suratlar tayyorlanmoqda…", settings.language)
                         : L10n.t("Добавить фотографии", "Surat qo‘shish", settings.language))
                    Spacer()
                    Text(L10n.t("до 16", "16 tagacha", settings.language))
                        .foregroundStyle(.secondary)
                }
                .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(ASUDesign.soft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))
            }
            .buttonStyle(.plain)
            .disabled(remaining == 0 || isImporting)
            .opacity(remaining == 0 ? 0.5 : 1)
            .onChange(of: selection) { _, items in
                guard !items.isEmpty else { return }
                Task { await importSelection(items) }
            }

            if let importError {
                Label(importError, systemImage: "exclamationmark.triangle")
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
                if let photo = pendingDelete { deleteExisting(photo) }
                pendingDelete = nil
            }
            Button(L10n.t("Отмена", "Bekor qilish", settings.language), role: .cancel) {
                pendingDelete = nil
            }
        } message: {
            Text(L10n.t(
                "Фотография будет удалена из D1 и R2 сразу.",
                "Surat D1 va R2 dan darhol o‘chiriladi.",
                settings.language
            ))
        }
    }

    private func existingTile(_ photo: ASUAdminCarDetailMedia) -> some View {
        ZStack(alignment: .topTrailing) {
            ASURemoteImage(url: mediaURL(photo.publicUrl), contentMode: .fill, background: ASUDesign.gallery)
                .frame(width: 132, height: 94)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))

            if photo.isCover {
                Image(systemName: "star.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(.black.opacity(0.58), in: Circle())
                    .padding(7)
            }

            Button {
                pendingDelete = photo
            } label: {
                Group {
                    if deletingPhotoID == photo.id {
                        ProgressView().controlSize(.mini).tint(.white)
                    } else {
                        Image(systemName: "trash")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 30, height: 30)
                .background(.black.opacity(0.62), in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(deletingPhotoID != nil)
            .padding(7)
            .offset(y: photo.isCover ? 34 : 0)
        }
    }

    private func pendingTile(_ photo: ASUAdminPendingPhoto) -> some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let image = UIImage(data: photo.data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    ASUDesign.gallery
                        .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                }
            }
            .frame(width: 132, height: 94)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))

            Button {
                newPhotos.removeAll { $0.id == photo.id }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(.black.opacity(0.62), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(7)

            Text(L10n.t("НОВОЕ", "YANGI", settings.language))
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .tracking(0.7)
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .frame(height: 22)
                .background(ASUDesign.success.opacity(0.86), in: Capsule())
                .padding(7)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
    }

    @MainActor
    private func importSelection(_ items: [PhotosPickerItem]) async {
        isImporting = true
        importError = nil
        defer {
            isImporting = false
            selection = []
        }

        var imported: [ASUAdminPendingPhoto] = []
        for item in items.prefix(remaining) {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let optimized = Self.optimizedPhoto(data: data) else {
                    continue
                }
                imported.append(optimized)
            } catch {
                importError = L10n.t("Одну из фотографий не удалось прочитать.", "Suratlardan birini o‘qib bo‘lmadi.", settings.language)
            }
        }

        if imported.isEmpty && importError == nil {
            importError = L10n.t("Не удалось подготовить выбранные фотографии.", "Tanlangan suratlarni tayyorlab bo‘lmadi.", settings.language)
        }
        newPhotos.append(contentsOf: imported.prefix(remaining))
    }

    private static func optimizedPhoto(data: Data) -> ASUAdminPendingPhoto? {
        guard let image = UIImage(data: data) else { return nil }
        let maxDimension: CGFloat = 2400
        let original = image.size
        let longest = max(original.width, original.height)
        let outputImage: UIImage

        if longest > maxDimension, longest > 0 {
            let scale = maxDimension / longest
            let target = CGSize(width: max(1, original.width * scale), height: max(1, original.height * scale))
            let format = UIGraphicsImageRendererFormat.default()
            format.scale = 1
            format.opaque = true
            outputImage = UIGraphicsImageRenderer(size: target, format: format).image { context in
                context.cgContext.setFillColor(UIColor.white.cgColor)
                context.cgContext.fill(CGRect(origin: .zero, size: target))
                image.draw(in: CGRect(origin: .zero, size: target))
            }
        } else {
            outputImage = image
        }

        var quality: CGFloat = 0.84
        guard var jpeg = outputImage.jpegData(compressionQuality: quality) else { return nil }
        while jpeg.count > 18 * 1024 * 1024 && quality > 0.48 {
            quality -= 0.10
            guard let next = outputImage.jpegData(compressionQuality: quality) else { break }
            jpeg = next
        }
        guard jpeg.count <= 20 * 1024 * 1024 else { return nil }
        return ASUAdminPendingPhoto(data: jpeg, filename: "asu-\(UUID().uuidString).jpg", mimeType: "image/jpeg")
    }

    private func mediaURL(_ value: String) -> URL? {
        let raw = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }
        if let absolute = URL(string: raw), absolute.scheme != nil { return absolute }
        return URL(string: raw, relativeTo: AppConfig.website)?.absoluteURL
    }
}
