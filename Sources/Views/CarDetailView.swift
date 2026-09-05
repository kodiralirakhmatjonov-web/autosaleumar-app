import SwiftUI

struct CarDetailView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: AppStore
    @Environment(\.openURL) private var openURL

    let car: Car

    @State private var detail: CarDetail?
    @State private var loadError: String?
    @State private var selectedVariant = 0
    @State private var selectedPhoto = 0
    @State private var showContact = false
    @State private var showBooking = false
    @State private var showGallery = false

    private var activeVariant: CarVariant? {
        guard let detail, !detail.variants.isEmpty else { return nil }
        return detail.variants[min(selectedVariant, detail.variants.count - 1)]
    }

    private var exteriorPhotos: [CarPhoto] {
        if let activeVariant, !activeVariant.photos.isEmpty { return activeVariant.photos }
        if let detail, !detail.exteriorPhotos.isEmpty { return detail.exteriorPhotos }
        return car.galleryImageURLs.enumerated().map { CarPhoto(id: -1000 - $0.offset, url: $0.element, isCover: $0.offset == 0, sortOrder: $0.offset) }
    }

    private var interiorPhotos: [CarPhoto] { activeVariant?.interiorPhotos ?? detail?.interiorPhotos ?? [] }
    private var detailPhotos: [CarPhoto] { activeVariant?.detailPhotos ?? [] }
    private var galleryPhotos: [CarPhoto] {
        var seen = Set<String>()
        return (exteriorPhotos + interiorPhotos + detailPhotos).filter { seen.insert($0.url.absoluteString).inserted }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                brandStage
                brandMedallion
                heroSection
                editorialSection
                detailPhotoRail
                performanceSection
                interiorSection
                variantsSection
                gallerySection
                specificationSection
                availabilitySection
            }
            .padding(.bottom, 34)
        }
        .scrollIndicators(.hidden)
        .background(ASUDesign.page)
        .navigationTitle(car.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    withAnimation(ASUDesign.spring) { store.toggleFavorite(car) }
                } label: {
                    Image(systemName: store.isFavorite(car) ? "heart.fill" : "heart")
                        .foregroundStyle(store.isFavorite(car) ? ASUDesign.orange : Color.primary)
                }
                ShareLink(item: AppConfig.carShareURL(car)) { Image(systemName: "square.and.arrow.up") }
            }
        }
        .sheet(isPresented: $showContact) { ContactSheet(car: car) }
        .sheet(isPresented: $showBooking) { CarBookingSheet(car: car) }
        .fullScreenCover(isPresented: $showGallery) {
            FullScreenCarGallery(title: car.displayName, photos: galleryPhotos, initialIndex: selectedPhoto)
        }
        .task(id: car.slug) { await loadDetail() }
    }

    private var brandStage: some View {
        ZStack {
            LinearGradient(colors: [Color.black, Color(red: 0.06, green: 0.06, blue: 0.065)], startPoint: .top, endPoint: .bottom)

            if let photo = exteriorPhotos.first {
                ASURemoteImage(url: photo.url, contentMode: .fill, background: .black)
                    .opacity(0.46)
                    .overlay(LinearGradient(colors: [.black.opacity(0.18), .black.opacity(0.72)], startPoint: .top, endPoint: .bottom))
            }

            VStack(spacing: 12) {
                Spacer()
                if let asset = brandAsset {
                    Image(asset)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 190, maxHeight: 76)
                        .grayscale(1)
                        .colorInvert()
                        .blendMode(.screen)
                } else {
                    Text(car.brand.uppercased())
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                Text("AUTO SALE UMAR · \(car.brand.uppercased())")
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .tracking(2.1)
                    .foregroundStyle(.white.opacity(0.72))
                Spacer().frame(height: 32)
            }
        }
        .frame(height: 250)
        .clipped()
    }

    private var brandMedallion: some View {
        VStack(spacing: 7) {
            ASUGlassCircleSurface(size: 94) {
                if let asset = brandAsset {
                    Image(asset)
                        .resizable()
                        .scaledToFit()
                        .grayscale(1)
                        .padding(20)
                } else {
                    Text(car.brand.prefix(2).uppercased())
                        .font(.system(size: 19, weight: .black, design: .rounded))
                }
            }
            .background(ASUDesign.page, in: Circle())
            Text(car.brand)
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .offset(y: -47)
        .padding(.bottom, -34)
    }

    private var heroSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 11) {
                Text(heroEyebrow)
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .tracking(1.25)
                    .foregroundStyle(.secondary)

                Text(car.displayName)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .tracking(-1.7)
                    .lineSpacing(-4)

                HStack(alignment: .center) {
                    StatusPill(status: detail?.status ?? car.status, language: settings.language)
                    Spacer()
                    Text(detail.map { Format.price($0, language: settings.language) } ?? Format.price(car, language: settings.language))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.trailing)
                }

                if let short = detail?.shortDescription(settings.language) ?? car.description(settings.language), !short.isEmpty {
                    Text(short)
                        .font(.system(size: 15.5))
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                }

                ASUGlassContainer(spacing: 9) {
                    HStack(spacing: 9) {
                        Button { showBooking = true } label: {
                            Label(L10n.t("Забронировать визит", "Tashrifni band qilish", settings.language), systemImage: "calendar")
                                .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color(uiColor: .systemBackground))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.primary, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        ASUGlassIconButton(
                            symbol: store.isCompared(car) ? "rectangle.2.swap.fill" : "rectangle.2.swap",
                            size: 52,
                            accessibilityLabel: L10n.t("Сравнить", "Solishtirish", settings.language)
                        ) { store.toggleCompare(car) }
                    }
                }
            }
            .padding(.horizontal, ASUDesign.pagePadding)

            heroGallery
            specStrip
        }
        .padding(.top, 10)
    }

    private var heroGallery: some View {
        ZStack(alignment: .bottom) {
            if exteriorPhotos.isEmpty {
                CarImage(url: car.primaryImageURL, height: 360)
            } else {
                TabView(selection: $selectedPhoto) {
                    ForEach(exteriorPhotos.indices, id: \.self) { index in
                        let photo = exteriorPhotos[index]
                        ASURemoteImage(url: photo.url, contentMode: .fit, background: ASUDesign.gallery, padding: 8)
                            .tag(index)
                            .onTapGesture { showGallery = true }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }

            if exteriorPhotos.count > 1 {
                ASUGlassSurface(radius: 18) {
                    Text("\(min(selectedPhoto + 1, exteriorPhotos.count)) / \(exteriorPhotos.count)")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .padding(.horizontal, 13)
                        .frame(height: 34)
                }
                .padding(.bottom, 14)
            }
        }
        .frame(height: 360)
        .background(ASUDesign.gallery)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))
        .padding(.horizontal, ASUDesign.pagePadding)
        .asuStoryTransition()
    }

    private var specStrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 9) {
                ForEach(primarySpecs, id: \.label) { item in
                    VStack(alignment: .leading, spacing: 7) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 17, weight: .medium))
                        Text(item.value)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Text(item.label)
                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(width: 128, height: 90, alignment: .leading)
                    .padding(14)
                    .asuCard(radius: 22, shadow: false)
                }
            }
            .padding(.horizontal, ASUDesign.pagePadding)
            .padding(.vertical, 3)
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private var editorialSection: some View {
        let text = detail?.description(settings.language) ?? car.description(settings.language)
        if text != nil || !galleryPhotos.isEmpty {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.t("ХАРАКТЕР В ДЕТАЛЯХ", "XARAKTER DETALLARDA", settings.language))
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .tracking(1.3)
                        .foregroundStyle(.secondary)
                    Text(L10n.t("Автомобиль, который раскрывается ближе.", "Yaqindan yanada ko‘proq ochiladigan avtomobil.", settings.language))
                        .asuSectionTitle(size: 34)
                    Text(text ?? L10n.t("Фотографии и характеристики относятся к конкретному автомобилю из базы Auto Sale Umar.", "Suratlar va xususiyatlar Auto Sale Umar bazasidagi aniq avtomobilga tegishli.", settings.language))
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                }
                .padding(22)
                .asuCard(radius: 28)

                if let photo = galleryPhotos.first {
                    ASURemoteImage(url: photo.url, contentMode: .fill, background: ASUDesign.gallery)
                        .frame(height: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))
                }
            }
            .padding(.horizontal, ASUDesign.pagePadding)
            .padding(.top, 54)
            .asuStoryTransition()
        }
    }

    @ViewBuilder
    private var detailPhotoRail: some View {
        let photos = Array((detailPhotos + interiorPhotos + Array(exteriorPhotos.dropFirst())).prefix(5))
        if !photos.isEmpty {
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(photos.indices, id: \.self) { index in
                        let photo = photos[index]
                        ZStack(alignment: .bottomLeading) {
                            ASURemoteImage(url: photo.url, contentMode: .fill, background: ASUDesign.gallery)
                                .frame(width: 275, height: 280)
                            LinearGradient(colors: [.clear, .black.opacity(0.68)], startPoint: .center, endPoint: .bottom)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(index == 0 && !interiorPhotos.isEmpty ? L10n.t("САЛОН", "SALON", settings.language) : L10n.t("ЭКСТЕРЬЕР", "TASHQI KO‘RINISH", settings.language))
                                    .font(.system(size: 9.5, weight: .bold, design: .rounded)).tracking(1.1)
                                Text(index == 0 && !interiorPhotos.isEmpty ? selectedInteriorColor : selectedExteriorColor)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .padding(17)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                            content.scaleEffect(phase.isIdentity ? 1 : 0.95).opacity(phase.isIdentity ? 1 : 0.82)
                        }
                    }
                }
                .padding(.horizontal, ASUDesign.pagePadding)
            }
            .scrollIndicators(.hidden)
            .padding(.top, 20)
        }
    }

    @ViewBuilder
    private var performanceSection: some View {
        if let performance = detail?.performance, performance.hasValues {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.t("ДИНАМИКА", "DINAMIKA", settings.language))
                        .font(.system(size: 10.5, weight: .bold, design: .rounded)).tracking(1.4).foregroundStyle(.white.opacity(0.55))
                    Text(L10n.t("Уверенность в каждом движении.", "Har bir harakatda ishonch.", settings.language))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .tracking(-1.25)
                        .foregroundStyle(.white)
                }

                if let hero = performance.horsepowerHp ?? performance.torqueNm ?? performance.topSpeedKmh {
                    Text("\(hero)")
                        .font(.system(size: 112, weight: .black, design: .rounded))
                        .tracking(-6)
                        .foregroundStyle(.white.opacity(0.10))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .frame(height: 100)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 0) {
                    ForEach(performanceItems(performance), id: \.label) { item in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.value)
                                .font(.system(size: 25, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text(item.label)
                                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.52))
                        }
                        .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
                        .padding(.top, 15)
                        .overlay(alignment: .top) { Rectangle().fill(Color.white.opacity(0.10)).frame(height: 0.7) }
                    }
                }
            }
            .padding(24)
            .background(Color(red: 0.035, green: 0.035, blue: 0.04), in: RoundedRectangle(cornerRadius: 32, style: .continuous))
            .padding(.horizontal, ASUDesign.pagePadding)
            .padding(.top, 58)
            .asuStoryTransition()
        }
    }

    @ViewBuilder
    private var interiorSection: some View {
        if let photo = interiorPhotos.first {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(L10n.t("ИНТЕРЬЕР", "INTERYER", settings.language))
                        .font(.system(size: 10.5, weight: .bold, design: .rounded)).tracking(1.4).foregroundStyle(.secondary)
                    Text(L10n.t("Тишина становится частью автомобиля.", "Sokinlik avtomobilning bir qismiga aylanadi.", settings.language))
                        .asuSectionTitle(size: 34)
                    colorSummary
                }
                .padding(22)
                .asuCard(radius: 28)

                ASURemoteImage(url: photo.url, contentMode: .fill, background: ASUDesign.gallery)
                    .frame(height: 350)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))
            }
            .padding(.horizontal, ASUDesign.pagePadding)
            .padding(.top, 52)
            .asuStoryTransition()
        }
    }

    @ViewBuilder
    private var variantsSection: some View {
        if let detail, detail.variants.count > 1 {
            VStack(alignment: .leading, spacing: 17) {
                Text(L10n.t("ДОСТУПНЫЕ ЦВЕТА", "MAVJUD RANGLAR", settings.language))
                    .font(.system(size: 10.5, weight: .bold, design: .rounded)).tracking(1.4).foregroundStyle(.secondary)
                Text(L10n.t("Выберите свой оттенок.", "O‘zingizga mos rangni tanlang.", settings.language))
                    .asuSectionTitle(size: 34)

                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(detail.variants.indices, id: \.self) { index in
                            let variant = detail.variants[index]
                            Button {
                                withAnimation(ASUDesign.spring) {
                                    selectedVariant = index
                                    selectedPhoto = 0
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(Color(asuHex: variant.exteriorSwatch, fallback: .primary))
                                        .frame(width: 43, height: 43)
                                        .overlay(Circle().stroke(ASUDesign.lineStrong, lineWidth: 1))
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(variant.exteriorColorName ?? L10n.t("Цвет \(index + 1)", "Rang \(index + 1)", settings.language))
                                            .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                                        if let interior = variant.interiorColorName, !interior.isEmpty {
                                            Text(interior).font(.system(size: 11.5, design: .rounded)).foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .padding(.horizontal, 14)
                                .frame(width: 235, height: 72, alignment: .leading)
                                .background {
                                    if selectedVariant == index {
                                        RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.primary, lineWidth: 2)
                                    }
                                }
                                .modifier(VariantGlass(active: selectedVariant != index))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal, ASUDesign.pagePadding)
            .padding(.top, 58)
        }
    }

    @ViewBuilder
    private var gallerySection: some View {
        if galleryPhotos.count > 2 {
            VStack(alignment: .leading, spacing: 17) {
                Text(L10n.t("ГАЛЕРЕЯ", "GALEREYA", settings.language))
                    .font(.system(size: 10.5, weight: .bold, design: .rounded)).tracking(1.4).foregroundStyle(.secondary)
                Text(L10n.t("Посмотрите автомобиль со всех сторон.", "Avtomobilni har tomondan ko‘ring.", settings.language))
                    .asuSectionTitle(size: 34)

                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(galleryPhotos.indices, id: \.self) { index in
                            let photo = galleryPhotos[index]
                            ASURemoteImage(url: photo.url, contentMode: .fill, background: ASUDesign.gallery)
                                .frame(width: 310, height: 260)
                                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(ASUDesign.line, lineWidth: 0.7))
                                .onTapGesture { selectedPhoto = index; showGallery = true }
                                .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                                    content.scaleEffect(phase.isIdentity ? 1 : 0.94).opacity(phase.isIdentity ? 1 : 0.80)
                                }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal, ASUDesign.pagePadding)
            .padding(.top, 58)
        }
    }

    private var specificationSection: some View {
        let specs = secondarySpecs
        return Group {
            if !specs.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Label(L10n.t("Характеристики", "Xususiyatlar", settings.language), systemImage: "gauge.with.dots.needle.67percent")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 0) {
                        ForEach(specs, id: \.label) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.label).font(.system(size: 10.5, design: .rounded)).foregroundStyle(.secondary)
                                Text(item.value).font(.system(size: 14.5, weight: .semibold, design: .rounded)).lineLimit(2)
                            }
                            .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
                            .padding(.top, 13)
                            .overlay(alignment: .top) { Rectangle().fill(ASUDesign.line).frame(height: 0.7) }
                        }
                    }
                }
                .padding(22)
                .asuCard(radius: 28)
                .padding(.horizontal, ASUDesign.pagePadding)
                .padding(.top, 46)
            }
        }
    }

    private var availabilitySection: some View {
        VStack(spacing: 0) {
            if let photo = galleryPhotos.first {
                ASURemoteImage(url: photo.url, contentMode: .fill, background: .black)
                    .frame(height: 245)
                    .clipped()
            }

            VStack(alignment: .leading, spacing: 14) {
                Label(L10n.t("Автомобиль доступен", "Avtomobil mavjud", settings.language), systemImage: "checkmark.shield")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.66))
                Text(car.displayName)
                    .font(.system(size: 33, weight: .bold, design: .rounded))
                    .tracking(-1)
                    .foregroundStyle(.white)
                Text(detail.map { Format.price($0, language: settings.language) } ?? Format.price(car, language: settings.language))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(L10n.t("Запишитесь на просмотр или свяжитесь с менеджером Auto Sale Umar.", "Ko‘rishga yoziling yoki Auto Sale Umar menejeri bilan bog‘laning.", settings.language))
                    .font(.system(size: 14.5)).foregroundStyle(.white.opacity(0.60)).lineSpacing(3)

                Button { showBooking = true } label: {
                    Label(L10n.t("Забронировать визит", "Tashrifni band qilish", settings.language), systemImage: "calendar")
                        .font(.system(size: 15.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(.white, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
                }
                .buttonStyle(.plain)

                Button { showContact = true } label: {
                    Label(L10n.t("Связаться с менеджером", "Menejer bilan bog‘lanish", settings.language), systemImage: "message")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 19, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 19, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 0.7))
                }
                .buttonStyle(.plain)

                if let instagram = detail?.instagramURL {
                    Button { openURL(instagram) } label: {
                        Label(L10n.t("Смотреть обзор в Instagram", "Instagram sharhini ko‘rish", settings.language), systemImage: "play.rectangle")
                            .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity).frame(height: 48)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(22)
            .background(Color(red: 0.035, green: 0.035, blue: 0.04))
        }
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .padding(.horizontal, ASUDesign.pagePadding)
        .padding(.top, 54)
    }

    private var colorSummary: some View {
        VStack(spacing: 0) {
            if !selectedExteriorColor.isEmpty {
                colorRow(title: L10n.t("Выбранный цвет", "Tanlangan rang", settings.language), value: selectedExteriorColor, swatch: activeVariant?.exteriorSwatch ?? "#111214")
            }
            if !selectedInteriorColor.isEmpty {
                colorRow(title: L10n.t("Цвет салона", "Salon rangi", settings.language), value: selectedInteriorColor, swatch: activeVariant?.interiorSwatch ?? "#111214")
            }
        }
    }

    private func colorRow(title: String, value: String, swatch: String) -> some View {
        HStack(spacing: 12) {
            Circle().fill(Color(asuHex: swatch, fallback: .primary)).frame(width: 36, height: 36).overlay(Circle().stroke(ASUDesign.lineStrong, lineWidth: 1))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 10.5, design: .rounded)).foregroundStyle(.secondary)
                Text(value).font(.system(size: 14.5, weight: .semibold, design: .rounded))
            }
            Spacer()
        }
        .padding(.vertical, 11)
        .overlay(alignment: .top) { Rectangle().fill(ASUDesign.line).frame(height: 0.7) }
    }

    private var heroEyebrow: String {
        let year = detail?.year ?? car.year
        let descriptor = detail?.trim ?? car.trim ?? detail?.engineText ?? car.engineText ?? car.brand
        return [year.map(String.init), descriptor].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
    }

    private var brandAsset: String? {
        ASUHomeContent.brands.first { $0.name.caseInsensitiveCompare(car.brand) == .orderedSame }?.assetName
    }

    private var selectedExteriorColor: String {
        activeVariant?.exteriorColorName ?? detail?.exteriorColor ?? car.exteriorColor ?? ""
    }

    private var selectedInteriorColor: String {
        activeVariant?.interiorColorName ?? detail?.interiorColor ?? car.interiorColor ?? ""
    }

    private var primarySpecs: [SpecItem] {
        let detail = self.detail
        var items: [SpecItem] = []
        if let year = detail?.year ?? car.year { items.append(.init(symbol: "calendar", label: L10n.t("Год", "Yil", settings.language), value: "\(year)")) }
        items.append(.init(symbol: "gauge.with.dots.needle.33percent", label: L10n.t("Пробег", "Yurgan", settings.language), value: "\(detail?.mileageKm ?? car.mileageKm ?? 0) км"))
        if let engine = detail?.engineText ?? car.engineText, !engine.isEmpty { items.append(.init(symbol: "engine.combustion", label: L10n.t("Двигатель", "Dvigatel", settings.language), value: engine)) }
        if let drive = detail?.driveType ?? car.driveType, !drive.isEmpty { items.append(.init(symbol: "arrow.triangle.branch", label: L10n.t("Привод", "Uzatma", settings.language), value: drive)) }
        if let transmission = detail?.transmission ?? car.transmission, !transmission.isEmpty { items.append(.init(symbol: "gearshape.2", label: L10n.t("Коробка", "Quti", settings.language), value: transmission)) }
        if let seats = detail?.seats ?? car.seats { items.append(.init(symbol: "person.2", label: L10n.t("Мест", "O‘rin", settings.language), value: "\(seats)")) }
        return Array(items.prefix(6))
    }

    private var secondarySpecs: [SpecItem] {
        var items: [SpecItem] = []
        let d = detail
        if let fuel = d?.fuelType ?? car.fuelType, !fuel.isEmpty { items.append(.init(symbol: "fuelpump", label: L10n.t("Топливо", "Yoqilg‘i", settings.language), value: fuel)) }
        if let country = countryLabel(d?.countryCode ?? car.countryCode) { items.append(.init(symbol: "globe", label: L10n.t("Рынок поставки", "Yetkazib berish bozori", settings.language), value: country)) }
        if let arrival = d?.arrivalDate ?? car.arrivalDate, !arrival.isEmpty { items.append(.init(symbol: "calendar.badge.clock", label: L10n.t("Ожидаемая дата", "Kutilayotgan sana", settings.language), value: arrival)) }
        if let engine = d?.performance.engineDisplacementL { items.append(.init(symbol: "engine.combustion", label: L10n.t("Объём", "Hajm", settings.language), value: String(format: "%.1f L", engine))) }
        if let economy = d?.performance.fuelConsumptionL100 { items.append(.init(symbol: "drop", label: L10n.t("Расход", "Sarf", settings.language), value: String(format: "%.1f л/100", economy))) }
        if let range = d?.performance.electricRangeKm { items.append(.init(symbol: "bolt", label: L10n.t("Запас хода", "Yurish zaxirasi", settings.language), value: "\(range) км")) }
        if let exterior = d?.exteriorColor ?? car.exteriorColor, !exterior.isEmpty { items.append(.init(symbol: "paintpalette", label: L10n.t("Цвет кузова", "Kuzov rangi", settings.language), value: exterior)) }
        if let interior = d?.interiorColor ?? car.interiorColor, !interior.isEmpty { items.append(.init(symbol: "seatbelt", label: L10n.t("Цвет салона", "Salon rangi", settings.language), value: interior)) }
        return items
    }

    private func performanceItems(_ p: CarPerformance) -> [SpecItem] {
        var items: [SpecItem] = []
        if let value = p.horsepowerHp { items.append(.init(symbol: "bolt", label: L10n.t("Мощность", "Quvvat", settings.language), value: "\(value) \(L10n.t("л.с.", "o.k.", settings.language))")) }
        if let value = p.torqueNm { items.append(.init(symbol: "arrow.triangle.2.circlepath", label: L10n.t("Крутящий момент", "Aylanish momenti", settings.language), value: "\(value) Н·м")) }
        if let value = p.acceleration0100 { items.append(.init(symbol: "timer", label: "0–100 км/ч", value: String(format: "%.1f с", value))) }
        if let value = p.topSpeedKmh { items.append(.init(symbol: "gauge.with.dots.needle.67percent", label: L10n.t("Макс. скорость", "Maks. tezlik", settings.language), value: "\(value) км/ч")) }
        return items
    }

    private func countryLabel(_ code: String?) -> String? {
        guard let code else { return nil }
        let ru = ["US":"США", "CA":"Канада", "KR":"Корея", "AE":"ОАЭ", "DE":"Германия", "GB":"Великобритания", "AU":"Австралия", "EU":"Европа"]
        let uz = ["US":"AQSH", "CA":"Kanada", "KR":"Koreya", "AE":"BAA", "DE":"Germaniya", "GB":"Buyuk Britaniya", "AU":"Avstraliya", "EU":"Yevropa"]
        return (settings.language == .ru ? ru : uz)[code.uppercased()] ?? code.uppercased()
    }

    private func loadDetail() async {
        do {
            detail = try await store.detail(for: car)
            loadError = nil
            selectedVariant = 0
            selectedPhoto = 0
        } catch {
            loadError = error.localizedDescription
        }
    }
}

private struct SpecItem: Hashable {
    let symbol: String
    let label: String
    let value: String
}

private struct VariantGlass: ViewModifier {
    let active: Bool
    @ViewBuilder func body(content: Content) -> some View {
        if active {
            if #available(iOS 26.0, *) { content.glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 22, style: .continuous)) }
            else { content.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous)).overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.white.opacity(0.2), lineWidth: 0.6)) }
        } else { content.background(ASUDesign.elevated, in: RoundedRectangle(cornerRadius: 22, style: .continuous)) }
    }
}

private struct FullScreenCarGallery: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let photos: [CarPhoto]
    let initialIndex: Int
    @State private var selection = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            TabView(selection: $selection) {
                ForEach(photos.indices, id: \.self) { index in
                    let photo = photos[index]
                    ASURemoteImage(url: photo.url, contentMode: .fit, background: .black)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack {
                HStack {
                    ASUGlassIconButton(symbol: "xmark", size: 46, accessibilityLabel: "Close") { dismiss() }
                        .foregroundStyle(.white)
                    Spacer()
                    ASUGlassSurface(radius: 18) {
                        Text(photos.isEmpty ? "0 / 0" : "\(selection + 1) / \(photos.count)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 13)
                            .frame(height: 36)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                Spacer()
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(.bottom, 16)
            }
        }
        .onAppear { selection = min(max(initialIndex, 0), max(photos.count - 1, 0)) }
    }
}

struct ContactSheet: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    let car: Car?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Capsule().fill(Color.secondary.opacity(0.30)).frame(width: 42, height: 5).frame(maxWidth: .infinity).padding(.top, 8)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.t("Связаться", "Bog‘lanish", settings.language)).font(.system(size: 29, weight: .bold, design: .rounded)).tracking(-0.8)
                    if let car { Text(car.displayName).font(.system(size: 13.5, weight: .medium, design: .rounded)).foregroundStyle(.secondary) }
                }
                Spacer()
                ASUGlassIconButton(symbol: "xmark", size: 44, accessibilityLabel: L10n.t("Закрыть", "Yopish", settings.language)) { dismiss() }
            }

            Button { openURL(whatsAppURL(car)) } label: {
                Label("WhatsApp", systemImage: "message.fill")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(uiColor: .systemBackground))
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(Color.primary, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
            }.buttonStyle(.plain)

            ASUGlassActionTile(action: { openURL(AppConfig.telegram) }) {
                Label("Telegram", systemImage: "paperplane.fill")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity).frame(height: 54)
            }
            ASUGlassActionTile(action: { openURL(URL(string: "tel:\(AppConfig.phone)")!) }) {
                Label(L10n.t("Позвонить", "Qo‘ng‘iroq", settings.language), systemImage: "phone.fill")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity).frame(height: 54)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .presentationDetents([.height(365)])
        .presentationCornerRadius(34)
        .presentationBackground(.regularMaterial)
    }

    private func whatsAppURL(_ car: Car?) -> URL {
        let text = car.map { "Здравствуйте. Интересует \($0.displayName)." } ?? "Здравствуйте. Хочу получить консультацию Auto Sale Umar."
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://wa.me/\(AppConfig.whatsappPhone)?text=\(encoded)")!
    }
}

private struct CarBookingSheet: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    let car: Car
    @State private var name = ""
    @State private var date = Date().addingTimeInterval(86_400)

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.t("Автомобиль", "Avtomobil", settings.language)) {
                    LabeledContent(L10n.t("Модель", "Model", settings.language), value: car.displayName)
                    LabeledContent(L10n.t("Цена", "Narx", settings.language), value: Format.price(car, language: settings.language))
                }
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
        .presentationCornerRadius(34)
    }

    private var bookingURL: URL {
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "ru_RU"); formatter.dateFormat = "dd.MM.yyyy HH:mm"
        let text = "Здравствуйте. Хочу забронировать визит по \(car.displayName). Имя: \(name). Время: \(formatter.string(from: date))."
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://wa.me/\(AppConfig.whatsappPhone)?text=\(encoded)")!
    }
}
