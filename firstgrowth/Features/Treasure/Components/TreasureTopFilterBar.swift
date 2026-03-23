import SwiftUI

struct TreasureTopFilterBar: View {
    let selectedFilter: TreasureFilter
    let onSelect: (TreasureFilter) -> Void

    @Namespace private var selectionNamespace

    var body: some View {
        HStack(spacing: 8) {
            ForEach(TreasureFilter.allCases) { filter in
                Button {
                    onSelect(filter)
                } label: {
                    Text(filter.title)
                        .font(.system(size: 15, weight: filter == selectedFilter ? .semibold : .medium))
                        .foregroundStyle(filter == selectedFilter ? AppTheme.Colors.primaryText : AppTheme.Colors.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                        .background {
                            if filter == selectedFilter {
                                Capsule()
                                    .fill(AppTheme.Colors.accent.opacity(0.24))
                                    .matchedGeometryEffect(id: "treasure-filter", in: selectionNamespace)
                            }
                        }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 4)
                .accessibilityLabel(filter.accessibilityLabel)
            }
        }
        .padding(6)
        .background(AppTheme.Colors.cardBackground.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
        .shadow(color: AppTheme.Shadow.color, radius: 8, y: 4)
    }
}
