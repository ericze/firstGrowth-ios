import Observation
import SwiftUI

struct MainTabContentView: View {
    @Bindable var store: HomeStore
    @Bindable var growthStore: GrowthStore
    @Bindable var treasureStore: TreasureStore
    @Binding var selectedTab: HomeModule
    let isSidebarPresented: Bool
    let isSidebarInteracting: Bool
    let onRevealSidebarChanged: (CGFloat) -> Void
    let onRevealSidebarEnded: (DragGesture.Value) -> Void

    var body: some View {
        GeometryReader { geometry in
            RootPagerView(
                selectedTab: $selectedTab,
                defersRecordSidebarReveal: selectedTab == .record && !isSidebarPresented && store.canRevealSidebarFromRoot,
                isSidebarInteractionInProgress: isSidebarInteracting
            ) {
                RecordRootView(
                    store: store,
                    isActiveTab: selectedTab == .record,
                    isSidebarPresented: isSidebarPresented,
                    onRevealSidebarChanged: onRevealSidebarChanged,
                    onRevealSidebarEnded: onRevealSidebarEnded
                )
            } growthPage: {
                GrowthView(store: growthStore)
            } collectionPage: {
                CollectionView(store: treasureStore)
            }
            .background(AppTheme.Colors.background)
            .overlay(alignment: .bottom) {
                if selectedTab == .record {
                    VStack(spacing: AppTheme.Spacing.floatingGap) {
                        if let ongoingSleep = store.viewState.ongoingSleep {
                            OngoingStateBar(
                                session: ongoingSleep,
                                onTap: { store.handle(.tapOngoingSleep) },
                                onEnd: { store.handle(.finishSleep) }
                            )
                            .padding(.horizontal, AppTheme.Spacing.screenHorizontal)
                        }

                        FloatingActionBar(
                            hasOngoingSleep: store.viewState.ongoingSleep != nil,
                            onMilkTapped: { store.handle(.tapMilkEntry) },
                            onFoodTapped: { store.handle(.tapFoodEntry) },
                            onDiaperTapped: { store.handle(.tapDiaperEntry) },
                            onStartSleep: { store.handle(.tapSleepEntry) },
                            onEndSleep: { store.handle(.finishSleep) }
                        )
                    }
                    .padding(.top, 8)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + AppTheme.Spacing.floatingBottom)
                    .background(Color.clear)
                }
            }
            .overlay(alignment: .bottom) {
                if let toast = activeUndoToast {
                    UndoToast(
                        state: toast,
                        onUndo: performUndo,
                        onDismiss: dismissUndo
                    )
                    .padding(.horizontal, AppTheme.Spacing.screenHorizontal)
                    .padding(.bottom, selectedTab == .record ? 134 : 36)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if let messageToast = activeMessageToast {
                    MessageToast(
                        state: messageToast,
                        onDismiss: dismissMessage
                    )
                    .padding(.horizontal, AppTheme.Spacing.screenHorizontal)
                    .padding(.bottom, selectedTab == .record ? 134 : 36)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(AppTheme.stateAnimation, value: activeUndoToast)
            .animation(AppTheme.stateAnimation, value: activeMessageToast)
            .sheet(item: activeSheetBinding) { sheet in
                sheetView(for: sheet)
            }
            .sheet(item: activeDeleteSummaryBinding) { summary in
                RecordDeleteConfirmationSheet(
                    summary: summary,
                    onConfirm: { store.handle(.confirmDeleteRecord) },
                    onCancel: { store.handle(.cancelDeleteRecord) }
                )
                .presentationDetents([.height(348)])
                .presentationDragIndicator(.visible)
                .presentationBackground(AppTheme.Colors.background)
            }
        }
    }

    private var activeSheetBinding: Binding<ActiveSheet?> {
        Binding(
            get: { store.routeState.activeSheet },
            set: { newValue in
                if newValue == nil {
                    switch store.routeState.activeSheet {
                    case .recordEditor:
                        store.handle(.dismissRecordEditor)
                    case .sleepControl:
                        store.handle(.dismissSheet)
                    case nil:
                        break
                    }
                } else {
                    store.routeState.activeSheet = newValue
                }
            }
        )
    }

    private var activeDeleteSummaryBinding: Binding<RecordDeleteSummary?> {
        Binding(
            get: { store.activeDeleteSummary },
            set: { newValue in
                if newValue == nil {
                    store.handle(.cancelDeleteRecord)
                }
            }
        )
    }

    private var activeUndoToast: UndoToastState? {
        switch selectedTab {
        case .record:
            store.viewState.undoToast
        case .growth:
            growthStore.viewState.undoToast
        case .collection:
            treasureStore.viewState.undoToast
        }
    }

    private var activeMessageToast: MessageToastState? {
        switch selectedTab {
        case .record:
            store.viewState.messageToast
        case .growth:
            growthStore.viewState.messageToast
        case .collection:
            treasureStore.viewState.messageToast
        }
    }

    private func performUndo() {
        switch selectedTab {
        case .record:
            store.handle(store.activeUndoAction)
        case .growth:
            growthStore.handle(.undoLastRecord)
        case .collection:
            treasureStore.handle(.undoLastEntry)
        }
    }

    private func dismissUndo() {
        switch selectedTab {
        case .record:
            store.handle(.dismissUndo)
        case .growth:
            growthStore.handle(.dismissUndo)
        case .collection:
            treasureStore.handle(.dismissUndo)
        }
    }

    private func dismissMessage() {
        switch selectedTab {
        case .record:
            store.handle(.dismissMessage)
        case .growth:
            growthStore.handle(.dismissMessage)
        case .collection:
            treasureStore.handle(.dismissMessage)
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: ActiveSheet) -> some View {
        switch sheet {
        case let .recordEditor(route):
            recordEditorSheet(for: route)
        case .sleepControl:
            SleepControlSheet(store: store)
                .presentationDetents([.height(360)])
                .presentationDragIndicator(.visible)
                .presentationBackground(AppTheme.Colors.background)
        }
    }

    @ViewBuilder
    private func recordEditorSheet(for route: RecordEditorRouteState) -> some View {
        switch route.editorType {
        case .milk:
            MilkLoggingSheet(store: store)
                .presentationDetents(route.mode.recordID == nil ? [.height(452), .large] : [.height(580), .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(AppTheme.Colors.background)
        case .diaper:
            DiaperRecordSheet(store: store)
                .presentationDetents([.height(route.mode.recordID == nil ? 392 : 472)])
                .presentationDragIndicator(.visible)
                .presentationBackground(AppTheme.Colors.background)
        case .food:
            FoodRecordSheet(store: store)
                .presentationDetents([.fraction(0.72), .large])
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled(store.shouldDisableFoodInteractiveDismiss)
                .presentationBackground(AppTheme.Colors.background)
        case .sleep:
            SleepRecordEditorSheet(store: store)
                .presentationDetents([.height(460), .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(AppTheme.Colors.background)
        }
    }
}

struct GrowthView: View {
    @Bindable var store: GrowthStore

    var body: some View {
        GrowthModuleContainer(store: store)
    }
}

struct CollectionView: View {
    @Bindable var store: TreasureStore

    var body: some View {
        TreasureModuleContainer(store: store)
    }
}
