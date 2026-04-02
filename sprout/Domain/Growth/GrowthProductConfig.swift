import Foundation

struct GrowthProductConfig: Equatable, Sendable {
    let defaultHeightValue: Double
    let defaultWeightValue: Double
    let heightRange: ClosedRange<Double>
    let weightRange: ClosedRange<Double>
    let chartMinimumVisibleAgeInDays: Int
    let chartTrailingAgePaddingInDays: Int

    nonisolated static let appDefault = GrowthProductConfig(
        defaultHeightValue: 50.0,
        defaultWeightValue: 3.5,
        heightRange: 40.0...110.0,
        weightRange: 2.0...25.0,
        chartMinimumVisibleAgeInDays: 120,
        chartTrailingAgePaddingInDays: 30
    )

    nonisolated func defaultValue(for metric: GrowthMetric) -> Double {
        switch metric {
        case .height:
            defaultHeightValue
        case .weight:
            defaultWeightValue
        }
    }
}
