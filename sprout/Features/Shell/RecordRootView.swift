import Observation
import SwiftUI

struct RecordRootView: View {
    @Bindable var store: HomeStore
    let isActiveTab: Bool
    let isSidebarPresented: Bool
    let onRevealSidebarChanged: (CGFloat) -> Void
    let onRevealSidebarEnded: (DragGesture.Value) -> Void

    private let gesturePolicy = SidebarGesturePolicy()

    var body: some View {
        ZStack {
            RecordHomeScrollView(store: store, isActiveTab: isActiveTab)
        }
        .background(AppTheme.Colors.background)
        .contentShape(Rectangle())
        // Sidebar reveal stays scoped to the record root, but the hit area is the full page.
        .simultaneousGesture(revealGesture)
    }

    private var isRevealEligible: Bool {
        gesturePolicy.canReveal(
            isRecordTab: true,
            isRootVisible: isActiveTab,
            isSidebarPresented: isSidebarPresented,
            isInteractionBlocked: !store.canRevealSidebarFromRoot
        )
    }

    private var revealGesture: some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .local)
            .onChanged { value in
                guard isRevealEligible else { return }
                guard gesturePolicy.isPredominantlyHorizontal(value.translation) else { return }

                onRevealSidebarChanged(max(value.translation.width, 0))
            }
            .onEnded { value in
                guard isRevealEligible else {
                    return
                }
                guard gesturePolicy.isPredominantlyHorizontal(value.translation) else { return }

                onRevealSidebarEnded(value)
            }
    }
}
