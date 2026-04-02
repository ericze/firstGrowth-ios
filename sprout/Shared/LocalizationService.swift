import Foundation

struct LocalizationKey: Hashable, Sendable {
    let value: String
    let table: String?
    let fallback: String?

    init(_ value: String, table: String? = nil, fallback: String? = nil) {
        self.value = value
        self.table = table
        self.fallback = fallback
    }
}

struct LocalizationService {
    let bundle: Bundle
    let locale: Locale
    let language: AppLanguage
    let defaultLanguage: AppLanguage
    let defaultTable: String?

    static var current: LocalizationService {
        LocalizationService()
    }

    init(
        bundle: Bundle = .main,
        locale: Locale = .autoupdatingCurrent,
        language: AppLanguage? = nil,
        defaultLanguage: AppLanguage = .fallback,
        defaultTable: String? = nil
    ) {
        self.bundle = bundle
        self.locale = locale
        self.language = language ?? AppLanguage(locale: locale)
        self.defaultLanguage = defaultLanguage
        self.defaultTable = defaultTable
    }

    func string(_ key: LocalizationKey) -> String {
        string(forKey: key.value, fallback: key.fallback, table: key.table)
    }

    func string(forKey key: String, fallback: String? = nil, table: String? = nil) -> String {
        let preferredTable = table ?? defaultTable

        if let localized = localizedString(forKey: key, table: preferredTable, language: language) {
            return localized
        }

        if language != defaultLanguage,
           let fallbackLocalized = localizedString(forKey: key, table: preferredTable, language: defaultLanguage) {
            return fallbackLocalized
        }

        return fallback ?? key
    }

    private func localizedString(forKey key: String, table: String?, language: AppLanguage) -> String? {
        guard let localizedBundle = localizedBundle(for: language) else {
            let value = bundle.localizedString(forKey: key, value: nil, table: table)
            return value == key ? nil : value
        }

        let value = localizedBundle.localizedString(forKey: key, value: nil, table: table)
        return value == key ? nil : value
    }

    private func localizedBundle(for language: AppLanguage) -> Bundle? {
        guard let path = bundle.path(forResource: language.lprojName, ofType: "lproj") else {
            return nil
        }

        return Bundle(path: path)
    }
}
