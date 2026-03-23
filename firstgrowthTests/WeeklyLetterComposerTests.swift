import Foundation
import XCTest
@testable import firstgrowth

final class WeeklyLetterComposerTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    func testComposeReturnsSilentLetterForSingleEntry() {
        let composer = WeeklyLetterComposer(calendar: calendar)
        let weekStart = Date(timeIntervalSince1970: 1_710_000_000)
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
        let entry = MemoryEntry(
            createdAt: weekStart,
            ageInDays: 40,
            imageLocalPath: nil,
            note: "今天笑了一下。",
            isMilestone: false
        )

        let letter = composer.compose(
            entries: [entry],
            weekStart: weekStart,
            weekEnd: weekEnd,
            generatedAt: weekEnd
        )

        XCTAssertEqual(letter?.density, .silent)
        XCTAssertEqual(letter?.collapsedText, "这一周，被轻轻收下了。")
        XCTAssertEqual(letter?.expandedText, "这一周只留下了一条记忆，日子照常往前。")
    }

    func testComposeReturnsDenseLetterWhenMilestoneExists() {
        let composer = WeeklyLetterComposer(calendar: calendar)
        let weekStart = Date(timeIntervalSince1970: 1_710_000_000)
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
        let entries = [
            MemoryEntry(createdAt: weekStart, ageInDays: 38, imageLocalPath: nil, note: "第一次翻身。", isMilestone: true),
            MemoryEntry(createdAt: weekStart.addingTimeInterval(2_000), ageInDays: 38, imageLocalPath: nil, note: "晚上睡得稳一些。", isMilestone: false),
        ]

        let letter = composer.compose(
            entries: entries,
            weekStart: weekStart,
            weekEnd: weekEnd,
            generatedAt: weekEnd
        )

        XCTAssertEqual(letter?.density, .dense)
        XCTAssertTrue(letter?.expandedText.contains("轻轻打上了星号") == true)
    }

    func testComposeRejectsBannedTermsWhenSnippetLeaksIntoLetter() {
        let composer = WeeklyLetterComposer(calendar: calendar)
        let weekStart = Date(timeIntervalSince1970: 1_710_000_000)
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
        let entries = (0..<5).map { index in
            MemoryEntry(
                createdAt: weekStart.addingTimeInterval(TimeInterval(index * 600)),
                ageInDays: 60,
                imageLocalPath: nil,
                note: index == 0 ? "今天很健康。" : "第\(index)条记忆。",
                isMilestone: false
            )
        }

        let letter = composer.compose(
            entries: entries,
            weekStart: weekStart,
            weekEnd: weekEnd,
            generatedAt: weekEnd
        )

        XCTAssertNil(letter)
    }
}
