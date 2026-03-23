import SwiftUI

struct RecordHomeScrollView: View {
    let store: HomeStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
                EmotionHeaderBlock(headerConfig: store.headerConfig, referenceDate: .now)

                if store.timelineItems.isEmpty {
                    EmptyTimelineView()
                        .padding(.top, 12)
                } else {
                    LazyVStack(spacing: AppTheme.Spacing.cardGap) {
                        ForEach(store.timelineItems) { item in
                            timelineCard(for: item)
                                .onAppear {
                                    store.handle(.loadMoreIfNeeded(item.recordID))
                                }
                        }

                        if store.viewState.isLoadingHistory {
                            ProgressView()
                                .tint(AppTheme.Colors.secondaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.screenHorizontal)
            .padding(.bottom, 20)
        }
    }

    @ViewBuilder
    private func timelineCard(for item: TimelineDisplayItem) -> some View {
        switch item.cardStyle {
        case .standard:
            StandardRecordCard(item: item)
        case .foodPhoto:
            FoodPhotoCard(item: item)
        }
    }
}

private struct EmptyTimelineView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("今天还没有记录")
                .font(AppTheme.Typography.cardTitle)
                .foregroundStyle(AppTheme.Colors.primaryText)

            Text("先记一笔奶量、尿布、睡眠或辅食，时间线会安静地接住今天。")
                .font(AppTheme.Typography.cardBody)
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
        .shadow(color: AppTheme.Shadow.color, radius: AppTheme.Shadow.radius, y: AppTheme.Shadow.y)
    }
}
