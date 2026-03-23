import SwiftUI

struct GrowthRecordEntryButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("+记录")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.Colors.primaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppTheme.Colors.background.opacity(0.8))
                .overlay {
                    Capsule()
                        .stroke(AppTheme.Colors.divider, lineWidth: 1)
                }
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("新增成长记录")
    }
}
