import Foundation

struct TreasureTimelineBuilder {
    private let calendar: Calendar
    private let fileManager: FileManager

    init(calendar: Calendar = .current, fileManager: FileManager = .default) {
        self.calendar = calendar
        self.fileManager = fileManager
    }

    func makeTimelineItems(
        entries: [MemoryEntry],
        weeklyLetters: [WeeklyLetter]
    ) -> [TreasureTimelineItem] {
        let memoryItems = entries.compactMap(makeMemoryItem)
        let letterItems = weeklyLetters.map(makeWeeklyLetterItem)
        return (memoryItems + letterItems).sorted { lhs, rhs in
            if lhs.createdAt == rhs.createdAt {
                return lhs.id.uuidString > rhs.id.uuidString
            }
            return lhs.createdAt > rhs.createdAt
        }
    }

    func filter(
        _ items: [TreasureTimelineItem],
        by filter: TreasureFilter
    ) -> [TreasureTimelineItem] {
        switch filter {
        case .allMemories:
            items
        case .starredMoments:
            items.filter { $0.type == .milestone }
        case .timeLetters:
            items.filter(\.isWeeklyLetter)
        }
    }

    private func makeMemoryItem(entry: MemoryEntry) -> TreasureTimelineItem? {
        let note = entry.note?.trimmed.nilIfEmpty
        let path = entry.imageLocalPath?.trimmed.nilIfEmpty
        let hasReadableImage = path.flatMap { fileManager.fileExists(atPath: $0) ? $0 : nil }
        let hasImageLoadError = path != nil && hasReadableImage == nil

        guard hasReadableImage != nil || note != nil else {
            return nil
        }

        return TreasureTimelineItem(
            id: entry.id,
            type: entry.isMilestone ? .milestone : .memory,
            createdAt: entry.createdAt,
            monthKey: monthKey(for: entry.createdAt),
            ageInDays: entry.ageInDays,
            imageLocalPath: hasReadableImage,
            note: note,
            hasImageLoadError: hasImageLoadError,
            isMilestone: entry.isMilestone,
            letterDensity: nil,
            collapsedText: nil,
            expandedText: nil,
            weekStart: nil,
            weekEnd: nil
        )
    }

    private func makeWeeklyLetterItem(letter: WeeklyLetter) -> TreasureTimelineItem {
        let displayDate = endOfDay(for: letter.weekEnd)
        let type: TreasureTimelineItemType
        switch letter.density {
        case .silent:
            type = .weeklyLetterSilent
        case .normal:
            type = .weeklyLetterNormal
        case .dense:
            type = .weeklyLetterDense
        }

        return TreasureTimelineItem(
            id: letter.id,
            type: type,
            createdAt: displayDate,
            monthKey: monthKey(for: displayDate),
            ageInDays: nil,
            imageLocalPath: nil,
            note: nil,
            hasImageLoadError: false,
            isMilestone: false,
            letterDensity: letter.density,
            collapsedText: letter.collapsedText,
            expandedText: letter.expandedText,
            weekStart: letter.weekStart,
            weekEnd: letter.weekEnd
        )
    }

    private func monthKey(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 1
        return String(format: "%04d-%02d", year, month)
    }

    private func endOfDay(for date: Date) -> Date {
        let start = calendar.startOfDay(for: date)
        return calendar.date(byAdding: DateComponents(day: 1, second: -1), to: start) ?? date
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
