import SwiftUI

struct RecordHomeScrollView: View {
    let store: HomeStore
    let isActiveTab: Bool
    @State private var isTimelineScrollInteracting = false
    @State private var scrollInteractionResetTask: Task<Void, Never>?

    init(store: HomeStore, isActiveTab: Bool = true) {
        self.store = store
        self.isActiveTab = isActiveTab
    }

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
                                    guard isActiveTab else { return }
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
        .simultaneousGesture(
            DragGesture(minimumDistance: 8)
                .onChanged { value in
                    guard shouldTrackTimelineScrollInteraction(for: value) else { return }
                    scrollInteractionResetTask?.cancel()
                    scrollInteractionResetTask = nil
                    if !isTimelineScrollInteracting {
                        isTimelineScrollInteracting = true
                    }
                }
                .onEnded { value in
                    guard shouldTrackTimelineScrollInteraction(for: value) else {
                        isTimelineScrollInteracting = false
                        return
                    }
                    scheduleScrollInteractionReset()
                }
        )
        .onDisappear {
            scrollInteractionResetTask?.cancel()
            scrollInteractionResetTask = nil
            isTimelineScrollInteracting = false
        }
    }

    @ViewBuilder
    private func timelineCard(for item: TimelineDisplayItem) -> some View {
        InteractiveTimelineRecordCard(
            item: item,
            store: store,
            cornerRadius: timelineCardCornerRadius(for: item),
            isInteractionEnabled: !isTimelineScrollInteracting
        ) {
            timelineCardContent(for: item)
        }
    }

    @ViewBuilder
    private func timelineCardContent(for item: TimelineDisplayItem) -> some View {
        switch item.cardStyle {
        case .standard:
            StandardRecordCard(item: item)
        case .foodPhoto:
            FoodPhotoCard(item: item)
        }
    }

    private func timelineCardCornerRadius(for item: TimelineDisplayItem) -> CGFloat {
        switch item.cardStyle {
        case .standard:
            AppTheme.Radius.card
        case .foodPhoto:
            AppTheme.Radius.image
        }
    }

    private func scheduleScrollInteractionReset() {
        scrollInteractionResetTask?.cancel()
        scrollInteractionResetTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            isTimelineScrollInteracting = false
            scrollInteractionResetTask = nil
        }
    }

    private func shouldTrackTimelineScrollInteraction(for value: DragGesture.Value) -> Bool {
        let verticalDistance = abs(value.translation.height)
        let horizontalDistance = abs(value.translation.width)
        return verticalDistance >= 10 && verticalDistance > horizontalDistance
    }
}

private struct EmptyTimelineView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "home.timeline.empty.title"))
                .font(AppTheme.Typography.cardTitle)
                .foregroundStyle(AppTheme.Colors.primaryText)

            Text(String(localized: "home.timeline.empty.body"))
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
