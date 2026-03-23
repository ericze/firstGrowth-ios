import Observation
import SwiftUI

struct SleepControlSheet: View {
    @Bindable var store: HomeStore

    private let formatter = TimelineContentFormatter()

    var body: some View {
        BaseRecordSheet(title: "睡眠中", onClose: { store.handle(.dismissSheet) }) {
            if let session = store.viewState.ongoingSleep {
                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 12) {
                            Image(systemName: "moon.zzz.fill")
                                .font(.system(size: 20, weight: .regular))
                                .foregroundStyle(AppTheme.Colors.accent)
                                .frame(width: 44, height: 44)
                                .background(AppTheme.Colors.iconBackground)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text("正在睡眠")
                                    .font(AppTheme.Typography.meta)
                                    .foregroundStyle(AppTheme.Colors.secondaryText)

                                TimelineView(.periodic(from: .now, by: 60)) { context in
                                    Text("已睡 \(formatter.formatSleepDuration(durationInSeconds: context.date.timeIntervalSince(session.startedAt)))")
                                        .font(AppTheme.Typography.cardTitle)
                                        .foregroundStyle(AppTheme.Colors.primaryText)
                                        .contentTransition(.numericText())
                                }
                            }
                        }

                        Divider()
                            .overlay(AppTheme.Colors.divider)

                        HStack {
                            metaBlock(title: "开始时间", value: session.startedAt.formatted(date: .omitted, time: .shortened))
                            Spacer()
                            TimelineView(.periodic(from: .now, by: 60)) { context in
                                metaBlock(
                                    title: "当前时长",
                                    value: formatter.formatSleepDuration(durationInSeconds: context.date.timeIntervalSince(session.startedAt))
                                )
                            }
                        }
                    }
                    .padding(20)
                    .background(AppTheme.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
                }
            }
        } footer: {
            SheetPrimaryButton(title: "结束睡眠", isEnabled: store.viewState.ongoingSleep != nil) {
                store.handle(.finishSleep)
            }
        }
    }

    private func metaBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppTheme.Typography.meta)
                .foregroundStyle(AppTheme.Colors.secondaryText)

            Text(value)
                .font(AppTheme.Typography.cardTitle)
                .foregroundStyle(AppTheme.Colors.primaryText)
        }
    }
}
