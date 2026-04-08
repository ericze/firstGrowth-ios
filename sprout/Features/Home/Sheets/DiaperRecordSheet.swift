import Observation
import SwiftUI

struct DiaperRecordSheet: View {
    @Bindable var store: HomeStore

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    private var isEditing: Bool {
        guard let route = store.activeRecordEditorRoute else { return false }
        return route.editorType == .diaper && route.mode.recordID != nil
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
        BaseRecordSheet(title: String(localized: "home.sheet.diaper.title"), onClose: { store.handle(.dismissSheet) }) {
            diaperGrid
        }
    }

    private var editBody: some View {
        BaseRecordSheet(title: editSheetTitle, onClose: { store.handle(.dismissSheet) }) {
            VStack(alignment: .leading, spacing: 18) {
                RecordTimestampField(
                    title: timeFieldTitle,
                    date: Binding(
                        get: { store.diaperDraft.recordedAt },
                        set: { store.diaperDraft.setRecordedAt($0) }
                    )
                )

                diaperGrid
            }
        } footer: {
            SheetPrimaryButton(title: saveButtonTitle, isEnabled: store.diaperDraft.canSubmit) {
                store.handle(.saveRecordEdits)
            }
        }
    }

    private var diaperGrid: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            diaperButton(
                title: String(localized: "home.sheet.diaper.pee.title"),
                subtitle: String(localized: "home.sheet.diaper.pee.subtitle"),
                subtype: .pee
            )
            diaperButton(
                title: String(localized: "home.sheet.diaper.poop.title"),
                subtitle: String(localized: "home.sheet.diaper.poop.subtitle"),
                subtype: .poop
            )
            diaperButton(
                title: String(localized: "home.sheet.diaper.both.title"),
                subtitle: String(localized: "home.sheet.diaper.both.subtitle"),
                subtype: .both
            )
        }
    }

    private func diaperButton(title: String, subtitle: String, subtype: DiaperSubtype) -> some View {
        let isSelected = isEditing && store.diaperDraft.selectedSubtype == subtype

        return Button {
            if isEditing {
                store.diaperDraft.selectSubtype(subtype)
            } else {
                store.handle(.saveDiaper(subtype))
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundStyle(isSelected ? Color.white : AppTheme.Colors.primaryText)

                Text(subtitle)
                    .font(AppTheme.Typography.meta)
                    .foregroundStyle(isSelected ? Color.white.opacity(0.76) : AppTheme.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
            .padding(18)
            .background(isSelected ? AppTheme.Colors.sageGreen : AppTheme.Colors.cardBackground)
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
                    .stroke(AppTheme.Colors.divider, lineWidth: isSelected ? 0 : 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
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
