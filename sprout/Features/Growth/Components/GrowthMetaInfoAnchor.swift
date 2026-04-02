import SwiftUI

struct GrowthMetaInfoAnchor: View {
    let metaInfo: GrowthMetaInfo
    let dataState: GrowthDataState
    private let textRenderer = GrowthTextRenderer()

    var body: some View {
        Text(textRenderer.metaSummary(metaInfo))
            .font(.system(size: 17, weight: dataState == .empty ? .medium : .semibold))
            .foregroundStyle(dataState == .empty ? AppTheme.Colors.secondaryText : AppTheme.Colors.primaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
