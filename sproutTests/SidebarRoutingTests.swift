import Testing
@testable import sprout

@MainActor
struct SidebarRoutingTests {

    @Test("V1 sidebar contains exactly 1 item: language")
    func testItemCount() {
        #expect(SidebarIndexItem.items.count == 1)
    }

    @Test("all items have valid, non-nil routes")
    func testAllRoutesValid() {
        for item in SidebarIndexItem.items {
            #expect(item.route != nil, "Item '\(item.id)' has a nil route")
        }
    }

    @Test("expected item IDs are present")
    func testExpectedIDs() {
        let ids = Set(SidebarIndexItem.items.map(\.id))
        #expect(ids.contains("language"))
    }

    @Test("removed items are absent from V1")
    func testRemovedItems() {
        let ids = SidebarIndexItem.items.map(\.id)
        #expect(!ids.contains("profile"))
        #expect(!ids.contains("cloud"))
        #expect(!ids.contains("family"))
        #expect(!ids.contains("rhythm"))
    }

    @Test("sidebar items reflect the current app language")
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

    @Test("language routes to language")
    func testLanguageRoute() {
        let lang = SidebarIndexItem.items.first { $0.id == "language" }
        #expect(lang != nil)
        #expect(lang?.route == .language)
    }
}
