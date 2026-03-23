import Foundation
import XCTest
@testable import firstgrowth

@MainActor
final class TreasureStoreTests: XCTestCase {
    func testShowsMonthHintOnlyOnFirstEligibleLoad() throws {
        let environment = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_710_000_000))
        let calendar = Calendar(identifier: .gregorian)

        _ = try environment.treasureRepository.createMemoryEntry(
            note: "一月的一条。",
            imageLocalPath: nil,
            isMilestone: false,
            createdAt: Date(timeIntervalSince1970: 1_704_067_200),
            birthDate: HomeHeaderConfig.placeholder.birthDate
        )
        _ = try environment.treasureRepository.createMemoryEntry(
            note: "三月的一条。",
            imageLocalPath: nil,
            isMilestone: false,
            createdAt: environment.now.value,
            birthDate: HomeHeaderConfig.placeholder.birthDate
        )

        let hintStore = TreasureMonthHintStore(defaults: environment.defaults, storageKey: "treasure.hint.once")
        let firstStore = makeTreasureStore(environment: environment, monthHintStore: hintStore)
        firstStore.onAppear()

        XCTAssertEqual(firstStore.viewState.monthScrubberState, .onboardingNudge)

        let secondStore = makeTreasureStore(environment: environment, monthHintStore: hintStore)
        secondStore.onAppear()

        XCTAssertNotEqual(secondStore.viewState.monthScrubberState, .onboardingNudge)
        XCTAssertTrue(environment.defaults.bool(forKey: "treasure.hint.once"))
        _ = calendar
    }

    func testSwitchingFilterClosesWeeklyLetterAndRequestsScrollToTop() throws {
        let environment = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_710_000_000))
        let store = makeTreasureStore(environment: environment)
        let weekStart = Calendar(identifier: .gregorian).date(
            from: Calendar(identifier: .gregorian).dateComponents([.yearForWeekOfYear, .weekOfYear], from: environment.now.value)
        )!

        _ = try environment.treasureRepository.createMemoryEntry(
            note: "会站一下了。",
            imageLocalPath: nil,
            isMilestone: true,
            createdAt: environment.now.value,
            birthDate: HomeHeaderConfig.placeholder.birthDate
        )
        try environment.treasureRepository.syncWeeklyLetter(
            for: weekStart,
            composer: WeeklyLetterComposer(calendar: Calendar(identifier: .gregorian)),
            generatedAt: environment.now.value
        )

        store.onAppear()
        guard let letter = store.viewState.timelineItems.first(where: \.canOpenWeeklyLetter) else {
            return XCTFail("Expected weekly letter in timeline")
        }

        store.handle(.tapWeeklyLetter(letter.id))
        XCTAssertNotNil(store.viewState.selectedWeeklyLetter)

        store.handle(.selectFilter(.starredMoments))

        XCTAssertNil(store.viewState.selectedWeeklyLetter)
        XCTAssertEqual(store.viewState.weeklyLetterViewState, .collapsed)
        XCTAssertEqual(store.viewState.currentFilter, .starredMoments)
        XCTAssertEqual(store.viewState.scrollTargetID, store.viewState.timelineItems.first?.id)
    }

    func testMilestoneOnlyDraftRequestsDiscardConfirmation() throws {
        let environment = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_710_000_000))
        let store = makeTreasureStore(environment: environment)

        store.onAppear()
        store.handle(.tapAddToday)
        store.handle(.toggleMilestone)
        store.handle(.dismissCompose)

        XCTAssertEqual(store.viewState.composeState, .confirmingDiscard)
        XCTAssertTrue(store.shouldShowDiscardConfirmation)
    }

    func testSaveAndUndoRefreshesTimelineAndLetters() throws {
        let environment = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_710_000_000))
        let store = makeTreasureStore(environment: environment)

        store.onAppear()
        store.handle(.tapAddToday)
        store.handle(.updateNote("睡前多看了一会儿窗外。"))
        store.handle(.saveCompose)

        XCTAssertEqual(try environment.treasureRepository.fetchMemoryEntries().count, 1)
        XCTAssertEqual(try environment.treasureRepository.fetchWeeklyLetters().count, 1)
        XCTAssertEqual(store.viewState.undoToast?.message, "已留住今天")
        XCTAssertFalse(store.viewState.timelineItems.isEmpty)

        store.handle(.undoLastEntry)

        XCTAssertTrue(try environment.treasureRepository.fetchMemoryEntries().isEmpty)
        XCTAssertTrue(try environment.treasureRepository.fetchWeeklyLetters().isEmpty)
        XCTAssertEqual(store.viewState.dataState, .empty)
        XCTAssertNil(store.viewState.undoToast)
    }

    func testUndoClosesWeeklyLetterWhenAffectedCardDisappears() throws {
        let environment = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_710_000_000))
        let store = makeTreasureStore(environment: environment)

        store.onAppear()
        store.handle(.tapAddToday)
        store.handle(.updateNote("第一次把手搭在床边。"))
        store.handle(.toggleMilestone)
        store.handle(.saveCompose)

        guard let letter = store.viewState.timelineItems.first(where: \.canOpenWeeklyLetter) else {
            return XCTFail("Expected openable weekly letter in timeline")
        }

        store.handle(.tapWeeklyLetter(letter.id))
        XCTAssertEqual(store.viewState.selectedWeeklyLetter?.id, letter.id)

        store.handle(.undoLastEntry)

        XCTAssertNil(store.viewState.selectedWeeklyLetter)
        XCTAssertEqual(store.viewState.weeklyLetterViewState, .collapsed)
        XCTAssertTrue(try environment.treasureRepository.fetchWeeklyLetters().isEmpty)
    }
}
