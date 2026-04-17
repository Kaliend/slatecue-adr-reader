import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Codable, Sendable {
    case english = "en"
    case czech = "cs"

    static let userDefaultsKey = "appLanguage"

    var id: String { rawValue }

    var localeIdentifier: String { rawValue }

    var nativeDisplayName: String {
        switch self {
        case .english:
            return "English"
        case .czech:
            return "Čeština"
        }
    }

    static var stored: AppLanguage {
        guard let rawValue = UserDefaults.standard.string(forKey: userDefaultsKey),
              let language = AppLanguage(rawValue: rawValue) else {
            return .english
        }

        return language
    }
}
