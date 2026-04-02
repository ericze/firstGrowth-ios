import Observation
import SwiftUI

struct DiaperRecordSheet: View {
    @Bindable var store: HomeStore

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        BaseRecordSheet(title: String(localized: "home.sheet.diaper.title"), onClose: { store.handle(.dismissSheet) }) {
            LazyVGrid(columns: columns, spacing: 14) {
                diaperButton(
                    title: String(localized: "home.sheet.diaper.pee.title"),
                    subtitle: String(localized: "home.sheet.diaper.pee.subtitle"),
                    subtype: .pee
                )
                diaperButton(
                    title: String(localized: "home.sheet.diaper.poop.title"),
                    subtitle: String(localized: "home.sheet.diaper.poop.subtitle"),
                    subtype: .poop
                )
                diaperButton(
                    title: String(localized: "home.sheet.diaper.both.title"),
                    subtitle: String(localized: "home.sheet.diaper.both.subtitle"),
                    subtype: .both
                )
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
