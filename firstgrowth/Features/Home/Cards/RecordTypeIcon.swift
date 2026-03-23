import SwiftUI

struct RecordTypeIcon: View {
    let icon: RecordIcon

    var body: some View {
        Group {
            switch icon {
            case .milk:
                MilkBottleIcon()
                    .frame(width: 17, height: 17)
            case .food:
                FoodSolidsIcon()
                    .frame(width: 17, height: 17)
            case .diaper:
                DiaperIcon()
                    .frame(width: 17, height: 17)
            case .sleep, .height, .weight:
                Image(systemName: icon.systemName)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(AppTheme.Colors.primaryText)
            }
        }
        .frame(width: 42, height: 42)
        .background(AppTheme.Colors.iconBackground)
        .clipShape(Circle())
    }
}
