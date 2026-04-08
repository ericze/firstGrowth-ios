import Observation
import SwiftUI

struct NursingTimerTab: View {
    @Bindable var store: HomeStore

    private var isEditing: Bool {
        guard let route = store.activeRecordEditorRoute else { return false }
        return route.editorType == .milk && route.mode.recordID != nil
    }

    var body: some View {
        Group {
            if isEditing {
                editBody
            } else {
                createBody
            }
        }
    }

    private var createBody: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(spacing: 16) {
                HStack(spacing: 14) {
                    NursingTimerBlock(
                        side: .left,
                        displayedSeconds: store.milkDraft.displayedSeconds(for: .left, now: context.date),
                        isActive: store.milkDraft.activeSide == .left
                    ) {
                        store.handle(.tapNursingSide(.left))
                    }

                    NursingTimerBlock(
                        side: .right,
                        displayedSeconds: store.milkDraft.displayedSeconds(for: .right, now: context.date),
                        isActive: store.milkDraft.activeSide == .right
                    ) {
                        store.handle(.tapNursingSide(.right))
                    }
                }

                Text(String(localized: "home.sheet.nursing.instruction"))
                    .font(AppTheme.Typography.meta)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, minHeight: MilkSheetLayout.contentMinHeight, alignment: .top)
        }
    }

    private var editBody: some View {
        HStack(spacing: 14) {
            EditableNursingDurationBlock(
                side: .left,
                displayedSeconds: store.milkDraft.leftAccumulatedSeconds,
                onDecrease: {
                    store.milkDraft.adjustNursingDuration(
                        for: .left,
                        deltaSeconds: -FeedingDraftState.nursingAdjustmentStep
                    )
                },
                onIncrease: {
                    store.milkDraft.adjustNursingDuration(
                        for: .left,
                        deltaSeconds: FeedingDraftState.nursingAdjustmentStep
                    )
                }
            )

            EditableNursingDurationBlock(
                side: .right,
                displayedSeconds: store.milkDraft.rightAccumulatedSeconds,
                onDecrease: {
                    store.milkDraft.adjustNursingDuration(
                        for: .right,
                        deltaSeconds: -FeedingDraftState.nursingAdjustmentStep
                    )
                },
                onIncrease: {
                    store.milkDraft.adjustNursingDuration(
                        for: .right,
                        deltaSeconds: FeedingDraftState.nursingAdjustmentStep
                    )
                }
            )
        }
        .frame(maxWidth: .infinity, minHeight: MilkSheetLayout.contentMinHeight, alignment: .top)
    }
}

private struct NursingTimerBlock: View {
    let side: NursingSide
    let displayedSeconds: Int
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 8) {
                    Text(side.title)
                        .font(.system(size: 20, weight: .semibold))

                    Text(side.badge)
                        .font(.system(size: 15, weight: .medium))
                        .opacity(0.7)
                }

                Spacer(minLength: 0)

                Text(formattedDuration)
                    .font(.system(size: 36, weight: .semibold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isActive ? Color.white : AppTheme.Colors.primaryText)
            .padding(22)
            .frame(
                maxWidth: .infinity,
                minHeight: MilkSheetLayout.nursingCardHeight,
                alignment: .topLeading
            )
            .background(isActive ? AppTheme.Colors.sageGreen : AppTheme.Colors.cardBackground)
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
                    .stroke(AppTheme.Colors.divider, lineWidth: isActive ? 0 : 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var formattedDuration: String {
        let minutes = max(displayedSeconds, 0) / 60
        let seconds = max(displayedSeconds, 0) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

private struct EditableNursingDurationBlock: View {
    let side: NursingSide
    let displayedSeconds: Int
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 8) {
                Text(side.title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.primaryText)

                Text(side.badge)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }

            Spacer(minLength: 0)

            Text(formattedDuration)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.primaryText)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            HStack(spacing: 12) {
                adjustmentButton(systemName: "minus", action: onDecrease)
                adjustmentButton(systemName: "plus", action: onIncrease)
            }
        }
        .padding(22)
        .frame(
            maxWidth: .infinity,
            minHeight: MilkSheetLayout.nursingCardHeight,
            alignment: .topLeading
        )
        .background(AppTheme.Colors.cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
                .stroke(AppTheme.Colors.divider, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
    }

    private func adjustmentButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppTheme.Colors.primaryText)
                .frame(width: 40, height: 40)
                .background(AppTheme.Colors.background)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private var formattedDuration: String {
        let minutes = max(displayedSeconds, 0) / 60
        let seconds = max(displayedSeconds, 0) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
