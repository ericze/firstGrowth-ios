import SwiftUI

struct TreasureMonthScrubber: View {
    let anchors: [TreasureMonthAnchor]
    let state: TreasureMonthScrubberState
    let activeAnchor: TreasureMonthAnchor?
    let onBegin: (CGFloat, CGFloat) -> Void
    let onUpdate: (CGFloat, CGFloat) -> Void
    let onEnd: () -> Void

    @State private var didBeginDrag = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            if state == .onboardingNudge {
                Text(L10n.text("treasure.scrubber.hint", en: "Drag here to browse time", zh: "拖动这里穿梭时间"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(TreasureTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(TreasureTheme.paperWhite.opacity(0.96))
                    .clipShape(Capsule())
            }

            GeometryReader { geometry in
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(TreasureTheme.paperWhite.opacity(0.92))
                        .frame(width: 48)

                    VStack(spacing: 8) {
                        ForEach(Array(anchors.enumerated()), id: \.element.id) { index, anchor in
                            Circle()
                                .fill(anchor.id == activeAnchor?.id ? TreasureTheme.sageDeep : TreasureTheme.textSecondary.opacity(0.18))
                                .frame(width: anchor.id == activeAnchor?.id ? 6 : 4, height: anchor.id == activeAnchor?.id ? 6 : 4)
                                .animation(AppTheme.stateAnimation, value: activeAnchor?.id)

                            if index != anchors.indices.last {
                                Capsule()
                                    .fill(TreasureTheme.textSecondary.opacity(0.14))
                                    .frame(width: 1, height: 12)
                            }
                        }
                    }

                    if let activeAnchor {
                        Text(activeAnchor.displayText)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(TreasureTheme.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(TreasureTheme.paperWhite.opacity(0.96))
                            .clipShape(Capsule())
                            .offset(x: -60)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !didBeginDrag {
                                didBeginDrag = true
                                onBegin(geometry.size.height, value.location.y)
                            } else {
                                onUpdate(geometry.size.height, value.location.y)
                            }
                        }
                        .onEnded { _ in
                            didBeginDrag = false
                            onEnd()
                        }
                )
            }
            .frame(width: 118, height: 176)
        }
        .accessibilityLabel(L10n.text("treasure.scrubber.accessibility", en: "Browse time", zh: "穿梭时间"))
        .opacity(state == .fading ? 0 : 1)
        .rootPagerGestureExclusion()
    }
}
