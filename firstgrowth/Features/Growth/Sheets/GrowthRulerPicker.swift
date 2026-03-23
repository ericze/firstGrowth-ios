import SwiftUI

struct GrowthRulerPicker: View {
    let config: GrowthRulerConfig
    @Binding var value: Double
    let onTapManualInput: () -> Void

    @State private var dragStartValue: Double?
    @State private var lastSelectionAnchor: Int?
    @State private var lastStrongAnchor: Int?

    private let pointsPerPrecision: CGFloat = 10

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.1f %@", value, config.unit))
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.primaryText)

                    Text("横向滑动，让数值对齐中央准星")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }

                Spacer()

                Button(action: onTapManualInput) {
                    Text("⌨️ 手动输入")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }
                .buttonStyle(.plain)
            }

            GeometryReader { proxy in
                let halfWidth = proxy.size.width / 2
                let visibleTicks = Int(halfWidth / pointsPerPrecision) + 2
                let precision = config.precision

                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(AppTheme.Colors.cardBackground)

                    ForEach(-visibleTicks...visibleTicks, id: \.self) { offset in
                        let tickValue = value + Double(offset) * precision
                        if config.range.contains(tickValue) {
                            let x = halfWidth + CGFloat(offset) * pointsPerPrecision
                            let isStrong = isAligned(tickValue, step: config.strongStep)
                            let isSelection = isAligned(tickValue, step: config.selectionStep)

                            Rectangle()
                                .fill(AppTheme.Colors.primaryText.opacity(isStrong ? 0.78 : isSelection ? 0.46 : 0.18))
                                .frame(width: 1.2, height: isStrong ? 42 : isSelection ? 28 : 18)
                                .position(x: x, y: proxy.size.height / 2)
                        }
                    }

                    Rectangle()
                        .fill(AppTheme.Colors.highlight)
                        .frame(width: 2, height: 64)
                        .overlay(alignment: .top) {
                            Capsule()
                                .fill(AppTheme.Colors.highlight)
                                .frame(width: 14, height: 4)
                                .offset(y: -6)
                        }
                }
                .gesture(rulerGesture())
            }
            .frame(height: 150)
        }
        .onAppear {
            synchronizeHapticAnchors(for: value)
        }
        .onChange(of: value) { _, newValue in
            triggerHapticsIfNeeded(for: newValue)
        }
    }

    private func rulerGesture() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                if dragStartValue == nil {
                    dragStartValue = value
                }

                let originValue = dragStartValue ?? value
                let delta = -gesture.translation.width / pointsPerPrecision * config.precision
                let rawValue = originValue + Double(delta)
                let snapped = (rawValue / config.precision).rounded() * config.precision
                value = min(max(snapped, config.range.lowerBound), config.range.upperBound)
            }
            .onEnded { _ in
                dragStartValue = nil
            }
    }

    private func triggerHapticsIfNeeded(for newValue: Double) {
        let selectionAnchor = Int((newValue / config.selectionStep).rounded())
        let strongAnchor = Int((newValue / config.strongStep).rounded())

        if strongAnchor != lastStrongAnchor, isAligned(newValue, step: config.strongStep) {
            lastStrongAnchor = strongAnchor
            lastSelectionAnchor = selectionAnchor
            AppHaptics.lightImpact()
            return
        }

        if selectionAnchor != lastSelectionAnchor, isAligned(newValue, step: config.selectionStep) {
            lastSelectionAnchor = selectionAnchor
            AppHaptics.selection()
        }
    }

    private func synchronizeHapticAnchors(for value: Double) {
        lastSelectionAnchor = Int((value / config.selectionStep).rounded())
        lastStrongAnchor = Int((value / config.strongStep).rounded())
    }

    private func isAligned(_ value: Double, step: Double) -> Bool {
        guard step > 0 else { return false }
        let remainder = (value / step).rounded() * step - value
        return abs(remainder) < 0.0001
    }
}
