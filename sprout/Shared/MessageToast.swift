import SwiftUI

struct MessageToastState: Equatable, Identifiable {
    let id = UUID()
    let message: String
}

struct MessageToast: View {
    let state: MessageToastState
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.secondaryText)

            Text(state.message)
                .font(AppTheme.Typography.meta)
                .foregroundStyle(AppTheme.Colors.primaryText)
                .lineLimit(2)

            Spacer(minLength: 8)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.tertiaryText)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.text("common.toast.dismiss", en: "Dismiss message", zh: "关闭提示"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: AppTheme.Shadow.color, radius: AppTheme.Shadow.radius, y: AppTheme.Shadow.y)
    }
}
