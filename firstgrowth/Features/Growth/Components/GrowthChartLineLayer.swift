import SwiftUI

struct GrowthChartLineLayer: View {
    let metrics: GrowthChartPlotMetrics
    let points: [GrowthPoint]

    var body: some View {
        linePath
            .stroke(
                AppTheme.Colors.primaryText,
                style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round)
            )
    }

    private var linePath: Path {
        Path { path in
            guard let first = points.first else { return }
            let firstPoint = metrics.point(for: first)
            path.move(to: firstPoint)

            guard points.count > 1 else { return }

            if points.count < 3 {
                for point in points.dropFirst() {
                    path.addLine(to: metrics.point(for: point))
                }
                return
            }

            let mappedPoints = points.map(metrics.point(for:))

            for index in 1..<mappedPoints.count {
                let previous = mappedPoints[index - 1]
                let current = mappedPoints[index]
                let midpoint = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)

                if index == 1 {
                    path.addQuadCurve(to: midpoint, control: previous)
                } else {
                    path.addQuadCurve(to: midpoint, control: previous)
                }

                if index == mappedPoints.count - 1 {
                    path.addQuadCurve(to: current, control: current)
                }
            }
        }
    }
}
