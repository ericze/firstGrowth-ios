import SwiftUI

struct MagazineTopBar: View {
    let selectedTab: HomeModule
    let babyName: String
    let onSelect: (HomeModule) -> Void
    let onAvatarTap: () -> Void

    var body: some View {
        ZStack {
            tabStrip
                .padding(.horizontal, 86)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack(spacing: 0) {
                avatarButton
                Spacer(minLength: 0)
            }
            .padding(.leading, 20)
        }
        .frame(height: 44)
    }

    private var tabStrip: some View {
        HStack(spacing: 22) {
            ForEach(HomeModule.allCases) { module in
                Button {
                    onSelect(module)
                } label: {
                    VStack(spacing: 5) {
                        Text(module.title)
                            .font(module == selectedTab ? AppTheme.Typography.navSelected : AppTheme.Typography.nav)
                            .foregroundStyle(module == selectedTab ? AppTheme.Colors.primaryText : AppTheme.Colors.secondaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        Capsule()
                            .fill(module == selectedTab ? AppTheme.Colors.sageGreen : .clear)
                            .frame(width: 16, height: 3)
                    }
                    .frame(minWidth: 48)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    String(
                        format: String(localized: "shell.topbar.switch_format"),
                        locale: .autoupdatingCurrent,
                        module.title
                    )
                )
            }
        }
    }

    private var avatarButton: some View {
        Button(action: onAvatarTap) {
            avatarMark
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "shell.topbar.open_sidebar"))
    }

    private var avatarMark: some View {
        Text(monogram)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppTheme.Colors.primaryText)
            .frame(width: 32, height: 32)
            .background(AppTheme.Colors.cardBackground)
            .overlay {
                Circle()
                    .stroke(AppTheme.Colors.divider, lineWidth: 1)
            }
            .clipShape(Circle())
            .shadow(color: AppTheme.Shadow.color, radius: AppTheme.Shadow.radius, y: AppTheme.Shadow.y)
    }

    private var monogram: String {
        let trimmedName = babyName.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackCharacter = HomeHeaderConfig.placeholder.babyName.first ?? Character("B")
        return String(trimmedName.first ?? fallbackCharacter)
    }
}
