import Observation
import SwiftUI

struct MilkLoggingSheet: View {
    @Bindable var store: HomeStore

    var body: some View {
        BaseRecordSheet {
            HStack(spacing: 16) {
                MilkTabSwitcher(selectedTab: store.milkDraft.selectedTab) { tab in
                    store.handle(.selectMilkTab(tab))
                }

                SheetCloseButton {
                    store.handle(.dismissSheet)
                }
            }
        } content: {
            switch store.milkDraft.selectedTab {
            case .nursing:
                NursingTimerTab(store: store)
            case .bottle:
                BottleLoggingTab(store: store)
            }
        } footer: {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let isEnabled = store.milkDraft.canSubmit(now: context.date)

                Button {
                    store.handle(.saveFeedingRecord)
                } label: {
                    Text(store.feedingSubmitButtonTitle(now: context.date))
                        .font(AppTheme.Typography.primaryButton)
                        .foregroundStyle(isEnabled ? Color.white : AppTheme.Colors.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            isEnabled
                                ? AppTheme.Colors.primaryText
                                : AppTheme.Colors.primaryText.opacity(0.14)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!isEnabled)
            }
        }
    }
}
