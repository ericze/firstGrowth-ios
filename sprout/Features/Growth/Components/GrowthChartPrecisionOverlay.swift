import SwiftUI

struct GrowthChartPrecisionOverlay: View {
    let metrics: GrowthChartPlotMetrics
    let selection: GrowthChartSelection?
    let labels: [GrowthYAxisLabel]
    let metric: GrowthMetric
    let isVisible: Bool
    private let textRenderer = GrowthTextRenderer()

    var body: some View {
        ZStack(alignment: .trailing) {
            if isVisible {
                Rectangle()
                    .fill(AppTheme.Colors.primaryText.opacity(0.04))
            }

            if let selection, isVisible {
                let point = metrics.point(for: selection.point)

                Rectangle()
                    .fill(AppTheme.Colors.highlight.opacity(0.45))
                    .frame(width: 1.5)
                    .position(x: point.x, y: metrics.size.height / 2)

                Circle()
                    .fill(AppTheme.Colors.cardBackground)
                    .frame(width: 16, height: 16)
                    .overlay {
                        Circle()
                            .stroke(AppTheme.Colors.highlight, lineWidth: 2)
                    }
                    .position(point)
            }

            if isVisible {
                ZStack(alignment: .trailing) {
                    ForEach(labels) { label in
                        Text(textRenderer.yAxisLabelText(label, metric: metric))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.Colors.secondaryText)
                            .position(
                                x: max(metrics.size.width - 22, 22),
                                y: metrics.yPosition(for: label)
                            )
                    }
                }
            }
        }
        .animation(.easeOut(duration: 0.18), value: isVisible)
    }
}
