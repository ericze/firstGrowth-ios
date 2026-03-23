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
            MemoryEntry(createdAt: older, ageInDays: 30, imageLocalPath: nil, note: "较早的一条。", isMilestone: false),
            MemoryEntry(createdAt: newer, ageInDays: 31, imageLocalPath: nil, note: "更新的一条。", isMilestone: true),
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

    func testFilterReturnsOnlyMatchingTreasureItems() {
        let builder = TreasureTimelineBuilder(calendar: calendar)
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let items = builder.makeTimelineItems(
            entries: [
                MemoryEntry(createdAt: now, ageInDays: 20, imageLocalPath: nil, note: "日常。", isMilestone: false),
                MemoryEntry(createdAt: now.addingTimeInterval(-100), ageInDays: 19, imageLocalPath: nil, note: "会翻身了。", isMilestone: true),
            ],
            weeklyLetters: [
                WeeklyLetter(
                    weekStart: now.addingTimeInterval(-86_400),
                    weekEnd: now,
                    density: .silent,
                    collapsedText: "这一周，被轻轻收下了。",
                    expandedText: "这一周只留下了一条记忆，日子照常往前。",
                    generatedAt: now
                )
            ]
        )

        XCTAssertEqual(builder.filter(items, by: .allMemories).count, 3)
        XCTAssertEqual(builder.filter(items, by: .starredMoments).map(\.type), [.milestone])
        XCTAssertEqual(builder.filter(items, by: .timeLetters).map(\.type), [.weeklyLetterSilent])
    }

    func testDropsUnreadableImageWithoutTextAndKeepsTextFallback() {
        let builder = TreasureTimelineBuilder(calendar: calendar, fileManager: .default)
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let entries = [
            MemoryEntry(createdAt: now, ageInDays: 20, imageLocalPath: "/tmp/not-found-a.jpg", note: nil, isMilestone: false),
            MemoryEntry(createdAt: now.addingTimeInterval(-10), ageInDays: 20, imageLocalPath: "/tmp/not-found-b.jpg", note: "还有一句话。", isMilestone: false),
        ]

        let items = builder.makeTimelineItems(entries: entries, weeklyLetters: [])

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.note, "还有一句话。")
        XCTAssertEqual(items.first?.hasImageLoadError, true)
        XCTAssertNil(items.first?.imageLocalPath)
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
                    imageLocalPath: nil,
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
}
