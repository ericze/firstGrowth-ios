import SwiftUI

struct GrowthChartTooltipBubble: View {
    let tooltip: GrowthTooltipData
    let xPosition: CGFloat

    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .leading, spacing: 3) {
                Text(tooltip.ageText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.secondaryText)

                Text(tooltip.valueText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.primaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: AppTheme.Shadow.color, radius: 8, y: 4)
            .position(
                x: min(max(xPosition, 74), max(proxy.size.width - 74, 74)),
                y: 26
            )
        }
        .allowsHitTesting(false)
    }
}
