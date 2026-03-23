import SwiftUI

struct TreasureEmptyState: View {
    let filter: TreasureFilter
    let dataState: TreasureDataState
    let errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(AppTheme.Colors.accent.opacity(0.6))

            Text(message)
                .font(AppTheme.Typography.cardBody)
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            if let errorMessage, dataState == .error {
                Text(errorMessage)
                    .font(AppTheme.Typography.meta)
                    .foregroundStyle(AppTheme.Colors.tertiaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 84)
    }

    private var iconName: String {
        switch dataState {
        case .error:
            "tray"
        default:
            "camera.aperture"
        }
    }

    private var message: String {
        if dataState == .error {
            return "这一页暂时没有顺利展开。"
        }

        switch filter {
        case .allMemories:
            return "这里存放时间。点击右上角，留住今天。"
        case .starredMoments:
            return "还没有被点亮的时刻。"
        case .timeLetters:
            return "这里会放时间寄来的信。"
        }
    }
}
