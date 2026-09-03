import Foundation

enum L10n {
    static func t(_ ru: String, _ uz: String, _ language: AppLanguage) -> String {
        language == .ru ? ru : uz
    }
}
