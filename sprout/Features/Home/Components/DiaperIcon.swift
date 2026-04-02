import SwiftUI

struct DiaperIcon: View {
    var color: Color = AppTheme.Colors.primaryText
    var lineWidth: CGFloat = 2

    var body: some View {
        GeometryReader { proxy in
            let metrics = DiaperIconMetrics(size: proxy.size, baseLineWidth: lineWidth)

            ZStack {
                bodyPath(metrics: metrics)
                    .stroke(color, style: metrics.strokeStyle)

                waistPath(metrics: metrics)
                    .stroke(color, style: metrics.strokeStyle)

                sideTabsPath(metrics: metrics)
                    .stroke(color, style: metrics.strokeStyle)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private func bodyPath(metrics: DiaperIconMetrics) -> Path {
        Path { path in
            path.move(to: metrics.point(x: 4, y: 6))
            path.addLine(to: metrics.point(x: 20, y: 6))
            path.addLine(to: metrics.point(x: 20, y: 10))
            path.addCurve(
                to: metrics.point(x: 12, y: 18),
                control1: metrics.point(x: 20, y: 14.5),
                control2: metrics.point(x: 16.5, y: 18)
            )
            path.addCurve(
                to: metrics.point(x: 4, y: 10),
                control1: metrics.point(x: 7.5, y: 18),
                control2: metrics.point(x: 4, y: 14.5)
            )
            path.closeSubpath()
        }
    }

    private func waistPath(metrics: DiaperIconMetrics) -> Path {
        Path { path in
            path.move(to: metrics.point(x: 4, y: 6))
            path.addCurve(
                to: metrics.point(x: 12, y: 6),
                control1: metrics.point(x: 4.2, y: 8.1),
                control2: metrics.point(x: 9.3, y: 8.2)
            )
            path.addCurve(
                to: metrics.point(x: 20, y: 6),
                control1: metrics.point(x: 14.7, y: 8.2),
                control2: metrics.point(x: 19.8, y: 8.1)
            )
        }
    }

    private func sideTabsPath(metrics: DiaperIconMetrics) -> Path {
        Path { path in
            path.move(to: metrics.point(x: 3, y: 7))
            path.addLine(to: metrics.point(x: 5, y: 6))

            path.move(to: metrics.point(x: 21, y: 7))
            path.addLine(to: metrics.point(x: 19, y: 6))
        }
    }
}

private struct DiaperIconMetrics {
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
