import Foundation
import SwiftData
@testable import firstgrowth

@MainActor
struct TestEnvironment {
    let store: HomeStore
    let recordRepository: RecordRepository
    let growthRepository: GrowthRecordRepository
    let treasureRepository: TreasureRepository
    let now: MutableNow
    let defaults: UserDefaults
}

@MainActor
final class MutableNow {
    var value: Date

    init(_ value: Date) {
        self.value = value
    }
}

@MainActor
func makeTestEnvironment(now initialDate: Date) throws -> TestEnvironment {
    let schema = Schema([
        RecordItem.self,
        MemoryEntry.self,
        WeeklyLetter.self,
    ])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [configuration])
    let modelContext = ModelContext(container)
    let recordRepository = RecordRepository(modelContext: modelContext)
    let growthRepository = GrowthRecordRepository(modelContext: modelContext)
    let treasureRepository = TreasureRepository(modelContext: modelContext)

    let suiteName = "firstgrowthTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)

    let now = MutableNow(initialDate)
    let calendar = Calendar(identifier: .gregorian)
    let store = HomeStore(
        headerConfig: .placeholder,
        recordRepository: recordRepository,
        formatter: TimelineContentFormatter(),
        sleepSessionRepository: SleepSessionRepository(defaults: defaults, storageKey: "active_sleep_session_test"),
        calendar: calendar,
        historyPageSize: 20,
        dateProvider: { now.value }
    )

    return TestEnvironment(
        store: store,
        recordRepository: recordRepository,
        growthRepository: growthRepository,
        treasureRepository: treasureRepository,
        now: now,
        defaults: defaults
    )
}

@MainActor
func makeGrowthStore(
    environment: TestEnvironment,
    preferenceStore: GrowthMetricPreferenceStore? = nil,
    productConfig: GrowthProductConfig = .appDefault,
    chartInteractionController: GrowthChartInteractionController = GrowthChartInteractionController()
) -> GrowthStore {
    let calendar = Calendar(identifier: .gregorian)

    return GrowthStore(
        headerConfig: .placeholder,
        repository: environment.growthRepository,
        formatter: GrowthFormatter(calendar: calendar),
        referenceRangeStore: GrowthReferenceRangeStore(),
        metricPreferenceStore: preferenceStore ?? GrowthMetricPreferenceStore(
            defaults: environment.defaults,
            storageKey: "growth.metric.preference.test"
        ),
        chartInteractionController: chartInteractionController,
        productConfig: productConfig,
        calendar: calendar,
        dateProvider: { environment.now.value }
    )
}

@MainActor
func makeTreasureStore(
    environment: TestEnvironment,
    monthHintStore: TreasureMonthHintStore? = nil,
    imageRemover: @escaping @MainActor ([String]) -> Void = { _ in }
) -> TreasureStore {
    let calendar = Calendar(identifier: .gregorian)

    return TreasureStore(
        headerConfig: .placeholder,
        repository: environment.treasureRepository,
        timelineBuilder: TreasureTimelineBuilder(calendar: calendar),
        monthAnchorBuilder: TreasureMonthAnchorBuilder(calendar: calendar),
        weeklyLetterComposer: WeeklyLetterComposer(calendar: calendar),
        monthHintStore: monthHintStore ?? TreasureMonthHintStore(
            defaults: environment.defaults,
            storageKey: "treasure.month.hint.test"
        ),
        calendar: calendar,
        dateProvider: { environment.now.value },
        imageRemover: imageRemover
    )
}
