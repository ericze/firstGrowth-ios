import SwiftUI

private enum RootPagerCoordinateSpace {
    static let name = "RootPagerCoordinateSpace"
}

struct HorizontalGestureExclusionPreferenceKey: PreferenceKey {
    static var defaultValue: [CGRect] = []

    static func reduce(value: inout [CGRect], nextValue: () -> [CGRect]) {
        value.append(contentsOf: nextValue())
    }
}

extension View {
    func rootPagerGestureExclusion() -> some View {
        background {
            GeometryReader { proxy in
                Color.clear
                    .preference(
                        key: HorizontalGestureExclusionPreferenceKey.self,
                        value: [proxy.frame(in: .named(RootPagerCoordinateSpace.name))]
                    )
            }
        }
    }
}

struct RootPagerView<RecordPage: View, GrowthPage: View, CollectionPage: View>: View {
    @Binding var selectedTab: HomeModule
    let defersRecordSidebarReveal: Bool
    let isSidebarInteractionInProgress: Bool
    let recordPage: RecordPage
    let growthPage: GrowthPage
    let collectionPage: CollectionPage

    @State private var exclusionRects: [CGRect] = []
    @State private var dragOffset: CGFloat = 0

    private let gesturePolicy = RootPagerGesturePolicy()

    init(
        selectedTab: Binding<HomeModule>,
        defersRecordSidebarReveal: Bool,
        isSidebarInteractionInProgress: Bool,
        @ViewBuilder recordPage: () -> RecordPage,
        @ViewBuilder growthPage: () -> GrowthPage,
        @ViewBuilder collectionPage: () -> CollectionPage
    ) {
        _selectedTab = selectedTab
        self.defersRecordSidebarReveal = defersRecordSidebarReveal
        self.isSidebarInteractionInProgress = isSidebarInteractionInProgress
        self.recordPage = recordPage()
        self.growthPage = growthPage()
        self.collectionPage = collectionPage()
    }

    var body: some View {
        GeometryReader { proxy in
            let pageWidth = proxy.size.width

            HStack(spacing: 0) {
                recordPage
                    .frame(width: pageWidth)

                growthPage
                    .frame(width: pageWidth)

                collectionPage
                    .frame(width: pageWidth)
            }
            .frame(width: pageWidth * CGFloat(HomeModule.allCases.count), alignment: .leading)
            .offset(x: contentOffset(pageWidth: pageWidth))
            .contentShape(Rectangle())
            .simultaneousGesture(pagerGesture(pageWidth: pageWidth))
        }
        .coordinateSpace(name: RootPagerCoordinateSpace.name)
        .clipped()
        .onPreferenceChange(HorizontalGestureExclusionPreferenceKey.self) { exclusionRects = $0 }
    }

    private func contentOffset(pageWidth: CGFloat) -> CGFloat {
        -CGFloat(selectedTab.pagerIndex) * pageWidth + dragOffset
    }

    private func pagerGesture(pageWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 12, coordinateSpace: .named(RootPagerCoordinateSpace.name))
            .onChanged { value in
                guard gesturePolicy.canTrackPagerDrag(
                    currentTab: selectedTab,
                    startLocation: value.startLocation,
                    translation: value.translation,
                    exclusionRects: exclusionRects,
                    defersRecordSidebarReveal: defersRecordSidebarReveal,
                    isSidebarInteractionInProgress: isSidebarInteractionInProgress
                ) else {
                    dragOffset = 0
                    return
                }

                dragOffset = gesturePolicy.dragOffset(
                    currentTab: selectedTab,
                    translationWidth: value.translation.width,
                    pageWidth: pageWidth
                )
            }
            .onEnded { value in
                let nextTab = gesturePolicy.targetTab(
                    currentTab: selectedTab,
                    startLocation: value.startLocation,
                    translation: value.translation,
                    predictedEndTranslation: value.predictedEndTranslation,
                    pageWidth: pageWidth,
                    exclusionRects: exclusionRects,
                    defersRecordSidebarReveal: defersRecordSidebarReveal,
                    isSidebarInteractionInProgress: isSidebarInteractionInProgress
                )
                let didChangeTab = nextTab != selectedTab

                withAnimation(AppTheme.stateAnimation) {
                    dragOffset = 0
                    selectedTab = nextTab
                }

                if didChangeTab {
                    AppHaptics.selection()
                }
            }
    }
}
