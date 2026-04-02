import SwiftUI

struct GrowthChartReferenceRangeLayer: View {
    let metrics: GrowthChartPlotMetrics
    let referenceBands: [GrowthReferenceBandPoint]

    var body: some View {
        referencePath
            .fill(AppTheme.Colors.accent.opacity(0.16))
    }

    private var referencePath: Path {
        Path { path in
            guard referenceBands.count >= 2 else { return }

            let upperPoints = referenceBands.map { CGPoint(x: metrics.xPosition(for: $0.ageInDays), y: metrics.yPosition(for: $0.upper)) }
            let lowerPoints = referenceBands.reversed().map { CGPoint(x: metrics.xPosition(for: $0.ageInDays), y: metrics.yPosition(for: $0.lower)) }

            path.move(to: upperPoints[0])
            addSmoothedSegments(path: &path, points: upperPoints)
            path.addLine(to: lowerPoints[0])
            addSmoothedSegments(path: &path, points: lowerPoints)
            path.closeSubpath()
        }
    }

    private func addSmoothedSegments(path: inout Path, points: [CGPoint]) {
        guard points.count >= 2 else { return }

        if points.count == 2 {
            path.addLine(to: points[1])
            return
        }

        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let midpoint = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)

            if index == 1 {
                path.addQuadCurve(to: midpoint, control: previous)
            } else {
                path.addQuadCurve(to: midpoint, control: previous)
            }

            if index == points.count - 1 {
                path.addQuadCurve(to: current, control: current)
            }
        }
    }
}
