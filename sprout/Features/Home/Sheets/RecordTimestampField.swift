import SwiftUI

struct RecordTimestampField: View {
    let title: String
    @Binding var date: Date

    var body: some View {
        DatePicker(
            selection: $date,
            displayedComponents: [.date, .hourAndMinute]
        ) {
            Text(title)
                .font(AppTheme.Typography.meta)
                .foregroundStyle(AppTheme.Colors.secondaryText)
        }
        .datePickerStyle(.compact)
        .tint(AppTheme.Colors.primaryText)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
        .shadow(color: AppTheme.Shadow.color, radius: AppTheme.Shadow.radius, y: AppTheme.Shadow.y)
    }
}
