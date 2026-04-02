import Foundation

enum AppLanguage: String, CaseIterable, Sendable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"

    init(locale: Locale = .autoupdatingCurrent) {
        let languageCode = locale.language.languageCode?.identifier

        switch languageCode {
        case "zh":
            self = .simplifiedChinese
        default:
            self = .english
        }
    }

    static let fallback: AppLanguage = .english

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    var lprojName: String {
        rawValue
    }
}
