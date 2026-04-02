import Foundation

enum L10n {
    static func text(
        _ key: String,
        service: LocalizationService = .current,
        en: String,
        zh: String,
        table: String? = nil
    ) -> String {
        service.string(
            forKey: key,
            fallback: fallback(for: service.language, en: en, zh: zh),
            table: table
        )
    }

    static func format(
        _ key: String,
        service: LocalizationService = .current,
        locale: Locale? = nil,
        en: String,
        zh: String,
        arguments: [CVarArg],
        table: String? = nil
    ) -> String {
        let format = text(key, service: service, en: en, zh: zh, table: table)
        return String(
            format: format,
            locale: locale ?? service.locale,
            arguments: arguments
        )
    }

    private static func fallback(for language: AppLanguage, en: String, zh: String) -> String {
        switch language {
        case .english:
            en
        case .simplifiedChinese:
            zh
        }
    }
}
