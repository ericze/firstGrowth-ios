import CoreGraphics

struct RootPagerGesturePolicy {
    static let minimumSwipeThreshold: CGFloat = 56

    func canTrackPagerDrag(
        currentTab: HomeModule,
        startLocation: CGPoint,
        translation: CGSize,
        exclusionRects: [CGRect],
        defersRecordSidebarReveal: Bool,
        isSidebarInteractionInProgress: Bool
    ) -> Bool {
        guard isPredominantlyHorizontal(translation) else { return false }

        if isSidebarInteractionInProgress, currentTab == .record {
            return false
        }

        if defersRecordSidebarReveal, currentTab == .record, translation.width > 0 {
            return false
        }

        return exclusionRects.contains(where: { $0.contains(startLocation) }) == false
    }

    func dragOffset(
        currentTab: HomeModule,
        translationWidth: CGFloat,
        pageWidth: CGFloat
    ) -> CGFloat {
        let limitedWidth = min(max(translationWidth, -pageWidth), pageWidth)

        switch currentTab {
        case .record:
            return min(limitedWidth, 0)
        case .growth:
            return limitedWidth
        case .collection:
            return max(limitedWidth, 0)
        }
    }

    func targetTab(
        currentTab: HomeModule,
        startLocation: CGPoint,
        translation: CGSize,
        predictedEndTranslation: CGSize,
        pageWidth: CGFloat,
        exclusionRects: [CGRect],
        defersRecordSidebarReveal: Bool,
        isSidebarInteractionInProgress: Bool
    ) -> HomeModule {
        guard canTrackPagerDrag(
            currentTab: currentTab,
            startLocation: startLocation,
            translation: translation,
            exclusionRects: exclusionRects,
            defersRecordSidebarReveal: defersRecordSidebarReveal,
            isSidebarInteractionInProgress: isSidebarInteractionInProgress
        ) else {
            return currentTab
        }

        let threshold = max(Self.minimumSwipeThreshold, pageWidth * 0.16)
        let effectiveWidth = projectedTranslationWidth(
            translation: translation.width,
            predictedEndTranslation: predictedEndTranslation.width
        )

        guard abs(effectiveWidth) > threshold else {
            return currentTab
        }

        let direction: PagerDirection = effectiveWidth < 0 ? .forward : .backward
        return adjacentTab(from: currentTab, direction: direction) ?? currentTab
    }

    func projectedTranslationWidth(
        translation: CGFloat,
        predictedEndTranslation: CGFloat
    ) -> CGFloat {
        abs(predictedEndTranslation) > abs(translation) ? predictedEndTranslation : translation
    }

    func isPredominantlyHorizontal(_ translation: CGSize) -> Bool {
        abs(translation.width) > abs(translation.height)
    }

    private func adjacentTab(from currentTab: HomeModule, direction: PagerDirection) -> HomeModule? {
        let currentIndex = currentTab.pagerIndex

        switch direction {
        case .backward:
            guard currentIndex > 0 else { return nil }
            return HomeModule.allCases[currentIndex - 1]
        case .forward:
            guard currentIndex < HomeModule.allCases.count - 1 else { return nil }
            return HomeModule.allCases[currentIndex + 1]
        }
    }
}

private enum PagerDirection {
    case backward
    case forward
}

extension HomeModule {
    var pagerIndex: Int {
        HomeModule.allCases.firstIndex(of: self) ?? 0
    }
}
