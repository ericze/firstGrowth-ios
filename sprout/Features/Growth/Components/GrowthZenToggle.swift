import SwiftUI

struct GrowthZenToggle: View {
    let selectedMetric: GrowthMetric
    let onSelect: (GrowthMetric) -> Void

    @Namespace private var selectionNamespace
    private let textRenderer = GrowthTextRenderer()

    var body: some View {
        HStack(spacing: 8) {
            ForEach(GrowthMetric.allCases) { metric in
                Button {
                    onSelect(metric)
                } label: {
                    Text(textRenderer.metricTitle(metric))
                        .font(.system(size: 16, weight: metric == selectedMetric ? .semibold : .medium))
                        .foregroundStyle(metric == selectedMetric ? AppTheme.Colors.primaryText : AppTheme.Colors.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                        .background {
                            if metric == selectedMetric {
                                Capsule()
                                    .fill(AppTheme.Colors.accent.opacity(0.26))
                                    .matchedGeometryEffect(id: "growth-toggle", in: selectionNamespace)
                            }
                        }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 4)
            }
        }
        .padding(6)
        .background(AppTheme.Colors.cardBackground.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
    }
}
