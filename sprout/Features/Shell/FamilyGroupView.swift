import SwiftUI

struct FamilyGroupView: View {
    @Bindable var store: FamilyGroupStore
    let babyRepository: BabyRepository

    @Environment(\.dismiss) private var dismiss
    @State private var sharedBabyNames: [String] = []

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
                statusCard
                if let familyGroup = store.currentFamilyGroup {
                    inviteCard(familyGroup)
                    sharedBabiesCard(familyGroup)
                }
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
                Text(L10n.text("paywall.feature.family.title", en: "Family Group", zh: "家庭组"))
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundStyle(AppTheme.Colors.primaryText)
            }
        }
        .onAppear {
            refresh()
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(AppTheme.Colors.accent)

            Text(statusTitle)
                .font(AppTheme.Typography.cardTitle)
                .foregroundStyle(AppTheme.Colors.primaryText)

            Text(statusDetail)
                .font(AppTheme.Typography.cardBody)
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            if store.currentFamilyGroup == nil {
                Button(action: {
                    guard store.createFamilyGroup() else { return }
                    refreshSharedBabyNames()
                    AppHaptics.lightImpact()
                }) {
                    Text(L10n.text("family_group.create", en: "Create Family Group", zh: "创建家庭组"))
                        .font(AppTheme.Typography.sheetBody)
                        .foregroundStyle(AppTheme.Colors.cardBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(AppTheme.Colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            if let error = store.error {
                Text(error.userMessage)
                    .font(AppTheme.Typography.meta)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }
        }
        .padding(AppTheme.Spacing.section)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
        .shadow(color: AppTheme.Shadow.color, radius: AppTheme.Shadow.radius, y: AppTheme.Shadow.y)
    }

    private func inviteCard(_ familyGroup: FamilyGroup) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.text("family_group.invite.title", en: "Invite Code", zh: "邀请码"))
                .font(AppTheme.Typography.cardTitle)
                .foregroundStyle(AppTheme.Colors.primaryText)

            Text(familyGroup.inviteCode ?? L10n.text("family_group.invite.empty", en: "Not generated", zh: "尚未生成"))
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.Colors.primaryText)
                .textSelection(.enabled)

            if store.ownershipState == .owner {
                Button(action: {
                    guard store.rotateInviteCode() else { return }
                    AppHaptics.selection()
                }) {
                    Text(L10n.text("family_group.invite.refresh", en: "Refresh Code", zh: "刷新邀请码"))
                        .font(AppTheme.Typography.sheetBody)
                        .foregroundStyle(AppTheme.Colors.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(AppTheme.Colors.iconBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppTheme.Spacing.section)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
        .shadow(color: AppTheme.Shadow.color, radius: AppTheme.Shadow.radius, y: AppTheme.Shadow.y)
    }

    private func sharedBabiesCard(_ familyGroup: FamilyGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text("family_group.shared_babies.title", en: "Shared Babies", zh: "共享宝宝"))
                .font(AppTheme.Typography.cardTitle)
                .foregroundStyle(AppTheme.Colors.primaryText)

            if familyGroup.sharedBabyIDs.isEmpty {
                Text(L10n.text(
                    "family_group.shared_babies.empty",
                    en: "No babies are shared yet.",
                    zh: "还没有共享宝宝。"
                ))
                .font(AppTheme.Typography.cardBody)
                .foregroundStyle(AppTheme.Colors.secondaryText)
            } else {
                ForEach(sharedBabyNames, id: \.self) { name in
                    Text(name)
                        .font(AppTheme.Typography.sheetBody)
                        .foregroundStyle(AppTheme.Colors.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }
            }
        }
        .padding(AppTheme.Spacing.section)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
        .shadow(color: AppTheme.Shadow.color, radius: AppTheme.Shadow.radius, y: AppTheme.Shadow.y)
    }

    private var statusTitle: String {
        switch store.ownershipState {
        case .owner:
            L10n.text("family_group.owner.title", en: "Your family group", zh: "你的家庭组")
        case .member:
            L10n.text("family_group.member.title", en: "Joined family group", zh: "已加入家庭组")
        case .none:
            L10n.text("family_group.empty.title", en: "Create a quiet sharing space", zh: "创建一个安静的共享空间")
        }
    }

    private var statusDetail: String {
        switch store.ownershipState {
        case .owner:
            L10n.text(
                "family_group.owner.detail",
                en: "Invite family with a code and choose which babies to share.",
                zh: "用邀请码邀请家人，并选择要共享的宝宝。"
            )
        case .member:
            L10n.text(
                "family_group.member.detail",
                en: "Shared babies appear separately in the baby profile screen.",
                zh: "共享宝宝会在宝宝资料页单独显示。"
            )
        case .none:
            L10n.text(
                "family_group.empty.detail",
                en: "Family Group lets trusted family help record shared moments.",
                zh: "家庭组让信任的家人一起记录共享的时刻。"
            )
        }
    }

    private func refresh() {
        _ = store.loadCurrentFamilyGroup()
        refreshSharedBabyNames()
    }

    private func refreshSharedBabyNames() {
        guard let group = store.currentFamilyGroup else {
            sharedBabyNames = []
            return
        }
        let sharedIDs = Set(group.sharedBabyIDs)
        sharedBabyNames = ((try? babyRepository.fetchBabies()) ?? [])
            .filter { sharedIDs.contains($0.id) }
            .map(\.name)
    }
}
