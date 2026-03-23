import SwiftUI

struct GrowthManualInputPanel: View {
    let metric: GrowthMetric
    @Binding var text: String
    let onBackToRuler: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Spacer()

                Button(action: onBackToRuler) {
                    Text("返回刻度尺")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }
                .buttonStyle(.plain)
            }

            Text("直接输入\(metric.title)数值")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppTheme.Colors.primaryText)

            HStack(spacing: 12) {
                TextField("0.0", text: $text)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.primaryText)

                Text(metric.unit)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(AppTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            Text("手动输入是效率兜底，单位固定，不额外增加备注字段。")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
