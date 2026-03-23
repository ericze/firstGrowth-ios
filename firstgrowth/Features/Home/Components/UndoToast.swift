import SwiftUI

struct UndoToast: View {
    let state: UndoToastState
    let onUndo: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(state.message)
                .font(AppTheme.Typography.meta)
                .foregroundStyle(AppTheme.Colors.primaryText)
                .lineLimit(2)

            Spacer(minLength: 8)

            Button("撤销", action: onUndo)
                .font(AppTheme.Typography.primaryButton)
                .foregroundStyle(AppTheme.Colors.primaryText)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.tertiaryText)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("关闭撤销提示")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: AppTheme.Shadow.color, radius: AppTheme.Shadow.radius, y: AppTheme.Shadow.y)
    }
}
