import SwiftUI

struct FloatingActionBar: View {
    let hasOngoingSleep: Bool
    let onMilkTapped: () -> Void
    let onFoodTapped: () -> Void
    let onDiaperTapped: () -> Void
    let onStartSleep: () -> Void
    let onEndSleep: () -> Void

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                FloatingActionButton(
                    label: String(localized: "home.fab.feed.label"),
                    accessibilityLabel: String(localized: "home.fab.feed.accessibility"),
                    action: onMilkTapped
                ) {
                    MilkBottleIcon()
                        .frame(width: 24, height: 24)
                }

                FloatingActionButton(
                    label: String(localized: "home.fab.solids.label"),
                    accessibilityLabel: String(localized: "home.fab.solids.accessibility"),
                    action: onFoodTapped
                ) {
                    FoodSolidsIcon()
                        .frame(width: 24, height: 24)
                }

                FloatingActionButton(
                    label: String(localized: "home.fab.diaper.label"),
                    accessibilityLabel: String(localized: "home.fab.diaper.accessibility"),
                    action: onDiaperTapped
                ) {
                    DiaperIcon()
                        .frame(width: 24, height: 24)
                }

                SleepActionButton(
                    isActive: hasOngoingSleep,
                    onTapInactive: onStartSleep,
                    onTapActive: { },
                    onLongPressEnd: onEndSleep
                )
            }
            .frame(width: proxy.size.width * 0.9, height: 68)
            .background(capsuleBackground)
            .clipShape(Capsule())
            .shadow(
                color: AppTheme.Shadow.floatingBarColor,
                radius: AppTheme.Shadow.floatingBarRadius,
                y: AppTheme.Shadow.floatingBarY
            )
            .frame(maxWidth: .infinity)
        }
        .frame(height: 68)
    }

    private var capsuleBackground: some View {
        Capsule()
            .fill(AppTheme.Colors.floatingBarBackground)
            .background(.ultraThinMaterial, in: Capsule())
    }
}

private struct FloatingActionButton<Icon: View>: View {
    let label: String
    let accessibilityLabel: String
    let action: () -> Void
    @ViewBuilder let icon: () -> Icon

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                icon()

                Text(label)
                    .font(AppTheme.Typography.floatingLabel)
                    .foregroundStyle(AppTheme.Colors.primaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(FloatingActionPressStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}

struct FloatingActionPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.86 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
