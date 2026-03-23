import Observation
import SwiftUI

struct DiaperRecordSheet: View {
    @Bindable var store: HomeStore

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        BaseRecordSheet(title: "记尿布", onClose: { store.handle(.dismissSheet) }) {
            LazyVGrid(columns: columns, spacing: 14) {
                diaperButton(title: "小便", subtitle: "点一下就记上", subtype: .pee)
                diaperButton(title: "大便", subtitle: "快速留痕", subtype: .poop)
                diaperButton(title: "都有", subtitle: "一次完成", subtype: .both)
            }
        }
    }

    private func diaperButton(title: String, subtitle: String, subtype: DiaperSubtype) -> some View {
        Button {
            store.handle(.saveDiaper(subtype))
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundStyle(AppTheme.Colors.primaryText)

                Text(subtitle)
                    .font(AppTheme.Typography.meta)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
            .padding(18)
            .background(AppTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
