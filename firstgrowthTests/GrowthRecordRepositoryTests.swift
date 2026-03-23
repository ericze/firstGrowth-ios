import XCTest
@testable import firstgrowth

@MainActor
final class GrowthRecordRepositoryTests: XCTestCase {
    func testCreateFetchAndDeleteGrowthRecords() throws {
        let environment = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_710_000_000))
        let repository = environment.growthRepository

        let height = try repository.createRecord(metric: .height, value: 75.2, at: environment.now.value)
        _ = try repository.createRecord(metric: .weight, value: 9.6, at: environment.now.value.addingTimeInterval(3600))

        let heightRecords = try repository.fetchRecords(for: .height)
        let weightRecords = try repository.fetchRecords(for: .weight)

        XCTAssertEqual(heightRecords.count, 1)
        XCTAssertEqual(weightRecords.count, 1)
        XCTAssertEqual(heightRecords.first?.value ?? 0, 75.2, accuracy: 0.001)

        try repository.deleteRecord(id: height.id)
        XCTAssertTrue(try repository.fetchRecords(for: .height).isEmpty)
    }

    func testHomeQueriesIgnoreGrowthRecords() throws {
        let environment = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_710_000_000))

        _ = try environment.growthRepository.createRecord(metric: .height, value: 75.2, at: environment.now.value)
        let todayHomeRecords = try environment.recordRepository.fetchTodayRecords(referenceDate: environment.now.value)

        XCTAssertTrue(todayHomeRecords.isEmpty)
    }
}
