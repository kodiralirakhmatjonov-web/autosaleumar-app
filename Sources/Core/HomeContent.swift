import Foundation

struct ASUBrandItem: Identifiable, Hashable {
    let name: String
    let assetName: String
    var id: String { name }
}

struct ASUShowroomStory: Identifiable, Hashable {
    let assetName: String
    let titleRu: String
    let titleUz: String
    let textRu: String
    let textUz: String
    var id: String { assetName }

    func title(_ language: AppLanguage) -> String { language == .ru ? titleRu : titleUz }
    func text(_ language: AppLanguage) -> String { language == .ru ? textRu : textUz }
}

struct ASUDigitalStory: Identifiable, Hashable {
    let assetName: String
    let titleRu: String
    let titleUz: String
    let textRu: String
    let textUz: String
    var id: String { assetName }

    func title(_ language: AppLanguage) -> String { language == .ru ? titleRu : titleUz }
    func text(_ language: AppLanguage) -> String { language == .ru ? textRu : textUz }
}

struct ASUMarket: Identifiable, Hashable {
    let flag: String
    let ru: String
    let uz: String
    var id: String { ru }
    func title(_ language: AppLanguage) -> String { language == .ru ? ru : uz }
}

enum ASUHomeContent {
    static let brands: [ASUBrandItem] = [
        .init(name: "Mercedes-Benz", assetName: "BrandMercedes"),
        .init(name: "Range Rover", assetName: "BrandRangeRover"),
        .init(name: "Rolls-Royce", assetName: "BrandRollsRoyce"),
        .init(name: "Cadillac", assetName: "BrandCadillac"),
        .init(name: "Lexus", assetName: "BrandLexus"),
        .init(name: "Toyota", assetName: "BrandToyota"),
        .init(name: "Genesis", assetName: "BrandGenesis"),
        .init(name: "BMW", assetName: "BrandBMW"),
        .init(name: "Lamborghini", assetName: "BrandLamborghini"),
        .init(name: "Porsche", assetName: "BrandPorsche"),
    ]

    static let showroomStories: [ASUShowroomStory] = [
        .init(
            assetName: "Showroom01",
            titleRu: "Тишина снаружи. Характер внутри.",
            titleUz: "Tashqarida sokinlik. Ichkarida xarakter.",
            textRu: "Пространство, где автомобиль говорит сам за себя. Без лишнего шума, давления и спешки.",
            textUz: "Avtomobil o‘zi haqida gapiradigan makon. Ortiqcha shovqin, bosim va shoshilishsiz."
        ),
        .init(
            assetName: "Showroom02",
            titleRu: "Комфорт начинается до поездки.",
            titleUz: "Qulaylik safardan oldin boshlanadi.",
            textRu: "Спокойная клиентская зона, персональное внимание и время для обдуманного решения.",
            textUz: "Sokin mijozlar zonasi, shaxsiy e’tibor va o‘ylangan qaror uchun yetarli vaqt."
        ),
        .init(
            assetName: "Showroom03",
            titleRu: "Свет подчёркивает главное.",
            titleUz: "Yorug‘lik asosiy narsani ko‘rsatadi.",
            textRu: "Архитектура шоурума раскрывает линии автомобиля, материалы и детали без визуального шума.",
            textUz: "Shourum arxitekturasi avtomobil chiziqlari, materiallari va detallarini vizual shovqinsiz ochib beradi."
        ),
        .init(
            assetName: "Showroom04",
            titleRu: "Выбирайте не из доступного. Выбирайте своё.",
            titleUz: "Mavjudidan emas. O‘zingiznikini tanlang.",
            textRu: "Подберём модель, комплектацию и организуем путь автомобиля до передачи ключей.",
            textUz: "Model va komplektatsiyani tanlaymiz, avtomobil yo‘lini kalit topshirilgunga qadar tashkil qilamiz."
        ),
        .init(
            assetName: "Showroom05",
            titleRu: "Доверие строится на деталях.",
            titleUz: "Ishonch detallardan quriladi.",
            textRu: "Прозрачный статус автомобиля, серьёзное сопровождение и правильное отношение к клиенту.",
            textUz: "Avtomobilning aniq statusi, jiddiy kuzatuv va mijozga to‘g‘ri munosabat."
        ),
        .init(
            assetName: "Showroom06",
            titleRu: "Цифровая витрина. Живой шоурум.",
            titleUz: "Raqamli vitrina. Jonli shourum.",
            textRu: "Каталог, актуальные статусы и автомобили работают как единая система прямо в пространстве Auto Sale Umar.",
            textUz: "Katalog, dolzarb statuslar va avtomobillar Auto Sale Umar makonida yagona tizim sifatida ishlaydi."
        ),
    ]

    static let digitalStories: [ASUDigitalStory] = [
        .init(
            assetName: "DigitalDisplay",
            titleRu: "Главная витрина",
            titleUz: "Asosiy vitrina",
            textRu: "Премиальная подача Auto Sale Umar на большом экране.",
            textUz: "Auto Sale Umar’ning katta ekrandagi premium taqdimoti."
        ),
        .init(
            assetName: "DigitalTablet",
            titleRu: "Приложение и iPad",
            titleUz: "Ilova va iPad",
            textRu: "Каталог и мобильный интерфейс работают как единая система.",
            textUz: "Katalog va mobil interfeys yagona tizim sifatida ishlaydi."
        ),
        .init(
            assetName: "DigitalLaptop",
            titleRu: "Каталог на ноутбуке",
            titleUz: "Noutbukdagi katalog",
            textRu: "Фильтры, карточки и поиск автомобиля доступны в веб-версии.",
            textUz: "Filtrlar, kartalar va qidiruv veb-versiyada ishlaydi."
        ),
        .init(
            assetName: "DigitalStage",
            titleRu: "Единая презентация",
            titleUz: "Yagona taqdimot",
            textRu: "Сайт, приложение и визуальная подача работают в одном стиле.",
            textUz: "Sayt, ilova va vizual taqdimot bir uslubda ishlaydi."
        ),
    ]

    static let markets: [ASUMarket] = [
        .init(flag: "🇺🇸", ru: "США", uz: "AQSH"),
        .init(flag: "🇨🇦", ru: "Канада", uz: "Kanada"),
        .init(flag: "🇰🇷", ru: "Корея", uz: "Koreya"),
        .init(flag: "🇦🇪", ru: "ОАЭ", uz: "BAA"),
        .init(flag: "🇪🇺", ru: "Европа", uz: "Yevropa"),
        .init(flag: "🇬🇧", ru: "Великобритания", uz: "Buyuk Britaniya"),
        .init(flag: "🇦🇺", ru: "Австралия", uz: "Avstraliya"),
    ]
}
