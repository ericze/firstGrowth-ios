import SwiftUI

struct TreasureWeeklyLetterCard: View {
    let item: TreasureTimelineItem
    let onTap: () -> Void

    var body: some View {
        Group {
            if item.canOpenWeeklyLetter {
                Button(action: onTap) {
                    cardContent(showsExpandHint: true)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("打开这一周的信")
            } else {
                cardContent(showsExpandHint: false)
            }
        }
    }

    private func cardContent(showsExpandHint: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("时光信笺")
                    .font(.system(size: 12, weight: .medium))
                    .tracking(0.4)
                    .foregroundStyle(TreasureTheme.textSecondary)

                Spacer()

                if showsExpandHint {
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(TreasureTheme.textSecondary.opacity(0.65))
                }
            }

            Text(item.collapsedText ?? "")
                .font(.system(size: item.type == .weeklyLetterDense ? 18 : 17, weight: .medium))
                .foregroundStyle(TreasureTheme.textPrimary)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)

            if let weekEnd = item.weekEnd {
                Text(TreasureTimestampFormatter.shared.string(from: weekEnd, ageInDays: nil))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(TreasureTheme.textSecondary.opacity(0.7))
            }
        }
        .padding(.horizontal, TreasureTheme.contentPadding)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TreasureTheme.paperWhite)
        .clipShape(TopRoundedCardShape(radius: TreasureTheme.cardRadius))
    }
}
