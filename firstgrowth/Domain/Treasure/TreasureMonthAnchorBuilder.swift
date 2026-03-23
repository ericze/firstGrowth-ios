import Foundation

struct TreasureMonthAnchorBuilder {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func build(from items: [TreasureTimelineItem]) -> [TreasureMonthAnchor] {
        var seenMonthKeys = Set<String>()
        var anchors: [TreasureMonthAnchor] = []

        for item in items {
            guard !seenMonthKeys.contains(item.monthKey) else { continue }
            seenMonthKeys.insert(item.monthKey)
            anchors.append(
                TreasureMonthAnchor(
                    id: item.monthKey,
                    monthKey: item.monthKey,
                    displayText: displayText(for: item.createdAt),
                    firstTimelineItemID: item.id
                )
            )
        }

        return anchors
    }

    private func displayText(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        return "\(year) · \(month)月"
    }
}
