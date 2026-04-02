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
                value: rounded(value, precision: 0.1)
            )
        }
    }

    func makeMetaInfo(from points: [GrowthPoint], metric: GrowthMetric, now: Date) -> GrowthMetaInfo {
        guard let latest = points.last else {
            return GrowthMetaInfo(metric: metric, latestValue: nil, latestRecordedAt: nil, referenceDate: now)
        }

        return GrowthMetaInfo(metric: metric, latestValue: latest.value, latestRecordedAt: latest.date, referenceDate: now)
    }

    func makeTooltip(for point: GrowthPoint, metric: GrowthMetric) -> GrowthTooltipData {
        GrowthTooltipData(
            ageInDays: point.ageInDays,
            value: point.value,
            metric: metric
        )
    }

    func makeAIContent(from points: [GrowthPoint], metric: GrowthMetric) -> GrowthAIContent {
        guard let latest = points.last else {
            return GrowthAIContent(
                expanded: GrowthAIMessage(metric: metric, kind: .inviteFirstRecord),
                collapsed: GrowthAIMessage(metric: metric, kind: .waitingFirstRecord)
            )
        }

        guard points.count >= 2 else {
            let message = GrowthAIMessage(metric: metric, kind: .firstRecordLogged)
            return GrowthAIContent(expanded: message, collapsed: message)
        }

        let previous = points[points.count - 2]
        let intervalDays = max(
            calendar.dateComponents([.day], from: calendar.startOfDay(for: previous.date), to: calendar.startOfDay(for: latest.date)).day ?? 0,
            0
        )
        let delta = rounded(latest.value - previous.value, precision: 0.1)
        let direction: GrowthAIChangeDirection
        if delta == 0 {
            direction = .unchanged
        } else if delta > 0 {
            direction = .increased
        } else {
            direction = .decreased
        }

        let message = GrowthAIMessage(
            metric: metric,
            kind: .change(intervalDays: intervalDays, direction: direction, deltaValue: abs(delta))
        )

        return GrowthAIContent(
            expanded: message,
            collapsed: message
        )
    }

    func makeYAxisLabels(
        points: [GrowthPoint],
        referenceBands: [GrowthReferenceBandPoint],
        metric: GrowthMetric
    ) -> [GrowthYAxisLabel] {
        let allValues = points.map(\.value) + referenceBands.flatMap { [$0.lower, $0.upper] }
        guard let minValue = allValues.min(), let maxValue = allValues.max(), minValue < maxValue else {
            return [GrowthYAxisLabel(id: "middle", value: 1.0, normalizedY: 0.5)]
        }

        let padding = max((maxValue - minValue) * 0.08, 0.4)
        let lower = minValue - padding
        let upper = maxValue + padding
        let middle = (lower + upper) / 2

        return [
            GrowthYAxisLabel(id: "upper", value: upper, normalizedY: 0.0),
            GrowthYAxisLabel(id: "middle", value: middle, normalizedY: 0.5),
            GrowthYAxisLabel(id: "lower", value: lower, normalizedY: 1.0)
        ]
    }

    private func rounded(_ value: Double, precision: Double) -> Double {
        guard precision > 0 else { return value }
        return (value / precision).rounded() * precision
    }
}
