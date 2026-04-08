import Observation
import SwiftUI

struct SleepRecordEditorSheet: View {
    @Bindable var store: HomeStore

    private let formatter = TimelineContentFormatter()

    var body: some View {
        BaseRecordSheet(title: store.sleepSheetTitle, onClose: { store.handle(.dismissRecordEditor) }) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    RecordEditorDateField(
                        title: L10n.text("home.sheet.sleep.edit.start", en: "Start time", zh: "开始时间"),
                        date: Binding(
                            get: { store.sleepEditDraft.startTime },
                            set: { store.updateSleepEditStartTime($0) }
                        )
                    )

                    RecordEditorDateField(
                        title: L10n.text("home.sheet.sleep.edit.end", en: "End time", zh: "结束时间"),
                        date: Binding(
                            get: { store.sleepEditDraft.endTime },
                            set: { store.updateSleepEditEndTime($0) }
                        ),
                        supportingText: store.sleepEditValidationMessage,
                        supportingColor: AppTheme.Colors.highlight.opacity(0.9)
                    )

                    SleepDurationSummaryCard(
                        value: durationText,
                        isValid: store.sleepEditDraft.isValid
                    )
                }
                .padding(.bottom, 12)
            }
        } footer: {
            SheetPrimaryButton(
                title: store.sleepPrimaryActionTitle,
                isEnabled: store.isSleepEditSaveEnabled
            ) {
                store.handle(.saveRecordEdits)
            }
        }
    }

    private var durationText: String {
        guard store.sleepEditDraft.isValid else {
            return L10n.text("home.sheet.sleep.edit.duration.pending", en: "Adjust the time", zh: "请调整时间")
        }

        return formatter.formatSleepDuration(durationInSeconds: store.sleepEditDraft.duration)
    }
}

private struct SleepDurationSummaryCard: View {
    let value: String
    let isValid: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.text("home.sheet.sleep.edit.duration", en: "Duration", zh: "时长"))
                .font(AppTheme.Typography.meta)
                .foregroundStyle(AppTheme.Colors.secondaryText)

            Text(value)
                .font(AppTheme.Typography.cardTitle)
                .foregroundStyle(isValid ? AppTheme.Colors.primaryText : AppTheme.Colors.secondaryText)
                .monospacedDigit()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
    }
}
