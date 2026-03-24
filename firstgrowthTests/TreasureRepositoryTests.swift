import Foundation
import XCTest
@testable import firstgrowth

@MainActor
final class TreasureRepositoryTests: XCTestCase {
    func testCreateMemoryEntryPersistsAgeInDays() throws {
        let environment = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_710_000_000))
        let birthDate = Calendar(identifier: .gregorian).date(byAdding: .day, value: -10, to: environment.now.value)!

        let entry = try environment.treasureRepository.createMemoryEntry(
            note: "  会抬头了  ",
            imageLocalPaths: [],
            isMilestone: true,
            createdAt: environment.now.value,
            birthDate: birthDate
        )

        XCTAssertEqual(entry.ageInDays, 10)
        XCTAssertEqual(entry.note, "会抬头了")
        XCTAssertTrue(entry.imageLocalPaths.isEmpty)
        XCTAssertEqual(try environment.treasureRepository.fetchMemoryEntries().count, 1)
    }

    func testCreateMemoryEntryTruncatesToMaximumImageCount() throws {
        let environment = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_710_000_000))
        let imagePaths = (0..<8).map { "/tmp/treasure-image-\($0).jpg" }

        let entry = try environment.treasureRepository.createMemoryEntry(
            note: nil,
            imageLocalPaths: imagePaths,
            isMilestone: false,
            createdAt: environment.now.value,
            birthDate: HomeHeaderConfig.placeholder.birthDate
        )

        let expectedPaths = Array(imagePaths.prefix(TreasureLimits.maxImagesPerEntry))
        XCTAssertEqual(entry.imageLocalPaths, expectedPaths)

        let fetchedEntries = try environment.treasureRepository.fetchMemoryEntries()
        XCTAssertEqual(fetchedEntries.first?.imageLocalPaths, expectedPaths)
    }

    func testSyncWeeklyLetterUpsertsAndRemovesAffectedWeek() throws {
        let environment = try makeTestEnvironment(now: Date(timeIntervalSince1970: 1_710_000_000))
        let calendar = Calendar(identifier: .gregorian)
        let composer = WeeklyLetterComposer(calendar: calendar)
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: environment.now.value))!

        let entry = try environment.treasureRepository.createMemoryEntry(
            note: "这一周留下了第一条。",
            imageLocalPaths: [],
            isMilestone: false,
            createdAt: environment.now.value,
            birthDate: HomeHeaderConfig.placeholder.birthDate
        )

        try environment.treasureRepository.syncWeeklyLetter(
            for: weekStart,
            composer: composer,
            generatedAt: environment.now.value
        )

        var letters = try environment.treasureRepository.fetchWeeklyLetters()
        XCTAssertEqual(letters.count, 1)
        XCTAssertEqual(letters.first?.density, .silent)

        try environment.treasureRepository.deleteMemoryEntry(id: entry.id, removeImage: false)
        try environment.treasureRepository.syncWeeklyLetter(
            for: weekStart,
            composer: composer,
            generatedAt: environment.now.value
        )

        letters = try environment.treasureRepository.fetchWeeklyLetters()
        XCTAssertTrue(letters.isEmpty)
    }
}
