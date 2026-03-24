import Foundation
import XCTest
@testable import firstgrowth

final class TreasureTimelineBuilderTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    func testBuildsMixedTimelineSortedByCreatedAtDescending() {
        let builder = TreasureTimelineBuilder(calendar: calendar)
        let older = Date(timeIntervalSince1970: 1_710_000_000)
        let newer = older.addingTimeInterval(86_400)
        let weekEnd = newer.addingTimeInterval(3_600)

        let entries = [
            MemoryEntry(createdAt: older, ageInDays: 30, imageLocalPaths: [], note: "较早的一条。", isMilestone: false),
            MemoryEntry(createdAt: newer, ageInDays: 31, imageLocalPaths: [], note: "更新的一条。", isMilestone: true),
        ]
        let letters = [
            WeeklyLetter(
                weekStart: older,
                weekEnd: weekEnd,
                density: .normal,
                collapsedText: "时间寄来了一封这周的信。",
                expandedText: "这一周留下了两条记忆。",
                generatedAt: weekEnd
            )
        ]

        let items = builder.makeTimelineItems(entries: entries, weeklyLetters: letters)

        XCTAssertEqual(items.map(\.type), [.weeklyLetterNormal, .milestone, .memory])
        XCTAssertEqual(items.first?.monthKey, "2024-03")
    }

    func testBuildsMemoryItemForSingleImageEntry() throws {
        let builder = TreasureTimelineBuilder(calendar: calendar)
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let imagePath = try makeTemporaryImagePath()

        defer {
            try? FileManager.default.removeItem(atPath: imagePath)
        }

        let items = builder.makeTimelineItems(
            entries: [
                MemoryEntry(
                    createdAt: now,
                    ageInDays: 20,
                    imageLocalPaths: [imagePath],
                    note: nil,
                    isMilestone: false
                )
            ],
            weeklyLetters: []
        )

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.imageLocalPaths, [imagePath])
    }

    func testBuildsMemoryItemForMultiImageEntry() throws {
        let builder = TreasureTimelineBuilder(calendar: calendar)
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let firstImagePath = try makeTemporaryImagePath()
        let secondImagePath = try makeTemporaryImagePath()

        defer {
            try? FileManager.default.removeItem(atPath: firstImagePath)
            try? FileManager.default.removeItem(atPath: secondImagePath)
        }

        let items = builder.makeTimelineItems(
            entries: [
                MemoryEntry(
                    createdAt: now,
                    ageInDays: 20,
                    imageLocalPaths: [firstImagePath, secondImagePath],
                    note: nil,
                    isMilestone: false
                )
            ],
            weeklyLetters: []
        )

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.imageLocalPaths, [firstImagePath, secondImagePath])
    }

    func testDropsUnreadableImageWithoutTextAndKeepsTextFallback() {
        let builder = TreasureTimelineBuilder(calendar: calendar, fileManager: .default)
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let entries = [
            MemoryEntry(createdAt: now, ageInDays: 20, imageLocalPaths: ["/tmp/not-found-a.jpg"], note: nil, isMilestone: false),
            MemoryEntry(createdAt: now.addingTimeInterval(-10), ageInDays: 20, imageLocalPaths: ["/tmp/not-found-b.jpg"], note: "还有一句话。", isMilestone: false),
        ]

        let items = builder.makeTimelineItems(entries: entries, weeklyLetters: [])

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.note, "还有一句话。")
        XCTAssertEqual(items.first?.hasImageLoadError, true)
        XCTAssertTrue(items.first?.imageLocalPaths.isEmpty == true)
    }

    func testDropsUnreadablePathsFromMultiImageEntries() throws {
        let builder = TreasureTimelineBuilder(calendar: calendar, fileManager: .default)
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let readableImagePath = try makeTemporaryImagePath()

        defer {
            try? FileManager.default.removeItem(atPath: readableImagePath)
        }

        let items = builder.makeTimelineItems(
            entries: [
                MemoryEntry(
                    createdAt: now,
                    ageInDays: 20,
                    imageLocalPaths: [readableImagePath, "/tmp/missing-image.jpg"],
                    note: "还有一张能看到。",
                    isMilestone: false
                )
            ],
            weeklyLetters: []
        )

        XCTAssertEqual(items.first?.imageLocalPaths, [readableImagePath])
        XCTAssertEqual(items.first?.hasImageLoadError, true)
    }

    func testWeeklyLetterUsesEndOfWeekDayForDisplayOrdering() {
        let builder = TreasureTimelineBuilder(calendar: calendar)
        let sameDayMorning = Date(timeIntervalSince1970: 1_710_000_000)
        let weekEndAtStartOfDay = calendar.startOfDay(for: sameDayMorning)

        let items = builder.makeTimelineItems(
            entries: [
                MemoryEntry(
                    createdAt: sameDayMorning,
                    ageInDays: 20,
                    imageLocalPaths: [],
                    note: "上午记下的一条。",
                    isMilestone: false
                )
            ],
            weeklyLetters: [
                WeeklyLetter(
                    weekStart: weekEndAtStartOfDay.addingTimeInterval(-6 * 86_400),
                    weekEnd: weekEndAtStartOfDay,
                    density: .normal,
                    collapsedText: "时间寄来了一封这周的信。",
                    expandedText: "这一周留下了几条记忆。",
                    generatedAt: weekEndAtStartOfDay
                )
            ]
        )

        XCTAssertEqual(items.map(\.type), [.weeklyLetterNormal, .memory])
    }

    private func makeTemporaryImagePath() throws -> String {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("treasure-test-\(UUID().uuidString).jpg")
        try Data("test".utf8).write(to: fileURL)
        return fileURL.path
    }
}
