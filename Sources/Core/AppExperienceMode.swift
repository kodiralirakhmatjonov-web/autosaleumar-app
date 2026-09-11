import Foundation

enum ASUExperienceMode: String, CaseIterable, Hashable {
    case client
    case staff

    private static let storageKey = "ASUExperienceModeV1"

    static func restored() -> ASUExperienceMode {
        guard let raw = UserDefaults.standard.string(forKey: storageKey),
              let value = ASUExperienceMode(rawValue: raw) else {
            return .client
        }
        return value
    }

    func persist() {
        UserDefaults.standard.set(rawValue, forKey: Self.storageKey)
    }
}
