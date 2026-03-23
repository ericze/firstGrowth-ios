import SwiftUI

struct TreasureTopFilterBar: View {
    let selectedFilter: TreasureFilter
    let onSelect: (TreasureFilter) -> Void

    @Namespace private var selectionNamespace
    private let itemSpacing: CGFloat = 24
    private let labelSpacing: CGFloat = 4
    private let indicatorSpacing: CGFloat = 6
    private let touchInset: CGFloat = 10
    private let labelFontSize: CGFloat = 13
    private let iconFontSize: CGFloat = 12
    private let indicatorSize: CGFloat = 4

    var body: some View {
        HStack(spacing: itemSpacing) {
            ForEach(TreasureFilter.allCases) { filter in
                Button {
                    onSelect(filter)
                } label: {
                    VStack(alignment: .leading, spacing: indicatorSpacing) {
                        HStack(spacing: labelSpacing) {
                            if let iconName = filter.iconName {
                                Image(systemName: iconName)
                                    .font(.system(size: iconFontSize, weight: .regular))
                                    .foregroundStyle(iconColor(for: filter))
                            }

                            Text(filter.displayTitle)
                                .font(.system(size: labelFontSize, weight: fontWeight(for: filter)))
                                .foregroundStyle(textColor(for: filter))
                        }

                        indicator(for: filter)
                    }
                    .padding(.horizontal, touchInset)
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(filter.accessibilityLabel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(AppTheme.stateAnimation, value: selectedFilter)
    }

    @ViewBuilder
    private func indicator(for filter: TreasureFilter) -> some View {
        Circle()
            .fill(filter == selectedFilter ? AppTheme.Colors.sageGreen : .clear)
            .frame(width: indicatorSize, height: indicatorSize)
            .matchedGeometryEffect(
                id: filter == selectedFilter ? "treasure-filter-indicator" : filter.id,
                in: selectionNamespace
            )
    }

    private func textColor(for filter: TreasureFilter) -> Color {
        filter == selectedFilter
            ? AppTheme.Colors.primaryText
            : AppTheme.Colors.primaryText.opacity(0.4)
    }

    private func iconColor(for filter: TreasureFilter) -> Color {
        filter == selectedFilter
            ? AppTheme.Colors.sageGreen
            : AppTheme.Colors.primaryText.opacity(0.4)
    }

    private func fontWeight(for filter: TreasureFilter) -> Font.Weight {
        filter == selectedFilter ? .semibold : .regular
    }
}

private extension TreasureFilter {
    var displayTitle: String {
        switch self {
        case .allMemories:
            "全部记忆"
        case .starredMoments:
            "星标时刻"
        case .timeLetters:
            "时光信笺"
        }
    }

    var iconName: String? {
        switch self {
        case .allMemories:
            nil
        case .starredMoments:
            "star.fill"
        case .timeLetters:
            "envelope.fill"
        }
    }
}
