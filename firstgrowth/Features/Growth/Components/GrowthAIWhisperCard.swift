import SwiftUI

struct GrowthAIWhisperCard: View {
    let state: GrowthAIState
    let content: GrowthAIContent
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Text("AI 客观解读")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.secondaryText)

                Spacer()

                Button(action: onToggle) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                        .rotationEffect(state == .expanded ? .degrees(0) : .degrees(-90))
                        .frame(width: 32, height: 32)
                        .background(AppTheme.Colors.background.opacity(0.55))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(state == .expanded ? "折叠解读" : "展开解读")
            }

            Text(state == .expanded ? content.expandedText : content.collapsedText)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(AppTheme.Colors.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
        .shadow(color: AppTheme.Shadow.color, radius: AppTheme.Shadow.radius, y: AppTheme.Shadow.y)
    }
}
