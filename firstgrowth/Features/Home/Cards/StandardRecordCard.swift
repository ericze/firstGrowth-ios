import SwiftUI

struct StandardRecordCard: View {
    let item: TimelineDisplayItem

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            RecordTypeIcon(icon: item.leadingIcon)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundStyle(AppTheme.Colors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(AppTheme.Typography.cardBody)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 12)

            TimeMetaView(date: item.timestamp)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
        .shadow(color: AppTheme.Shadow.color, radius: AppTheme.Shadow.radius, y: AppTheme.Shadow.y)
    }
}
