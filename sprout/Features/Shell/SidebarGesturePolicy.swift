import CoreGraphics

struct SidebarGesturePolicy {
    static let revealThreshold: CGFloat = 56
    static let dismissThreshold: CGFloat = 50
    static let revealSettleProgress: CGFloat = 0.32
    static let dismissSettleProgress: CGFloat = 0.78

    enum SettleState: Equatable {
        case open
        case closed
    }

    func canReveal(
        isRecordTab: Bool,
        isRootVisible: Bool,
        isSidebarPresented: Bool,
        isInteractionBlocked: Bool
    ) -> Bool {
        isRecordTab && isRootVisible && !isSidebarPresented && !isInteractionBlocked
    }

    func shouldReveal(startLocationX _: CGFloat, translation: CGSize, isEligible: Bool) -> Bool {
        guard isEligible else { return false }
        guard isPredominantlyHorizontal(translation) else { return false }
        return translation.width > Self.revealThreshold
    }

    func shouldDismiss(isSidebarPresented: Bool, translation: CGSize) -> Bool {
        guard isSidebarPresented else { return false }
        guard isPredominantlyHorizontal(translation) else { return false }
        return translation.width < -Self.dismissThreshold
    }

    func revealProgress(
        translationWidth: CGFloat,
        drawerWidth: CGFloat,
        isEligible: Bool
    ) -> CGFloat {
        guard isEligible else { return 0 }
        let visibleWidth = clampedVisibleWidth(translationWidth, drawerWidth: drawerWidth)
        return progress(forVisibleWidth: visibleWidth, drawerWidth: drawerWidth)
    }

    func dismissProgress(
        translationWidth: CGFloat,
        drawerWidth: CGFloat,
        isSidebarPresented: Bool
    ) -> CGFloat {
        guard isSidebarPresented else { return 0 }
        let visibleWidth = clampedVisibleWidth(drawerWidth + min(translationWidth, 0), drawerWidth: drawerWidth)
        return progress(forVisibleWidth: visibleWidth, drawerWidth: drawerWidth)
    }

    func revealSettleState(
        translation: CGSize,
        predictedEndTranslation: CGSize,
        drawerWidth: CGFloat,
        isEligible: Bool
    ) -> SettleState {
        guard isEligible else { return .closed }
        guard isPredominantlyHorizontal(translation) else { return .closed }

        let effectiveWidth = projectedTranslationWidth(
            translation: translation.width,
            predictedEndTranslation: predictedEndTranslation.width
        )
        let visibleWidth = clampedVisibleWidth(effectiveWidth, drawerWidth: drawerWidth)
        let projectedProgress = progress(forVisibleWidth: visibleWidth, drawerWidth: drawerWidth)

        return projectedProgress >= Self.revealSettleProgress ? .open : .closed
    }

    func dismissSettleState(
        translation: CGSize,
        predictedEndTranslation: CGSize,
        drawerWidth: CGFloat,
        isSidebarPresented: Bool
    ) -> SettleState {
        guard isSidebarPresented else { return .closed }
        guard isPredominantlyHorizontal(translation) else { return .open }

        let effectiveWidth = projectedTranslationWidth(
            translation: translation.width,
            predictedEndTranslation: predictedEndTranslation.width
        )
        let visibleWidth = clampedVisibleWidth(drawerWidth + min(effectiveWidth, 0), drawerWidth: drawerWidth)
        let projectedProgress = progress(forVisibleWidth: visibleWidth, drawerWidth: drawerWidth)

        return projectedProgress <= Self.dismissSettleProgress ? .closed : .open
    }

    func isPredominantlyHorizontal(_ translation: CGSize) -> Bool {
        abs(translation.width) > abs(translation.height) * 1.15
    }

    func progress(forVisibleWidth visibleWidth: CGFloat, drawerWidth: CGFloat) -> CGFloat {
        guard drawerWidth > 0 else { return 0 }
        return clampedVisibleWidth(visibleWidth, drawerWidth: drawerWidth) / drawerWidth
    }

    private func projectedTranslationWidth(
        translation: CGFloat,
        predictedEndTranslation: CGFloat
    ) -> CGFloat {
        abs(predictedEndTranslation) > abs(translation) ? predictedEndTranslation : translation
    }

    private func clampedVisibleWidth(_ visibleWidth: CGFloat, drawerWidth: CGFloat) -> CGFloat {
        min(max(visibleWidth, 0), drawerWidth)
    }
}
