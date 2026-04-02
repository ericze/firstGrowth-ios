import Observation
import SwiftUI

struct SleepControlSheet: View {
    @Bindable var store: HomeStore

    var body: some View {
        BaseRecordSheet(title: String(localized: "home.sheet.sleep.title"), onClose: { store.handle(.dismissSheet) }) {
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
                                Text(String(localized: "home.sheet.sleep.status"))
                                    .font(AppTheme.Typography.meta)
                                    .foregroundStyle(AppTheme.Colors.secondaryText)

                                LiveSleepDurationText(
                                    startedAt: session.startedAt,
                                    prefix: String(localized: "home.sheet.sleep.prefix"),
                                    font: AppTheme.Typography.cardTitle,
                                    color: AppTheme.Colors.primaryText
                                )
                            }
                        }

                        Divider()
                            .overlay(AppTheme.Colors.divider)

                        HStack {
                            metaBlock(title: String(localized: "home.sheet.sleep.start_time"), value: session.startedAt.formatted(date: .omitted, time: .shortened))
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
            SheetPrimaryButton(title: String(localized: "home.sheet.sleep.end_button"), isEnabled: store.viewState.ongoingSleep != nil) {
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

    private let formatter = TimelineContentFormatter()

    var body: some View {
        TimelineView(.periodic(from: startedAt, by: 1)) { context in
            VStack(alignment: .leading, spacing: 6) {
                Text(String(localized: "home.sheet.sleep.current_duration"))
                    .font(AppTheme.Typography.meta)
                    .foregroundStyle(AppTheme.Colors.secondaryText)

                Text(formattedDuration(at: context.date))
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundStyle(AppTheme.Colors.primaryText)
                    .contentTransition(.numericText())
                    .monospacedDigit()
            }
        }
    }

    private func formattedDuration(at date: Date) -> String {
        formatter.formatSleepDuration(durationInSeconds: max(0, date.timeIntervalSince(startedAt)))
    }
}
