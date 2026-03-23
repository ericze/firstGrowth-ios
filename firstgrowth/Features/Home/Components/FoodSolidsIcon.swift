import SwiftUI

struct FoodSolidsIcon: View {
    var color: Color = AppTheme.Colors.primaryText
    var lineWidth: CGFloat = 2

    var body: some View {
        GeometryReader { proxy in
            let metrics = FoodSolidsMetrics(size: proxy.size, baseLineWidth: lineWidth)

            ZStack {
                bowlPath(metrics: metrics)
                    .stroke(color, style: metrics.strokeStyle)

                spoonPath(metrics: metrics)
                    .stroke(color, style: metrics.strokeStyle)

                spoonHandlePath(metrics: metrics)
                    .stroke(color, style: metrics.strokeStyle)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private func bowlPath(metrics: FoodSolidsMetrics) -> Path {
        Path { path in
            path.move(to: metrics.point(x: 4, y: 11))
            path.addCurve(
                to: metrics.point(x: 12, y: 19),
                control1: metrics.point(x: 4, y: 15.418),
                control2: metrics.point(x: 7.582, y: 19)
            )
            path.addCurve(
                to: metrics.point(x: 20, y: 11),
                control1: metrics.point(x: 16.418, y: 19),
                control2: metrics.point(x: 20, y: 15.418)
            )
            path.addLine(to: metrics.point(x: 4, y: 11))
        }
    }

    private func spoonPath(metrics: FoodSolidsMetrics) -> Path {
        Path { path in
            path.move(to: metrics.point(x: 15, y: 5))
            path.addCurve(
                to: metrics.point(x: 12, y: 8),
                control1: metrics.point(x: 15, y: 6.5),
                control2: metrics.point(x: 14, y: 8)
            )
            path.addCurve(
                to: metrics.point(x: 9, y: 5),
                control1: metrics.point(x: 10, y: 8),
                control2: metrics.point(x: 9, y: 6.5)
            )
        }
    }

    private func spoonHandlePath(metrics: FoodSolidsMetrics) -> Path {
        Path { path in
            path.move(to: metrics.point(x: 12, y: 8))
            path.addLine(to: metrics.point(x: 12, y: 11))
        }
    }
}

private struct FoodSolidsMetrics {
    let size: CGSize
    let baseLineWidth: CGFloat

    private var unitScale: CGFloat {
        min(size.width, size.height) / 24
    }

    private var drawingSize: CGFloat {
        unitScale * 24
    }

    private var xInset: CGFloat {
        (size.width - drawingSize) / 2
    }

    private var yInset: CGFloat {
        (size.height - drawingSize) / 2
    }

    func point(x: CGFloat, y: CGFloat) -> CGPoint {
        CGPoint(x: xInset + x * unitScale, y: yInset + y * unitScale)
    }

    var strokeStyle: StrokeStyle {
        StrokeStyle(
            lineWidth: baseLineWidth * unitScale,
            lineCap: .round,
            lineJoin: .round
        )
    }
}
