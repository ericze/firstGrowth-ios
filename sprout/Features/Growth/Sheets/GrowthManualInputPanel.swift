import SwiftUI

struct GrowthManualInputPanel: View {
    let metric: GrowthMetric
    @Binding var text: String
    let onBackToRuler: () -> Void
    private let textRenderer = GrowthTextRenderer()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Spacer()

                Button(action: onBackToRuler) {
                    Text(L10n.text("growth.manual.back_to_ruler", en: "Back to ruler", zh: "返回刻度尺"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }
                .buttonStyle(.plain)
            }

            Text(
                L10n.format(
                    "growth.manual.prompt_format",
                    locale: Locale.autoupdatingCurrent,
                    en: "Enter the %@ value directly",
                    zh: "直接输入%@数值",
                    arguments: [textRenderer.metricTitle(metric)]
                )
            )
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppTheme.Colors.primaryText)

            HStack(spacing: 12) {
                TextField(L10n.text("growth.manual.placeholder", en: "0.0", zh: "0.0"), text: $text)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.primaryText)

                Text(textRenderer.unitSymbol(for: metric))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(AppTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            Text(
                L10n.text(
                    "growth.manual.note",
                    en: "Manual input is a fallback for speed. Units stay fixed, without extra note fields.",
                    zh: "手动输入是效率兜底，单位固定，不额外增加备注字段。"
                )
            )
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
