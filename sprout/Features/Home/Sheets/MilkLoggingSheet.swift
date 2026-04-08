import Observation
import SwiftUI

enum MilkSheetLayout {
    static let nursingCardHeight: CGFloat = 208
    static let contentMinHeight: CGFloat = 276
}

struct MilkLoggingSheet: View {
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
        BaseRecordSheet {
            MilkSheetHeader(
                selectedTab: store.milkDraft.selectedTab,
                onSelect: { tab in store.handle(.selectMilkTab(tab)) },
                onClose: { store.handle(.dismissSheet) }
            )
        } content: {
            milkContent
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

    private var editBody: some View {
        BaseRecordSheet(title: editSheetTitle, onClose: { store.handle(.dismissSheet) }) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    RecordTimestampField(
                        title: timeFieldTitle,
                        date: Binding(
                            get: { store.milkDraft.recordedAt },
                            set: { store.milkDraft.setRecordedAt($0) }
                        )
                    )

                    MilkTabSwitcher(
                        selectedTab: store.milkDraft.selectedTab,
                        onSelect: { tab in store.handle(.selectMilkTab(tab)) }
                    )

                    milkContent
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)
            }
        } footer: {
            SheetPrimaryButton(
                title: saveButtonTitle,
                isEnabled: store.milkDraft.canSubmit(now: store.milkDraft.recordedAt)
            ) {
                store.handle(.saveRecordEdits)
            }
        }
    }

    @ViewBuilder
    private var milkContent: some View {
        switch store.milkDraft.selectedTab {
        case .nursing:
            NursingTimerTab(store: store)
        case .bottle:
            BottleLoggingTab(store: store)
        }
    }

    private var editSheetTitle: String {
        L10n.text(
            "home.record.editor.title",
            en: "Edit record",
            zh: "编辑记录"
        )
    }

    private var saveButtonTitle: String {
        L10n.text(
            "home.record.editor.save",
            en: "Save changes",
            zh: "保存修改"
        )
    }

    private var timeFieldTitle: String {
        L10n.text(
            "home.record.editor.time",
            en: "Time",
            zh: "时间"
        )
    }
}

private struct MilkSheetHeader: View {
    let selectedTab: MilkTab
    let onSelect: (MilkTab) -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            MilkTabSwitcher(selectedTab: selectedTab, onSelect: onSelect)
            SheetCloseButton(action: onClose)
        }
        .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
        .padding(.top, 2)
    }
}
