import SwiftUI

struct TreasureAddEntryButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))

                Text("留住今天")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(AppTheme.Colors.primaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppTheme.Colors.cardBackground.opacity(0.96))
            .clipShape(Capsule())
            .shadow(color: AppTheme.Shadow.color, radius: AppTheme.Shadow.radius, y: AppTheme.Shadow.y)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("留住今天")
    }
}
