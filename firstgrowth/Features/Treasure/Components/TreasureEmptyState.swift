import SwiftUI

struct TreasureEmptyState: View {
    let dataState: TreasureDataState
    let errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(TreasureTheme.sageDeep.opacity(0.42))

            Text(message)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(TreasureTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            if let errorMessage, dataState == .error {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(TreasureTheme.textSecondary.opacity(0.7))
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
        return "这里存放时间。点右上角的取景框，留住今天。"
    }
}
