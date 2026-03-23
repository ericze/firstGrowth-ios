import CoreGraphics
import Foundation

struct GrowthChartInteractionController {
    typealias DelayRunner = @Sendable (UInt64) async -> Void

    private let fadeDelayNanoseconds: UInt64
    private let delayRunner: DelayRunner

    nonisolated init(
        fadeDelayNanoseconds: UInt64 = 400_000_000,
        delayRunner: @escaping DelayRunner = { nanoseconds in
            try? await Task.sleep(nanoseconds: nanoseconds)
        }
    ) {
        self.fadeDelayNanoseconds = fadeDelayNanoseconds
        self.delayRunner = delayRunner
    }

    nonisolated func nearestIndex(locationX: CGFloat, chartWidth: CGFloat, itemCount: Int) -> Int? {
        guard itemCount > 0, chartWidth > 0 else { return nil }
        guard itemCount > 1 else { return 0 }

        let clampedX = min(max(locationX, 0), chartWidth)
        let ratio = clampedX / chartWidth
        let rawIndex = ratio * CGFloat(itemCount - 1)
        return min(max(Int(rawIndex.rounded()), 0), itemCount - 1)
    }

    @discardableResult
    func scheduleFade(
        onTransition: @escaping @MainActor () -> Void,
        onCompletion: @escaping @MainActor () -> Void
    ) -> Task<Void, Never> {
        onTransition()

        return Task { [fadeDelayNanoseconds, delayRunner] in
            await delayRunner(fadeDelayNanoseconds)
            guard !Task.isCancelled else { return }
            await onCompletion()
        }
    }
}
