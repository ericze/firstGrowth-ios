import Observation
import SwiftUI

struct TreasureModuleContainer: View {
    @Bindable var store: TreasureStore
    private let addButtonTopInset: CGFloat = 14
    private let addButtonReservedHeight: CGFloat = 64
    private let addButtonReservedWidth: CGFloat = 122

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ZStack(alignment: .topTrailing) {
                    ScrollView(showsIndicators: false) {
                        TreasureScrollOffsetReader()

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
                            TreasureTopFilterBar(
                                selectedFilter: store.viewState.currentFilter,
                                onSelect: { store.handle(.selectFilter($0)) }
                            )
                            .padding(.top, addButtonReservedHeight)
                            .padding(.trailing, addButtonReservedWidth)

                            TreasureTimelineList(
                                dataState: store.viewState.dataState,
                                filter: store.viewState.currentFilter,
                                items: store.viewState.timelineItems,
                                errorMessage: store.viewState.errorMessage,
                                onTapWeeklyLetter: { store.handle(.tapWeeklyLetter($0)) }
                            )

                            Spacer(minLength: 160)
                        }
                        .padding(.horizontal, AppTheme.Spacing.screenHorizontal)
                        .padding(.bottom, 24)
                    }
                    .coordinateSpace(name: TreasureScrollOffsetReader.coordinateSpaceName)
                    .background(AppTheme.Colors.background)

                    if store.viewState.filterBarVisibility == .pinnedVisible {
                        TreasureTopFilterBar(
                            selectedFilter: store.viewState.currentFilter,
                            onSelect: { store.handle(.selectFilter($0)) }
                        )
                        .padding(.horizontal, AppTheme.Spacing.screenHorizontal)
                        .padding(.top, addButtonReservedHeight)
                        .padding(.trailing, addButtonReservedWidth)
                        .background(
                            AppTheme.Colors.background
                                .opacity(0.96)
                                .ignoresSafeArea(edges: .top)
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    TreasureAddEntryButton(action: { store.handle(.tapAddToday) })
                        .padding(.top, addButtonTopInset)
                        .padding(.trailing, AppTheme.Spacing.screenHorizontal)

                    if store.viewState.monthScrubberState != .hidden {
                        TreasureMonthScrubber(
                            anchors: store.viewState.monthAnchors,
                            state: store.viewState.monthScrubberState,
                            activeAnchor: store.viewState.activeMonthAnchor,
                            onBegin: { height, locationY in
                                store.handle(.beginMonthScrubbing(height: height, locationY: locationY))
                            },
                            onUpdate: { height, locationY in
                                store.handle(.updateMonthScrubbing(height: height, locationY: locationY))
                            },
                            onEnd: { store.handle(.endMonthScrubbing) }
                        )
                        .padding(.trailing, 8)
                        .padding(.top, geometry.size.height * 0.28)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .animation(AppTheme.stateAnimation, value: store.viewState.filterBarVisibility)
                .animation(AppTheme.stateAnimation, value: store.viewState.monthScrubberState)
                .onPreferenceChange(TreasureScrollOffsetPreferenceKey.self) { offset in
                    store.handle(.didScroll(offset: offset, timestamp: Date().timeIntervalSinceReferenceDate))
                }
                .onChange(of: store.viewState.scrollTargetID) { _, targetID in
                    guard let targetID else { return }
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                        proxy.scrollTo(targetID, anchor: .top)
                    }
                    store.consumeScrollTarget()
                }
                .sheet(item: weeklyLetterBinding) { item in
                    TreasureWeeklyLetterSheet(item: item, onClose: { store.handle(.dismissWeeklyLetter) })
                        .presentationDetents(item.letterDensity == .dense ? [.medium, .large] : [.height(420), .medium])
                        .presentationDragIndicator(.visible)
                        .presentationBackground(AppTheme.Colors.background)
                }
                .fullScreenCover(isPresented: composeBinding) {
                    TreasureComposeModal(store: store)
                }
            }
        }
    }

    private var weeklyLetterBinding: Binding<TreasureTimelineItem?> {
        Binding(
            get: { store.viewState.selectedWeeklyLetter },
            set: { newValue in
                if newValue == nil {
                    store.handle(.dismissWeeklyLetter)
                }
            }
        )
    }

    private var composeBinding: Binding<Bool> {
        Binding(
            get: { store.viewState.composeState.isPresented },
            set: { isPresented in
                if !isPresented {
                    store.handle(.dismissCompose)
                }
            }
        )
    }
}
