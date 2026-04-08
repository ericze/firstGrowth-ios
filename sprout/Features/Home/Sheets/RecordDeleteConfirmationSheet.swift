import SwiftUI

struct RecordDeleteConfirmationSheet: View {
    let summary: RecordDeleteSummary
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text(
                L10n.text(
                    "home.record.delete.title",
                    en: "Delete this record?",
                    zh: "删除这条记录？"
                )
            )
            .font(AppTheme.Typography.sheetTitle)
            .foregroundStyle(AppTheme.Colors.primaryText)
            .multilineTextAlignment(.center)

            summaryCard

            Text(
                L10n.text(
                    "home.record.delete.message",
                    en: "This record will leave the timeline. You can still undo it for a short time.",
                    zh: "删除后会从时间线移除。你仍可在短时间内撤销。"
                )
            )
            .font(AppTheme.Typography.meta)
            .foregroundStyle(AppTheme.Colors.secondaryText)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 14) {
                Button(action: onConfirm) {
                    Text(
                        L10n.text(
                            "home.record.delete.confirm",
                            en: "Delete",
                            zh: "删除"
                        )
                    )
                    .font(AppTheme.Typography.primaryButton)
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(AppTheme.Colors.primaryText)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: onCancel) {
                    Text(
                        L10n.text(
                            "home.record.delete.cancel",
                            en: "Cancel",
                            zh: "取消"
                        )
                    )
                    .font(AppTheme.Typography.primaryButton)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppTheme.Colors.background)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(summary.title)
                .font(AppTheme.Typography.cardTitle)
                .foregroundStyle(AppTheme.Colors.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            if let subtitle = summary.subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(AppTheme.Typography.cardBody)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(summary.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(AppTheme.Typography.meta)
                .foregroundStyle(AppTheme.Colors.tertiaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.sheetCard, style: .continuous))
        .shadow(color: AppTheme.Shadow.color, radius: AppTheme.Shadow.radius, y: AppTheme.Shadow.y)
    }
}
