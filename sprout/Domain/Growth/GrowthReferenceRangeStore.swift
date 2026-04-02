import Foundation

struct GrowthReferenceRangeStore {
    private let samples: [GrowthMetric: [GrowthReferenceBandPoint]] = [
        .height: [
            GrowthReferenceBandPoint(ageInDays: 0, lower: 47.0, upper: 53.5),
            GrowthReferenceBandPoint(ageInDays: 30, lower: 50.5, upper: 58.0),
            GrowthReferenceBandPoint(ageInDays: 90, lower: 56.0, upper: 64.0),
            GrowthReferenceBandPoint(ageInDays: 180, lower: 62.0, upper: 72.0),
            GrowthReferenceBandPoint(ageInDays: 270, lower: 67.0, upper: 77.0),
            GrowthReferenceBandPoint(ageInDays: 365, lower: 72.0, upper: 82.0),
            GrowthReferenceBandPoint(ageInDays: 540, lower: 79.0, upper: 91.0),
            GrowthReferenceBandPoint(ageInDays: 730, lower: 85.0, upper: 98.0),
            GrowthReferenceBandPoint(ageInDays: 1095, lower: 93.0, upper: 108.0)
        ],
        .weight: [
            GrowthReferenceBandPoint(ageInDays: 0, lower: 2.8, upper: 4.4),
            GrowthReferenceBandPoint(ageInDays: 30, lower: 3.8, upper: 5.8),
            GrowthReferenceBandPoint(ageInDays: 90, lower: 4.8, upper: 7.8),
            GrowthReferenceBandPoint(ageInDays: 180, lower: 6.0, upper: 9.2),
            GrowthReferenceBandPoint(ageInDays: 270, lower: 6.8, upper: 10.2),
            GrowthReferenceBandPoint(ageInDays: 365, lower: 7.5, upper: 11.0),
            GrowthReferenceBandPoint(ageInDays: 540, lower: 8.5, upper: 12.5),
            GrowthReferenceBandPoint(ageInDays: 730, lower: 9.5, upper: 13.8),
            GrowthReferenceBandPoint(ageInDays: 1095, lower: 11.0, upper: 16.0)
        ]
    ]

    nonisolated init() {}

    func referenceBands(for metric: GrowthMetric, maxAgeInDays: Int) -> [GrowthReferenceBandPoint] {
        guard let series = samples[metric], !series.isEmpty else { return [] }

        let targetAge = max(maxAgeInDays, series.first?.ageInDays ?? 0)
        let lowerSlice = series.filter { $0.ageInDays <= targetAge }
        let upperNeighbor = series.first { $0.ageInDays > targetAge }

        if let upperNeighbor {
            return lowerSlice + [upperNeighbor]
        }

        return lowerSlice
    }
}
