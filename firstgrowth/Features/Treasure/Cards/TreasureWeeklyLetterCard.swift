import SwiftUI

struct TreasureWeeklyLetterCard: View {
    let item: TreasureTimelineItem
    let onTap: () -> Void

    var body: some View {
        Group {
            if item.type == .weeklyLetterSilent {
                silentCard
            } else {
                Button(action: onTap) {
                    expandableCard
                }
                .buttonStyle(.plain)
                .accessibilityLabel("打开这一周的信")
            }
        }
    }

    private var silentCard: some View {
        HStack(spacing: 12) {
            Capsule()
                .fill(AppTheme.Colors.accent.opacity(0.45))
                .frame(width: 3)

            Text(item.collapsedText ?? "")
                .font(AppTheme.Typography.cardBody)
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .lineSpacing(3)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(AppTheme.Colors.cardBackground.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var expandableCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("时光信笺")
                    .font(AppTheme.Typography.meta)
                    .foregroundStyle(AppTheme.Colors.secondaryText)

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.tertiaryText)
            }

            Text(item.collapsedText ?? "")
                .font(.system(size: item.type == .weeklyLetterDense ? 18 : 17, weight: .medium))
                .foregroundStyle(AppTheme.Colors.primaryText)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)

            if let weekEnd = item.weekEnd {
                Text(TreasureTimestampFormatter.shared.string(from: weekEnd, ageInDays: nil))
                    .font(AppTheme.Typography.meta)
                    .foregroundStyle(AppTheme.Colors.tertiaryText)
            }
        }
        .padding(20)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: AppTheme.Shadow.color, radius: AppTheme.Shadow.radius, y: AppTheme.Shadow.y)
    }
}
