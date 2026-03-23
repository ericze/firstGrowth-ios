import SwiftUI

struct TimeMetaView: View {
    let date: Date

    var body: some View {
        Text(date.formatted(date: .omitted, time: .shortened))
            .font(AppTheme.Typography.meta)
            .foregroundStyle(AppTheme.Colors.tertiaryText)
            .monospacedDigit()
    }
}
