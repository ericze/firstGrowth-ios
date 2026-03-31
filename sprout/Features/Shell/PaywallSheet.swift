import SwiftUI

struct PaywallSheet: View {
    let featureTitle: String

    @Environment(\.dismiss) private var dismiss
    @State private var showToast = false

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 32)
                .padding(.horizontal, AppTheme.Spacing.screenHorizontal)

            featuresList
                .padding(.top, 24)
                .padding(.horizontal, AppTheme.Spacing.screenHorizontal)

            upgradeButton
                .padding(.top, 28)
                .padding(.horizontal, AppTheme.Spacing.screenHorizontal)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .background(AppTheme.Colors.background)
        .presentationDetents([.medium])
        .overlay {
            if showToast {
                toastOverlay
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkle")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(AppTheme.Colors.accent)

            Text(String(localized: "shell.paywall.title"))
                .font(AppTheme.Typography.sheetTitle)
                .foregroundStyle(AppTheme.Colors.primaryText)

            Text(featureTitle)
                .font(AppTheme.Typography.cardBody)
                .foregroundStyle(AppTheme.Colors.secondaryText)
        }
    }

    private var featuresList: some View {
        VStack(alignment: .leading, spacing: 16) {
            featureRow(String(localized: "shell.paywall.feature.family"))
            featureRow(String(localized: "shell.paywall.feature.cloud"))
            featureRow(String(localized: "shell.paywall.feature.more"))
        }
    }

    private func featureRow(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(AppTheme.Colors.accent)

            Text(text)
                .font(AppTheme.Typography.cardBody)
                .foregroundStyle(AppTheme.Colors.primaryText)
        }
    }

    private var upgradeButton: some View {
        Button(action: {
            AppHaptics.lightImpact()
            showToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showToast = false
            }
        }) {
            Text(String(localized: "shell.paywall.upgrade"))
                .font(AppTheme.Typography.primaryButton)
                .foregroundStyle(AppTheme.Colors.cardBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.Colors.accent)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var toastOverlay: some View {
        Text(String(localized: "shell.paywall.coming_soon"))
            .font(AppTheme.Typography.meta)
            .foregroundStyle(AppTheme.Colors.cardBackground)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(AppTheme.Colors.primaryText.opacity(0.85))
            .clipShape(Capsule())
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 8)
            .transition(.opacity)
            .animation(AppTheme.stateAnimation, value: showToast)
    }
}
