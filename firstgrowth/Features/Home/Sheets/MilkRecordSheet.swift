import Observation
import SwiftUI

struct MilkRecordSheet: View {
    @Bindable var store: HomeStore

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        BaseRecordSheet(title: "记奶量", onClose: { store.handle(.dismissSheet) }) {
            VStack(spacing: 22) {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(MilkDraftState.presets, id: \.self) { preset in
                        Button {
                            store.handle(.saveMilkPreset(preset))
                        } label: {
                            Text("\(preset)ml")
                                .font(AppTheme.Typography.cardTitle)
                                .foregroundStyle(AppTheme.Colors.primaryText)
                                .frame(maxWidth: .infinity)
                                .frame(height: 58)
                                .background(AppTheme.Colors.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(spacing: 18) {
                    Text("需要非标准奶量时再微调")
                        .font(AppTheme.Typography.meta)
                        .foregroundStyle(AppTheme.Colors.secondaryText)

                    HStack(spacing: 28) {
                        stepperButton(systemName: "minus", step: -10)

                        Text("\(store.milkDraft.customValue)ml")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.primaryText)
                            .frame(minWidth: 108)
                            .monospacedDigit()

                        stepperButton(systemName: "plus", step: 10)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(AppTheme.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
            }
        } footer: {
            if store.milkDraft.isUsingCustomValue {
                SheetPrimaryButton(title: "完成记录", isEnabled: true) {
                    store.handle(.saveCustomMilk)
                }
            }
        }
    }

    private func stepperButton(systemName: String, step: Int) -> some View {
        Button {
            store.handle(.adjustMilkCustom(step))
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(AppTheme.Colors.primaryText)
                .frame(width: 46, height: 46)
                .background(AppTheme.Colors.background)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
