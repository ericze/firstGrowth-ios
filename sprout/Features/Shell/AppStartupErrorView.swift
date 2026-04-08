//
//  AppStartupErrorView.swift
//  sprout
//

import SwiftUI

struct AppStartupErrorView: View {
    let errorMessage: String
    private var sanitizedErrorMessage: String {
        let trimmed = errorMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty
            ? L10n.text("startup_error.unknown", en: "Unknown startup error.", zh: "未知启动错误。")
            : trimmed
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.section) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(AppTheme.Colors.secondaryText)

                VStack(spacing: 8) {
                    Text(L10n.text("startup_error.title", en: "Unable to Start", zh: "无法启动"))
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundStyle(AppTheme.Colors.primaryText)
                        .multilineTextAlignment(.center)

                    Text(L10n.text("startup_error.message", en: "The app encountered a problem and cannot start. Please restart the app or reinstall if the issue persists.", zh: "应用遇到了问题，无法正常启动。请尝试重启应用，若问题持续，可能需要重新安装。"))
                        .font(AppTheme.Typography.cardBody)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, AppTheme.Spacing.screenHorizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.text("startup_error.details", en: "Error details", zh: "错误详情"))
                        .font(AppTheme.Typography.meta)
                        .foregroundStyle(AppTheme.Colors.tertiaryText)

                    Text(sanitizedErrorMessage)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                        .textSelection(.enabled)
                        .lineLimit(6)

                    Text(L10n.text("startup_error.recovery_hint", en: "Try closing and reopening the app. If the issue persists, reinstall the app.", zh: "请先关闭并重新打开应用；若问题持续，请重新安装应用。"))
                        .font(AppTheme.Typography.meta)
                        .foregroundStyle(AppTheme.Colors.tertiaryText)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.Colors.cardBackground.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, AppTheme.Spacing.screenHorizontal)
            }
            .padding(AppTheme.Spacing.section)
        }
    }
}

// MARK: - Preview

#Preview {
    AppStartupErrorView(errorMessage: "Test error")
}
