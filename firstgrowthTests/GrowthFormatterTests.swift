import XCTest
@testable import firstgrowth

final class GrowthFormatterTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    func testMetaInfoAndTooltipFormatting() {
        let formatter = GrowthFormatter(calendar: calendar)
        let birthDate = Date(timeIntervalSince1970: 1_700_000_000)
        let recordDate = calendar.date(byAdding: .day, value: 390, to: birthDate)!
        let record = RecordItem(timestamp: recordDate, type: RecordType.height.rawValue, value: 75.2)

        let points = formatter.makePoints(from: [record], metric: .height, birthDate: birthDate)
        let metaInfo = formatter.makeMetaInfo(from: points, metric: .height, now: calendar.date(byAdding: .day, value: 397, to: birthDate)!)
        let tooltip = formatter.makeTooltip(for: points[0], metric: .height)

        XCTAssertEqual(metaInfo.summaryText, "最新记录：75.2cm · 7天前")
        XCTAssertEqual(tooltip.ageText, "13个月")
        XCTAssertEqual(tooltip.valueText, "75.2cm")
    }

    func testAIContentStaysObjective() {
        let formatter = GrowthFormatter(calendar: calendar)
        let birthDate = Date(timeIntervalSince1970: 1_700_000_000)
        let first = RecordItem(
            timestamp: calendar.date(byAdding: .day, value: 360, to: birthDate)!,
            type: RecordType.weight.rawValue,
            value: 9.4
        )
        let second = RecordItem(
            timestamp: calendar.date(byAdding: .day, value: 375, to: birthDate)!,
            type: RecordType.weight.rawValue,
            value: 9.6
        )

        let points = formatter.makePoints(from: [first, second], metric: .weight, birthDate: birthDate)
        let content = formatter.makeAIContent(from: points, metric: .weight)

        XCTAssertEqual(content.collapsedText, "✨ 记录了距上次15天的变化")
        XCTAssertTrue(content.expandedText.contains("体重增加了 0.2kg"))
        XCTAssertFalse(content.expandedText.contains("健康"))
        XCTAssertFalse(content.expandedText.contains("同龄"))
    }
}
