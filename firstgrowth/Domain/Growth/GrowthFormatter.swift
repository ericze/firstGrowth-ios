import Foundation

struct GrowthFormatter {
    private let calendar: Calendar

    nonisolated init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func makePoints(from records: [RecordItem], metric: GrowthMetric, birthDate: Date) -> [GrowthPoint] {
        records.compactMap { record in
            guard record.recordType == metric.recordType, let value = record.value, value > 0 else {
                return nil
            }

            let ageInDays = max(
                calendar.dateComponents(
                    [.day],
                    from: calendar.startOfDay(for: birthDate),
                    to: calendar.startOfDay(for: record.timestamp)
                ).day ?? 0,
                0
            )

            return GrowthPoint(
                id: record.id,
                recordID: record.id,
                date: record.timestamp,
                ageInDays: ageInDays,
                ageText: formatAgeText(ageInDays),
                value: rounded(value, precision: 0.1)
            )
        }
    }

    func makeMetaInfo(from points: [GrowthPoint], metric: GrowthMetric, now: Date) -> GrowthMetaInfo {
        guard let latest = points.last else {
            return GrowthMetaInfo(summaryText: metric.emptyText)
        }

        let valueText = formatValue(latest.value, metric: metric)
        let relativeText = formatRelativeTime(from: latest.date, to: now)
        return GrowthMetaInfo(summaryText: "最新记录：\(valueText) · \(relativeText)")
    }

    func makeTooltip(for point: GrowthPoint, metric: GrowthMetric) -> GrowthTooltipData {
        GrowthTooltipData(
            ageText: point.ageText,
            valueText: formatValue(point.value, metric: metric)
        )
    }

    func makeAIContent(from points: [GrowthPoint], metric: GrowthMetric) -> GrowthAIContent {
        guard let latest = points.last else {
            let unitTitle = metric == .height ? "身高" : "体重"
            return GrowthAIContent(
                expandedText: "✨ 记录第一条\(unitTitle)数据，生命线会从这里开始。",
                collapsedText: "✨ 等待第一条\(unitTitle)记录"
            )
        }

        guard points.count >= 2 else {
            let summary = "✨ 已记录第一条\(metric.title)数据"
            return GrowthAIContent(expandedText: summary, collapsedText: summary)
        }

        let previous = points[points.count - 2]
        let intervalDays = max(
            calendar.dateComponents([.day], from: calendar.startOfDay(for: previous.date), to: calendar.startOfDay(for: latest.date)).day ?? 0,
            0
        )
        let delta = rounded(latest.value - previous.value, precision: 0.1)
        let absDelta = abs(delta)
        let deltaText = formatValue(absDelta, metric: metric)
        let intervalText = intervalDays == 0 ? "0天" : "\(intervalDays)天"

        let expandedText: String
        if delta == 0 {
            expandedText = "距离上次记录过去了 \(intervalText)，\(metric.title)与上次持平。"
        } else if delta > 0 {
            expandedText = "距离上次记录过去了 \(intervalText)，\(metric.title)增加了 \(deltaText)。"
        } else {
            expandedText = "距离上次记录过去了 \(intervalText)，\(metric.title)较上次减少了 \(deltaText)。"
        }

        return GrowthAIContent(
            expandedText: expandedText,
            collapsedText: "✨ 记录了距上次\(intervalText)的变化"
        )
    }

    func makeYAxisLabels(
        points: [GrowthPoint],
        referenceBands: [GrowthReferenceBandPoint],
        metric: GrowthMetric
    ) -> [GrowthYAxisLabel] {
        let allValues = points.map(\.value) + referenceBands.flatMap { [$0.lower, $0.upper] }
        guard let minValue = allValues.min(), let maxValue = allValues.max(), minValue < maxValue else {
            let valueText = formatValue(1.0, metric: metric)
            return [GrowthYAxisLabel(id: valueText, text: valueText, normalizedY: 0.5)]
        }

        let padding = max((maxValue - minValue) * 0.08, 0.4)
        let lower = minValue - padding
        let upper = maxValue + padding
        let middle = (lower + upper) / 2

        return [
            GrowthYAxisLabel(id: "upper", text: formatValue(upper, metric: metric), normalizedY: 0.0),
            GrowthYAxisLabel(id: "middle", text: formatValue(middle, metric: metric), normalizedY: 0.5),
            GrowthYAxisLabel(id: "lower", text: formatValue(lower, metric: metric), normalizedY: 1.0)
        ]
    }

    func formatValue(_ value: Double, metric: GrowthMetric) -> String {
        "\(String(format: "%.1f", value))\(metric.unit)"
    }

    func formatEditableValue(_ value: Double) -> String {
        String(format: "%.1f", rounded(value, precision: 0.1))
    }

    func formatAxisLabel(ageInDays: Int) -> String {
        if ageInDays < 30 {
            return "\(max(ageInDays, 0))天"
        }

        let months = max(ageInDays / 30, 0)
        if months < 24 {
            return "\(months)月"
        }

        let years = months / 12
        let remainingMonths = months % 12
        return remainingMonths == 0 ? "\(years)岁" : "\(years)岁\(remainingMonths)月"
    }

    private func formatAgeText(_ ageInDays: Int) -> String {
        if ageInDays < 30 {
            return "\(ageInDays)天"
        }

        let months = ageInDays / 30
        if months < 24 {
            return "\(months)个月"
        }

        let years = months / 12
        let remainingMonths = months % 12
        return remainingMonths == 0 ? "\(years)岁" : "\(years)岁\(remainingMonths)个月"
    }

    private func formatRelativeTime(from date: Date, to now: Date) -> String {
        let dayDelta = max(
            calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)).day ?? 0,
            0
        )

        if dayDelta == 0 {
            return "今天"
        }
        if dayDelta < 30 {
            return "\(dayDelta)天前"
        }

        let monthDelta = max(calendar.dateComponents([.month], from: date, to: now).month ?? 0, 1)
        if monthDelta < 12 {
            return "\(monthDelta)个月前"
        }

        let yearDelta = max(calendar.dateComponents([.year], from: date, to: now).year ?? 1, 1)
        return "\(yearDelta)年前"
    }

    private func rounded(_ value: Double, precision: Double) -> Double {
        guard precision > 0 else { return value }
        return (value / precision).rounded() * precision
    }
}
