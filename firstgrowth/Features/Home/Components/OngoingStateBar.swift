import Combine
import SwiftUI

struct OngoingStateBar: View {
    let session: SleepSessionState
    let onTap: () -> Void
    let onEnd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(AppTheme.Colors.accent)
                        .frame(width: 34, height: 34)
                        .background(AppTheme.Colors.accent.opacity(0.14))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text("睡眠中")
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
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button(action: onEnd) {
                Text("结束")
                    .font(AppTheme.Typography.meta)
                    .foregroundStyle(AppTheme.Colors.primaryText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppTheme.Colors.cardBackground)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("结束睡眠")
        }
        .padding(14)
        .background(AppTheme.Colors.floatingMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: AppTheme.Shadow.color, radius: AppTheme.Shadow.radius, y: AppTheme.Shadow.y)
    }
}

struct LiveSleepDurationText: View {
    let startedAt: Date
    let prefix: String
    let font: Font
    let color: Color

    @State private var currentDate = Date()

    private let formatter = TimelineContentFormatter()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text("\(prefix)\(formatter.formatSleepDuration(durationInSeconds: currentDate.timeIntervalSince(startedAt)))")
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText())
            .monospacedDigit()
            .onAppear {
                currentDate = Date()
            }
            .onReceive(timer) { date in
                currentDate = date
            }
    }
}
