import SwiftUI

struct TreasureTimelineList: View {
    let dataState: TreasureDataState
    let filter: TreasureFilter
    let items: [TreasureTimelineItem]
    let errorMessage: String?
    let onTapWeeklyLetter: (UUID) -> Void

    var body: some View {
        if items.isEmpty {
            TreasureEmptyState(filter: filter, dataState: dataState, errorMessage: errorMessage)
        } else {
            LazyVStack(alignment: .leading, spacing: AppTheme.Spacing.cardGap) {
                ForEach(items) { item in
                    card(for: item)
                        .id(item.id)
                }
            }
        }
    }

    @ViewBuilder
    private func card(for item: TreasureTimelineItem) -> some View {
        switch item.type {
        case .memory:
            TreasureMemoryCard(item: item)
        case .milestone:
            TreasureMilestoneCard(item: item)
        case .weeklyLetterSilent, .weeklyLetterNormal, .weeklyLetterDense:
            TreasureWeeklyLetterCard(item: item, onTap: {
                onTapWeeklyLetter(item.id)
            })
        }
    }
}
