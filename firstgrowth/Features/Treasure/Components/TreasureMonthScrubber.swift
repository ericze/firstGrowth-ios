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
                Text("拖动这里穿梭时间")
                    .font(AppTheme.Typography.floatingHint)
                    .foregroundStyle(AppTheme.Colors.primaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(AppTheme.Colors.floatingHintBackground)
                    .clipShape(Capsule())
                    .shadow(color: AppTheme.Shadow.color, radius: AppTheme.Shadow.hintRadius, y: AppTheme.Shadow.hintY)
            }

            GeometryReader { geometry in
                ZStack {
                    Capsule()
                        .fill(AppTheme.Colors.cardBackground.opacity(0.92))
                        .frame(width: 62)
                        .shadow(color: AppTheme.Shadow.color, radius: AppTheme.Shadow.radius, y: AppTheme.Shadow.y)

                    VStack(spacing: 10) {
                        ForEach(Array(anchors.enumerated()), id: \.element.id) { index, anchor in
                            Circle()
                                .fill(anchor.id == activeAnchor?.id ? AppTheme.Colors.accent : AppTheme.Colors.divider)
                                .frame(width: anchor.id == activeAnchor?.id ? 7 : 5, height: anchor.id == activeAnchor?.id ? 7 : 5)
                                .animation(AppTheme.stateAnimation, value: activeAnchor?.id)

                            if index != anchors.indices.last {
                                Capsule()
                                    .fill(AppTheme.Colors.divider)
                                    .frame(width: 1, height: 12)
                            }
                        }
                    }

                    if let activeAnchor {
                        Text(activeAnchor.displayText)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.primaryText)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(AppTheme.Colors.background.opacity(0.96))
                            .clipShape(Capsule())
                            .offset(x: -68)
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
            .frame(width: 140, height: 180)
        }
        .accessibilityLabel("穿梭时间")
        .opacity(state == .fading ? 0 : 1)
    }
}
