import Foundation
import Testing
@testable import sprout

@MainActor
struct AppLanguageManagerTests {

    @Test("language changes persist and update the localization override")
    func testLanguageChangesPersistAndUpdateOverride() {
        let previousOverride = LocalizationService.overrideLanguage
        let suiteName = "sprout-language-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        defer {
            LocalizationService.overrideLanguage = previousOverride
            defaults.removePersistentDomain(forName: suiteName)
        }

        let manager = AppLanguageManager(
            defaults: defaults,
            storageKey: "app_language_test",
            initialLanguage: .english
        )

        #expect(manager.language == .english)
        #expect(manager.languageVersion == 0)

        manager.language = .simplifiedChinese

        #expect(manager.languageVersion == 1)
        #expect(defaults.string(forKey: "app_language_test") == AppLanguage.simplifiedChinese.rawValue)
        #expect(LocalizationService.current.language == .simplifiedChinese)
    }

    @Test("sidebar items are recalculated when the language override changes")
    func testSidebarItemsRecalculateForLanguageChanges() {
        let previousOverride = LocalizationService.overrideLanguage

        defer {
            LocalizationService.overrideLanguage = previousOverride
        }

        LocalizationService.override(language: .english)
        let englishTitles = SidebarIndexItem.items.map(\.title)
        let englishDetails = SidebarIndexItem.items.map(\.detail)

        LocalizationService.override(language: .simplifiedChinese)
        let chineseTitles = SidebarIndexItem.items.map(\.title)
        let chineseDetails = SidebarIndexItem.items.map(\.detail)

        #expect(englishTitles != chineseTitles)
        #expect(englishDetails != chineseDetails)
    }

    @Test("language region selection only commits changed language")
    func testLanguageRegionSelectionOnlyCommitsChangedLanguage() {
        var currentLanguage = AppLanguage.english
        var committedLanguages: [AppLanguage] = []
        let selection = LanguageRegionSelection(
            currentLanguage: { currentLanguage },
            commit: { language in
                currentLanguage = language
                committedLanguages.append(language)
            }
        )

        selection.select(.english)
        #expect(committedLanguages.isEmpty)

        selection.select(.simplifiedChinese)
        #expect(currentLanguage == .simplifiedChinese)
        #expect(committedLanguages == [.simplifiedChinese])

        selection.select(.simplifiedChinese)
        #expect(committedLanguages == [.simplifiedChinese])
    }
}
