import SwiftUI

struct TreasureHeaderBar: View {
    let action: () -> Void

    var body: some View {
        HStack {
            Spacer()

            Button(action: action) {
                Image(systemName: "plus.viewfinder")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(TreasureTheme.sageDeep)
                    .frame(width: TreasureTheme.headerButtonSize, height: TreasureTheme.headerButtonSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("留住今天")
        }
    }
}
