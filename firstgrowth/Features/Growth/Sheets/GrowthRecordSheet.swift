import Observation
import SwiftUI

struct GrowthRecordSheet: View {
    @Bindable var store: GrowthStore

    var body: some View {
        BaseRecordSheet(
            title: store.viewState.sheetState.metric?.entryTitle ?? store.viewState.currentMetric.entryTitle,
            onClose: { store.handle(.dismissSheet) }
        ) {
            VStack(spacing: 18) {
                if store.viewState.sheetState.isManualInput {
                    GrowthManualInputPanel(
                        metric: store.viewState.sheetState.metric ?? store.viewState.currentMetric,
                        text: Binding(
                            get: { store.viewState.entryDraft.manualInput },
                            set: { store.handle(.updateManualInput($0)) }
                        ),
                        onBackToRuler: { store.handle(.switchToRulerInput) }
                    )
                } else {
                    GrowthRulerPicker(
                        config: store.currentRulerConfig,
                        value: Binding(
                            get: { store.viewState.entryDraft.value },
                            set: { store.handle(.updateRulerValue($0)) }
                        ),
                        onTapManualInput: { store.handle(.switchToManualInput) }
                    )
                }
            }
        } footer: {
            SheetPrimaryButton(
                title: "完成记录",
                isEnabled: store.isSaveEnabled,
                action: { store.handle(.saveRecord) }
            )
        }
    }
}
