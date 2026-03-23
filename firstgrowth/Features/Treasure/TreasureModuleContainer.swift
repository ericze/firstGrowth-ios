import Observation
import SwiftUI

struct TreasureModuleContainer: View {
    @Bindable var store: TreasureStore

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ZStack(alignment: .topTrailing) {
                    VStack(spacing: 0) {
                        TreasureHeaderBar(action: { store.handle(.tapAddToday) })
                            .padding(.horizontal, TreasureTheme.listHorizontalPadding)
                            .padding(.top, 4)
                            .padding(.bottom, 8)

                        ScrollView(showsIndicators: false) {
                            TreasureScrollOffsetReader()

                            TreasureTimelineList(
                                dataState: store.viewState.dataState,
                                items: store.viewState.timelineItems,
                                errorMessage: store.viewState.errorMessage,
                                onTapWeeklyLetter: { store.handle(.tapWeeklyLetter($0)) }
                            )
                            .padding(.horizontal, TreasureTheme.listHorizontalPadding)
                            .padding(.top, TreasureTheme.listTopPadding)
                            .padding(.bottom, TreasureTheme.listBottomPadding)
                        }
                        .coordinateSpace(name: TreasureScrollOffsetReader.coordinateSpaceName)
                    }
                    .background(TreasureTheme.pageBackground)

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
                        .padding(.trailing, 6)
                        .padding(.top, geometry.size.height * 0.26)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .background(TreasureTheme.pageBackground.ignoresSafeArea())
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
                        .presentationBackground(TreasureTheme.pageBackground)
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
