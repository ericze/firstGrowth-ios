import Testing
@testable import sprout

struct OnboardingDraftTests {

    @Test("draft isValid 为 false 当名字为空")
    func testInvalidWhenNameEmpty() {
        let draft = OnboardingDraft(name: "", birthDate: .now)
        #expect(!draft.isValid)
    }

    @Test("draft isValid 为 false 当名字只有空格")
    func testInvalidWhenNameWhitespace() {
        let draft = OnboardingDraft(name: "   ", birthDate: .now)
        #expect(!draft.isValid)
    }

    @Test("draft isValid 为 true 当名字非空")
    func testValidWhenNamePresent() {
        let draft = OnboardingDraft(name: "小花生", birthDate: .now)
        #expect(draft.isValid)
    }

    @Test("trimmedName 去除首尾空格")
    func testTrimmedName() {
        let draft = OnboardingDraft(name: "  小花生  ", birthDate: .now)
        #expect(draft.trimmedName == "小花生")
    }
}
