import SwiftUI

struct OngoingStateBar: View {
    let session: SleepSessionState
    let onTap: () -> Void
    let onEnd: () -> Void

    private let formatter = TimelineContentFormatter()

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

                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("睡眠中")
                                .font(AppTheme.Typography.meta)
                                .foregroundStyle(AppTheme.Colors.secondaryText)

                            Text("已睡 \(formatter.formatSleepDuration(durationInSeconds: context.date.timeIntervalSince(session.startedAt)))")
                                .font(AppTheme.Typography.cardTitle)
                                .foregroundStyle(AppTheme.Colors.primaryText)
                                .contentTransition(.numericText())
                        }
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
