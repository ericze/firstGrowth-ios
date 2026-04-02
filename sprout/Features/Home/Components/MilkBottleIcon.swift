import SwiftUI

struct MilkBottleIcon: View {
    var color: Color = AppTheme.Colors.primaryText
    var lineWidth: CGFloat = 1.5

    var body: some View {
        GeometryReader { proxy in
            let metrics = MilkBottleMetrics(size: proxy.size, baseLineWidth: lineWidth)

            ZStack {
                RoundedRectangle(cornerRadius: metrics.scale(2), style: .continuous)
                    .path(in: metrics.rect(x: 7, y: 7.5, width: 10, height: 13.5))
                    .stroke(color, style: metrics.strokeStyle)

                neckPath(metrics: metrics)
                    .stroke(color, style: metrics.strokeStyle)

                measurementLine(y: 11.5, metrics: metrics)
                    .stroke(color, style: metrics.strokeStyle)

                measurementLine(y: 15.5, metrics: metrics)
                    .stroke(color, style: metrics.strokeStyle)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private func neckPath(metrics: MilkBottleMetrics) -> Path {
        Path { path in
            path.move(to: metrics.point(x: 10, y: 7.5))
            path.addLine(to: metrics.point(x: 10, y: 5.5))

            path.addQuadCurve(
                to: metrics.point(x: 14, y: 5.5),
                control: metrics.point(x: 12, y: 2.5)
            )

            path.addLine(to: metrics.point(x: 14, y: 7.5))
        }
    }

    private func measurementLine(y: CGFloat, metrics: MilkBottleMetrics) -> Path {
        Path { path in
            path.move(to: metrics.point(x: 7, y: y))
            path.addLine(to: metrics.point(x: 17, y: y))
        }
    }
}

private struct MilkBottleMetrics {
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

    func rect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> CGRect {
        CGRect(
            x: xInset + x * unitScale,
            y: yInset + y * unitScale,
            width: width * unitScale,
            height: height * unitScale
        )
    }

    func scale(_ value: CGFloat) -> CGFloat {
        value * unitScale
    }

    var strokeStyle: StrokeStyle {
        StrokeStyle(
            lineWidth: baseLineWidth * unitScale,
            lineCap: .round,
            lineJoin: .round
        )
    }
}
