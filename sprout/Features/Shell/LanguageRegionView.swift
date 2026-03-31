import SwiftUI

struct LanguageRegionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLanguage: AppLanguage
    @State private var showRestartAlert = false

    init() {
        _selectedLanguage = State(initialValue: LocalizationService.current.language)
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
        .alert(
            String(localized: "shell.language.restart.title"),
            isPresented: $showRestartAlert
        ) {
            Button(String(localized: "common.ok"), role: .cancel) {}
        } message: {
            Text(String(localized: "shell.language.restart.message"))
        }
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(String(localized: "shell.language.label"))

            HStack(spacing: 12) {
                languageChip(
                    label: "English",
                    language: .english
                )
                languageChip(
                    label: "\u{4e2d}\u{6587}",
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

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppTheme.Typography.meta)
            .foregroundStyle(AppTheme.Colors.tertiaryText)
            .padding(.horizontal, AppTheme.Spacing.section)
            .padding(.bottom, 12)
    }

    private func languageChip(label: String, language: AppLanguage) -> some View {
        let isSelected = selectedLanguage == language
        return Button(action: {
            guard !isSelected else { return }
            AppHaptics.selection()
            selectedLanguage = language
            showRestartAlert = true
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
}
