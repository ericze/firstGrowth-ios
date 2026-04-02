import SwiftUI

struct GrowthRecordEntryButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(L10n.text("growth.entry.add", en: "+Record", zh: "+记录"))
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
        .accessibilityLabel(L10n.text("growth.entry.add_accessibility", en: "Add growth record", zh: "新增成长记录"))
    }
}
