import SwiftUI

struct SleepActionButton: View {
    let isActive: Bool
    let onTapInactive: () -> Void
    let onTapActive: () -> Void
    let onLongPressEnd: () -> Void

    @State private var showHint = false
    @State private var ignoreNextTap = false
    @State private var shakeOffset: CGFloat = 0
    @State private var hintDismissTask: Task<Void, Never>?

    var body: some View {
        Button(action: handleTap) {
            VStack(spacing: 4) {
                Image(systemName: isActive ? "moon.zzz.fill" : "moon.zzz")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(isActive ? AppTheme.Colors.accent : AppTheme.Colors.primaryText)

                Text(isActive ? "睡眠中" : "睡眠")
                    .font(AppTheme.Typography.floatingLabel)
                    .foregroundStyle(isActive ? AppTheme.Colors.accent : AppTheme.Colors.primaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .offset(x: shakeOffset)
            .overlay(alignment: .top) {
                if showHint {
                    SleepHintBubble(text: "长按结束")
                        .offset(y: -34)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
        }
        .buttonStyle(FloatingActionPressStyle())
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 1.0)
                .onEnded { _ in
                    guard isActive else { return }
                    ignoreNextTap = true
                    hideHintImmediately()
                    onLongPressEnd()
                }
        )
        .accessibilityLabel(isActive ? "睡眠中，长按结束" : "开始睡眠记录")
        .accessibilityValue(isActive ? "进行中" : "未开始")
        .onDisappear {
            hintDismissTask?.cancel()
        }
    }

    private func handleTap() {
        if ignoreNextTap {
            ignoreNextTap = false
            return
        }

        if isActive {
            onTapActive()
            triggerHint()
        } else {
            onTapInactive()
        }
    }

    private func triggerHint() {
        hintDismissTask?.cancel()
        withAnimation(.easeOut(duration: 0.15)) {
            showHint = true
        }

        withAnimation(.easeOut(duration: 0.08).repeatCount(2, autoreverses: true)) {
            shakeOffset = 3
        }

        hintDismissTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            shakeOffset = 0
            try? await Task.sleep(for: .milliseconds(1_020))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.16)) {
                showHint = false
            }
        }
    }

    private func hideHintImmediately() {
        hintDismissTask?.cancel()
        shakeOffset = 0
        withAnimation(.easeInOut(duration: 0.12)) {
            showHint = false
        }
    }
}

private struct SleepHintBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppTheme.Typography.floatingHint)
            .foregroundStyle(AppTheme.Colors.primaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(AppTheme.Colors.floatingHintBackground)
                    .background(.ultraThinMaterial, in: Capsule())
            )
            .shadow(
                color: AppTheme.Shadow.floatingBarColor,
                radius: AppTheme.Shadow.hintRadius,
                y: AppTheme.Shadow.hintY
            )
    }
}
