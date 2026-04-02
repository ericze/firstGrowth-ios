import SwiftUI

struct GrowthChartNodeLayer: View {
    let metrics: GrowthChartPlotMetrics
    let points: [GrowthPoint]
    let selection: GrowthChartSelection?

    var body: some View {
        ZStack {
            ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                let isSelected = selection?.index == index
                Circle()
                    .fill(isSelected ? AppTheme.Colors.highlight : AppTheme.Colors.primaryText.opacity(0.22))
                    .frame(width: isSelected ? 9 : 6, height: isSelected ? 9 : 6)
                    .position(metrics.point(for: point))
            }
        }
    }
}
