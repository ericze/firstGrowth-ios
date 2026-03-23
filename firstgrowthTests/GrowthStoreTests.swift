import XCTest
@testable import firstgrowth

@MainActor
final class GrowthStoreTests: XCTestCase {
    func testRestoresPreferredMetric() throws {
        let environment = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_710_000_000))
        let preferenceStore = GrowthMetricPreferenceStore(defaults: environment.defaults, storageKey: "growth.metric.preference.restore")
        preferenceStore.save(.weight)

        let store = GrowthStore(
            headerConfig: .placeholder,
            repository: environment.growthRepository,
            formatter: GrowthFormatter(calendar: Calendar(identifier: .gregorian)),
            referenceRangeStore: GrowthReferenceRangeStore(),
            metricPreferenceStore: preferenceStore,
            chartInteractionController: GrowthChartInteractionController(),
            productConfig: .appDefault,
            calendar: Calendar(identifier: .gregorian),
            dateProvider: { environment.now.value }
        )

        store.onAppear()
        XCTAssertEqual(store.viewState.currentMetric, .weight)
    }

    func testSwitchingMetricClearsPrecisionState() throws {
        let environment = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_710_000_000))
        let store = makeGrowthStore(environment: environment)

        _ = try environment.growthRepository.createRecord(metric: .height, value: 74.8, at: environment.now.value.addingTimeInterval(-86_400 * 7))
        _ = try environment.growthRepository.createRecord(metric: .height, value: 75.2, at: environment.now.value)

        store.onAppear()
        store.handle(.beginScrubbing(locationX: 120, plotWidth: 240))

        XCTAssertNotNil(store.viewState.selection)
        XCTAssertEqual(store.viewState.chartInteractionState, .precisionVisible)

        store.handle(.selectMetric(.weight))

        XCTAssertNil(store.viewState.selection)
        XCTAssertEqual(store.viewState.chartInteractionState, .idle)
        XCTAssertEqual(store.viewState.currentMetric, .weight)
    }

    func testUsesConfiguredDefaultValueWhenNoHistoryExists() throws {
        let environment = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_710_000_000))
        let config = GrowthProductConfig(
            defaultHeightValue: 52.3,
            defaultWeightValue: 3.9,
            heightRange: 40.0...110.0,
            weightRange: 2.0...25.0,
            chartMinimumVisibleAgeInDays: 120,
            chartTrailingAgePaddingInDays: 30
        )

        let store = GrowthStore(
            headerConfig: .placeholder,
            repository: environment.growthRepository,
            formatter: GrowthFormatter(calendar: Calendar(identifier: .gregorian)),
            referenceRangeStore: GrowthReferenceRangeStore(),
            metricPreferenceStore: GrowthMetricPreferenceStore(defaults: environment.defaults, storageKey: "growth.metric.preference.default"),
            chartInteractionController: GrowthChartInteractionController(),
            productConfig: config,
            calendar: Calendar(identifier: .gregorian),
            dateProvider: { environment.now.value }
        )

        store.onAppear()
        store.handle(.tapEntry)

        XCTAssertEqual(store.viewState.entryDraft.value, 52.3, accuracy: 0.001)
        XCTAssertEqual(store.viewState.entryDraft.manualInput, "52.3")
    }

    func testSheetModeSwitchPreservesCurrentValue() throws {
        let environment = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_710_000_000))
        let store = makeGrowthStore(environment: environment)

        store.onAppear()
        store.handle(.tapEntry)
        store.handle(.updateRulerValue(68.4))
        store.handle(.switchToManualInput)

        XCTAssertEqual(store.viewState.entryDraft.manualInput, "68.4")

        store.handle(.updateManualInput("69.3"))
        store.handle(.switchToRulerInput)

        XCTAssertEqual(store.viewState.entryDraft.value, 69.3, accuracy: 0.001)
    }

    func testSaveAndUndoRefreshesGrowthState() throws {
        let environment = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_710_000_000))
        let store = makeGrowthStore(environment: environment)

        store.onAppear()
        store.handle(.tapEntry)
        store.handle(.updateRulerValue(75.2))
        store.handle(.saveRecord)

        XCTAssertEqual(try environment.growthRepository.fetchRecords(for: .height).count, 1)
        XCTAssertEqual(store.viewState.dataState, .hasData)
        XCTAssertEqual(store.viewState.undoToast?.message, "已记录75.2cm")

        store.handle(.undoLastRecord)

        XCTAssertTrue(try environment.growthRepository.fetchRecords(for: .height).isEmpty)
        XCTAssertEqual(store.viewState.dataState, .empty)
        XCTAssertNil(store.viewState.undoToast)
    }
}
