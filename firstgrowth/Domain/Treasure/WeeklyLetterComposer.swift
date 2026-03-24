import Foundation

struct WeeklyLetterComposer {
    private let calendar: Calendar
    private let bannedTerms = [
        "击败", "超越", "落后", "领先", "优秀", "达标", "偏瘦", "偏胖",
        "健康", "发育", "奖励", "解锁", "成就", "荣耀", "任务完成"
    ]

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func compose(
        entries: [MemoryEntry],
        weekStart: Date,
        weekEnd: Date,
        generatedAt: Date
    ) -> WeeklyLetter? {
        guard !entries.isEmpty else { return nil }

        let normalizedEntries = entries.sorted { $0.createdAt < $1.createdAt }
        let photoCount = normalizedEntries.reduce(into: 0) { partialResult, entry in
            partialResult += normalizedImageCount(for: entry)
        }
        let textCount = normalizedEntries.filter { !($0.note?.trimmed.isEmpty ?? true) }.count
        let milestoneCount = normalizedEntries.filter(\.isMilestone).count
        let density = makeDensity(entryCount: normalizedEntries.count, milestoneCount: milestoneCount)
        let collapsedText = makeCollapsedText(for: density)
        let expandedText = makeExpandedText(
            density: density,
            entries: normalizedEntries,
            photoCount: photoCount,
            textCount: textCount,
            milestoneCount: milestoneCount
        )

        guard isAllowed(collapsedText, density: density, isCollapsed: true),
              isAllowed(expandedText, density: density, isCollapsed: false) else {
            return nil
        }

        return WeeklyLetter(
            weekStart: calendar.startOfDay(for: weekStart),
            weekEnd: calendar.startOfDay(for: weekEnd),
            density: density,
            collapsedText: collapsedText,
            expandedText: expandedText,
            generatedAt: generatedAt
        )
    }

    private func makeDensity(entryCount: Int, milestoneCount: Int) -> WeeklyLetterDensity {
        if milestoneCount > 0 || entryCount >= 5 {
            return .dense
        }
        if (2...4).contains(entryCount) {
            return .normal
        }
        return .silent
    }

    private func makeCollapsedText(for density: WeeklyLetterDensity) -> String {
        switch density {
        case .silent:
            "这一周，被轻轻收下了。"
        case .normal:
            "时间寄来了一封这周的信。"
        case .dense:
            "这一周，留了一封更厚一点的信。"
        }
    }

    private func makeExpandedText(
        density: WeeklyLetterDensity,
        entries: [MemoryEntry],
        photoCount: Int,
        textCount: Int,
        milestoneCount: Int
    ) -> String {
        let firstNoteSnippet = entries
            .compactMap { $0.note?.trimmed.nilIfEmpty }
            .first?
            .prefix(18) ?? ""

        switch density {
        case .silent:
            return "这一周只留下了一条记忆，日子照常往前。"
        case .normal:
            var segments = ["这一周留下了\(entries.count)条记忆"]
            if photoCount > 0 {
                segments.append("\(photoCount)张照片")
            }
            if textCount > 0 {
                segments.append("\(textCount)段文字")
            }

            let joined = segments.joined(separator: "、")
            return "\(joined)。几件小事被安静地留下，时间也在这些片刻里慢慢往前。"
        case .dense:
            var prefix = "这一周留下的内容比平时多一些。"
            if milestoneCount > 0 {
                prefix += "其中有\(milestoneCount)个被轻轻打上了星号。"
            }

            let middle = "照片和文字把这一页写得更厚了一点，\(entries.count)条记忆围着这周慢慢排开。"
            let ending: String
            if firstNoteSnippet.isEmpty {
                ending = "它们不需要被宣布，只要在翻到这里时，再被看见一次。"
            } else {
                ending = "像“\(firstNoteSnippet)”这样的片刻，也被稳稳留了下来。"
            }
            return "\(prefix)\(middle)\(ending)"
        }
    }

    private func isAllowed(_ text: String, density: WeeklyLetterDensity, isCollapsed: Bool) -> Bool {
        guard !text.trimmed.isEmpty else { return false }
        guard bannedTerms.allSatisfy({ !text.contains($0) }) else { return false }

        let maxLength: Int
        if isCollapsed {
            maxLength = density == .silent ? 30 : 18
        } else {
            switch density {
            case .silent:
                maxLength = 30
            case .normal:
                maxLength = 100
            case .dense:
                maxLength = 250
            }
        }

        return text.count <= maxLength
    }

    private func normalizedImageCount(for entry: MemoryEntry) -> Int {
        entry.imageLocalPaths.count
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
