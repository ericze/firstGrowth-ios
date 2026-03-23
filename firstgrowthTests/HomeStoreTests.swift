import XCTest
@testable import firstgrowth

@MainActor
final class HomeStoreTests: XCTestCase {
    func testMilkSaveAndUndo() throws {
        let environment = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_710_000_000))
        let store = environment.store

        store.handle(.tapMilkEntry)
        store.handle(.saveMilkPreset(120))

        XCTAssertEqual(try environment.recordRepository.fetchAllRecords().count, 1)
        XCTAssertEqual(store.viewState.todayDisplayItems.first?.title, "120ml")
        XCTAssertEqual(store.viewState.undoToast?.message, "已记录 120ml")

        store.handle(.undoLastRecord)

        XCTAssertTrue(try environment.recordRepository.fetchAllRecords().isEmpty)
        XCTAssertTrue(store.timelineItems.isEmpty)
        XCTAssertNil(store.viewState.undoToast)
    }

    func testSleepSessionRestoresAndFinishes() throws {
        let initialDate = Date(timeIntervalSince1970: 1_710_000_000)
        let environment = try makeTestEnvironment(now: initialDate)

        environment.store.handle(.tapSleepEntry)
        XCTAssertNotNil(environment.store.viewState.ongoingSleep)

        let restoredStore = HomeStore(
            headerConfig: .placeholder,
            recordRepository: environment.recordRepository,
            formatter: TimelineContentFormatter(),
            sleepSessionRepository: SleepSessionRepository(defaults: environment.defaults, storageKey: "active_sleep_session_test"),
            calendar: Calendar(identifier: .gregorian),
            historyPageSize: 20,
            dateProvider: { environment.now.value }
        )

        restoredStore.onAppear()
        XCTAssertNotNil(restoredStore.viewState.ongoingSleep)

        environment.now.value = initialDate.addingTimeInterval(90 * 60)
        restoredStore.handle(.finishSleep)

        XCTAssertNil(restoredStore.viewState.ongoingSleep)
        XCTAssertEqual(try environment.recordRepository.fetchAllRecords().count, 1)
        XCTAssertEqual(restoredStore.viewState.todayDisplayItems.first?.title, "睡了 1小时30分")

        restoredStore.handle(.undoLastRecord)
        XCTAssertTrue(try environment.recordRepository.fetchAllRecords().isEmpty)
        XCTAssertNil(restoredStore.viewState.ongoingSleep)
    }

    func testFoodDraftDismissConfirmation() throws {
        let environment = try makeTestEnvironment(now: .now)
        let store = environment.store

        store.handle(.tapFoodEntry)
        XCTAssertFalse(store.isFoodSaveEnabled)

        store.updateFoodNote("今天一直在扔勺子")
        XCTAssertTrue(store.isFoodSaveEnabled)

        store.requestFoodDismiss()
        XCTAssertTrue(store.isShowingFoodDiscardConfirmation)

        store.discardFoodDraft()
        XCTAssertFalse(store.foodDraft.hasContent)
        XCTAssertNil(store.routeState.activeSheet)
    }

    func testHistoryPaginationLoadsOlderRecords() throws {
        let referenceDate = Date(timeIntervalSince1970: 1_710_000_000)
        let environment = try makeTestEnvironment(now: referenceDate)
        let repository = environment.recordRepository

        try repository.createMilkRecord(amount: 120, at: referenceDate)
        for offset in 1...25 {
            let pastDate = Calendar(identifier: .gregorian).date(byAdding: .day, value: -offset, to: referenceDate)!
            try repository.createMilkRecord(amount: 90 + offset, at: pastDate)
        }

        environment.store.onAppear()

        XCTAssertEqual(environment.store.viewState.todayDisplayItems.count, 1)
        XCTAssertTrue(environment.store.viewState.historyDisplayItems.isEmpty)

        if let lastToday = environment.store.viewState.todayDisplayItems.last {
            environment.store.handle(.loadMoreIfNeeded(lastToday.recordID))
        }

        XCTAssertEqual(environment.store.viewState.historyDisplayItems.count, 20)
        XCTAssertTrue(environment.store.viewState.hasMoreHistory)

        if let lastHistory = environment.store.viewState.historyDisplayItems.last {
            environment.store.handle(.loadMoreIfNeeded(lastHistory.recordID))
        }

        XCTAssertEqual(environment.store.viewState.historyDisplayItems.count, 25)
        XCTAssertFalse(environment.store.viewState.hasMoreHistory)
    }
}
