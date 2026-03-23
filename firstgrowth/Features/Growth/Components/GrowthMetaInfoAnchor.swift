import SwiftUI

struct GrowthMetaInfoAnchor: View {
    let metaInfo: GrowthMetaInfo
    let dataState: GrowthDataState

    var body: some View {
        Text(metaInfo.summaryText)
            .font(.system(size: 17, weight: dataState == .empty ? .medium : .semibold))
            .foregroundStyle(dataState == .empty ? AppTheme.Colors.secondaryText : AppTheme.Colors.primaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
