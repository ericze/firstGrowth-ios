import SwiftUI

struct TreasureWeeklyLetterSheet: View {
    let item: TreasureTimelineItem
    let onClose: () -> Void

    var body: some View {
        BaseRecordSheet(title: "时光信笺", onClose: onClose) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    if let weekStart = item.weekStart, let weekEnd = item.weekEnd {
                        Text(rangeText(weekStart: weekStart, weekEnd: weekEnd))
                            .font(AppTheme.Typography.meta)
                            .foregroundStyle(AppTheme.Colors.secondaryText)
                    }

                    Text(item.expandedText ?? item.collapsedText ?? "")
                        .font(AppTheme.Typography.sheetBody)
                        .foregroundStyle(AppTheme.Colors.primaryText)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)
            }
        }
    }

    private func rangeText(weekStart: Date, weekEnd: Date) -> String {
        let formatter = TreasureWeeklyLetterRangeFormatter.shared
        return "\(formatter.string(from: weekStart).uppercased()) - \(formatter.string(from: weekEnd).uppercased())"
    }
}

private enum TreasureWeeklyLetterRangeFormatter {
    static let shared: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}
