import SwiftUI

struct EmotionHeaderBlock: View {
    let headerConfig: HomeHeaderConfig
    let referenceDate: Date
    let calendar: Calendar

    init(headerConfig: HomeHeaderConfig, referenceDate: Date, calendar: Calendar = .current) {
        self.headerConfig = headerConfig
        self.referenceDate = referenceDate
        self.calendar = calendar
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(formattedDate)
                .font(AppTheme.Typography.headerDate)
                .foregroundStyle(AppTheme.Colors.primaryText)

            Text("\(headerConfig.babyName)的第 \(dayCount) 天")
                .font(AppTheme.Typography.headerMeta)
                .foregroundStyle(AppTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 6)
    }

    private var formattedDate: String {
        referenceDate.formatted(
            .dateTime
                .month(.defaultDigits)
                .day()
                .weekday(.wide)
        )
    }

    private var dayCount: Int {
        let start = calendar.startOfDay(for: headerConfig.birthDate)
        let end = calendar.startOfDay(for: referenceDate)
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return max(days + 1, 1)
    }
}
