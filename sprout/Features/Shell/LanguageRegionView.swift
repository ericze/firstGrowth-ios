import SwiftUI

struct LanguageRegionSelection {
    let currentLanguage: () -> AppLanguage
    let commit: (AppLanguage) -> Void

    func select(_ language: AppLanguage) {
        guard language != currentLanguage() else { return }
        commit(language)
    }
}

/// Language & Region settings page.
struct LanguageRegionView: View {
    /// Called when the user selects a different language.
    /// The view persists the selection through `AppLanguageManager`; this
    /// closure is only for parent-level side effects.
    var onLanguageChange: (AppLanguage) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @State private var languageManager = AppLanguageManager.shared

    private var currentLanguage: AppLanguage {
        languageManager.language
    }

    private var selection: LanguageRegionSelection {
        LanguageRegionSelection(
            currentLanguage: { languageManager.language },
            commit: { language in
                languageManager.language = language
                onLanguageChange(language)
            }
        )
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.section) {
                languageSection
                timezoneSection
            }
            .padding(.horizontal, AppTheme.Spacing.screenHorizontal)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .background(AppTheme.Colors.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.primaryText)
                }
            }
            ToolbarItem(placement: .principal) {
                Text(String(localized: "shell.sidebar.language.title"))
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundStyle(AppTheme.Colors.primaryText)
            }
        }
    }

    // MARK: - Language

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(String(localized: "shell.language.label"))

            HStack(spacing: 12) {
                languageChip(
                    label: "English",
                    language: .english
                )
                languageChip(
                    label: "中文",
                    language: .simplifiedChinese
                )
            }
            .padding(.horizontal, AppTheme.Spacing.section)
            .padding(.bottom, 20)
        }
        .padding(.top, 16)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
        .shadow(color: AppTheme.Shadow.color, radius: AppTheme.Shadow.radius, y: AppTheme.Shadow.y)
    }

    private func languageChip(label: String, language: AppLanguage) -> some View {
        let isSelected = currentLanguage == language
        return Button(action: {
            AppHaptics.selection()
            selection.select(language)
        }) {
            Text(label)
                .font(AppTheme.Typography.sheetBody)
                .foregroundStyle(isSelected ? AppTheme.Colors.cardBackground : AppTheme.Colors.primaryText)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.cardBackground)
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.divider, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Timezone

    private var timezoneSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(String(localized: "shell.timezone.label"))

            Text(TimeZone.current.identifier)
                .font(AppTheme.Typography.sheetBody)
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .padding(.horizontal, AppTheme.Spacing.section)
                .padding(.bottom, 20)
        }
        .padding(.top, 16)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
        .shadow(color: AppTheme.Shadow.color, radius: AppTheme.Shadow.radius, y: AppTheme.Shadow.y)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppTheme.Typography.meta)
            .foregroundStyle(AppTheme.Colors.tertiaryText)
            .padding(.horizontal, AppTheme.Spacing.section)
            .padding(.bottom, 12)
    }
}
