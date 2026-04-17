import Foundation

@MainActor
final class LocalizationController: ObservableObject {
    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: AppLanguage.userDefaultsKey)
        }
    }

    init(language: AppLanguage = .stored) {
        self.language = language
    }

    func text(_ key: String) -> String {
        AppStrings.text(key, language: language)
    }

    func format(_ key: String, _ arguments: CVarArg...) -> String {
        AppStrings.format(key, language: language, arguments: arguments)
    }
}
