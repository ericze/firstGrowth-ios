import SwiftUI

struct RecordEditorDateField: View {
    let title: String
    @Binding var date: Date
    var displayedComponents: DatePickerComponents = [.date, .hourAndMinute]
    var supportingText: String? = nil
    var supportingColor: Color = AppTheme.Colors.secondaryText

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 16) {
                Text(title)
                    .font(AppTheme.Typography.meta)
                    .foregroundStyle(AppTheme.Colors.secondaryText)

                Spacer(minLength: 12)

                DatePicker(
                    "",
                    selection: $date,
                    displayedComponents: displayedComponents
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(AppTheme.Colors.primaryText)
            }

            if let supportingText, !supportingText.isEmpty {
                Text(supportingText)
                    .font(AppTheme.Typography.meta)
                    .foregroundStyle(supportingColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
    }
}
