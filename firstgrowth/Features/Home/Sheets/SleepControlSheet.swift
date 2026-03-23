import Combine
import Observation
import SwiftUI

struct SleepControlSheet: View {
    @Bindable var store: HomeStore

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

                                LiveSleepDurationText(
                                    startedAt: session.startedAt,
                                    prefix: "已睡 ",
                                    font: AppTheme.Typography.cardTitle,
                                    color: AppTheme.Colors.primaryText
                                )
                            }
                        }

                        Divider()
                            .overlay(AppTheme.Colors.divider)

                        HStack {
                            metaBlock(title: "开始时间", value: session.startedAt.formatted(date: .omitted, time: .shortened))
                            Spacer()
                            LiveSleepDurationMetaBlock(startedAt: session.startedAt)
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

private struct LiveSleepDurationMetaBlock: View {
    let startedAt: Date

    @State private var currentDate = Date()

    private let formatter = TimelineContentFormatter()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("当前时长")
                .font(AppTheme.Typography.meta)
                .foregroundStyle(AppTheme.Colors.secondaryText)

            Text(formatter.formatSleepDuration(durationInSeconds: currentDate.timeIntervalSince(startedAt)))
                .font(AppTheme.Typography.cardTitle)
                .foregroundStyle(AppTheme.Colors.primaryText)
                .contentTransition(.numericText())
                .monospacedDigit()
        }
        .onAppear {
            currentDate = Date()
        }
        .onReceive(timer) { date in
            currentDate = date
        }
    }
}
