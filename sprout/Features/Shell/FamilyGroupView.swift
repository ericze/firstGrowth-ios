import SwiftUI

struct FamilyGroupView: View {
    @Bindable var store: FamilyGroupStore
    let babyRepository: BabyRepository

    @Environment(\.dismiss) private var dismiss
    @State private var inviteCode = ""
    @State private var babies: [BabyProfile] = []

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
                statusCard
                if let familyGroup = store.currentFamilyGroup {
                    inviteCard(familyGroup)
                    sharedBabiesCard(familyGroup)
                    if store.ownershipState == .owner {
                        shareManagementCard(familyGroup)
                        membersCard(familyGroup)
                    }
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
                    refresh()
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

                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.text("family_group.join.prompt", en: "Have an invite code?", zh: "已有邀请码？"))
                        .font(AppTheme.Typography.meta)
                        .foregroundStyle(AppTheme.Colors.secondaryText)

                    TextField(
                        L10n.text("family_group.join.placeholder", en: "Invite code", zh: "邀请码"),
                        text: $inviteCode
                    )
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled(true)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(AppTheme.Colors.iconBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Button(action: joinFamilyGroup) {
                        Text(L10n.text("family_group.join.action", en: "Join Family Group", zh: "加入家庭组"))
                            .font(AppTheme.Typography.sheetBody)
                            .foregroundStyle(AppTheme.Colors.primaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(AppTheme.Colors.iconBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.top, 4)
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

            if let inviteStatus = inviteStatusText(for: familyGroup) {
                Text(inviteStatus)
                    .font(AppTheme.Typography.meta)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }

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

            let sharedBabies = babies.filter { familyGroup.sharedBabyIDs.contains($0.id) }

            if sharedBabies.isEmpty {
                Text(L10n.text(
                    "family_group.shared_babies.empty",
                    en: "No babies are shared yet.",
                    zh: "还没有共享宝宝。"
                ))
                .font(AppTheme.Typography.cardBody)
                .foregroundStyle(AppTheme.Colors.secondaryText)
            } else {
                ForEach(sharedBabies, id: \.id) { baby in
                    HStack(spacing: 12) {
                        Text(baby.name)
                            .font(AppTheme.Typography.sheetBody)
                            .foregroundStyle(AppTheme.Colors.primaryText)
                        Spacer(minLength: 8)
                        Text(L10n.text("family_group.shared_babies.shared", en: "Shared", zh: "已共享"))
                            .font(AppTheme.Typography.meta)
                            .foregroundStyle(AppTheme.Colors.secondaryText)
                    }
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

    private func shareManagementCard(_ familyGroup: FamilyGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text("family_group.manage_babies.title", en: "Share Babies", zh: "共享宝宝"))
                .font(AppTheme.Typography.cardTitle)
                .foregroundStyle(AppTheme.Colors.primaryText)

            if babies.isEmpty {
                Text(L10n.text(
                    "family_group.manage_babies.empty",
                    en: "Add a baby first to share it here.",
                    zh: "先添加宝宝，再在这里设置共享。"
                ))
                .font(AppTheme.Typography.cardBody)
                .foregroundStyle(AppTheme.Colors.secondaryText)
            } else {
                ForEach(babies, id: \.id) { baby in
                    let isShared = familyGroup.sharedBabyIDs.contains(baby.id)
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(baby.name)
                                .font(AppTheme.Typography.sheetBody)
                                .foregroundStyle(AppTheme.Colors.primaryText)
                            Text(isShared
                                 ? L10n.text("family_group.manage_babies.shared", en: "Visible to family", zh: "家人可见")
                                 : L10n.text("family_group.manage_babies.private", en: "Only you can see this", zh: "仅你可见"))
                                .font(AppTheme.Typography.meta)
                                .foregroundStyle(AppTheme.Colors.secondaryText)
                        }
                        Spacer(minLength: 8)
                        Button(action: {
                            guard store.setBabyShared(babyID: baby.id, shared: !isShared) else { return }
                            refresh()
                            AppHaptics.selection()
                        }) {
                            Text(isShared
                                 ? L10n.text("family_group.manage_babies.unshare", en: "Unshare", zh: "取消共享")
                                 : L10n.text("family_group.manage_babies.share", en: "Share", zh: "共享"))
                                .font(AppTheme.Typography.meta)
                                .foregroundStyle(AppTheme.Colors.primaryText)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(AppTheme.Colors.iconBackground)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
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

    private func membersCard(_ familyGroup: FamilyGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text("family_group.members.title", en: "Members", zh: "成员"))
                .font(AppTheme.Typography.cardTitle)
                .foregroundStyle(AppTheme.Colors.primaryText)

            let activeMembers = familyGroup.memberPayloads.filter { $0.removedAt == nil }

            if activeMembers.isEmpty {
                Text(L10n.text(
                    "family_group.members.empty",
                    en: "No members yet.",
                    zh: "还没有成员。"
                ))
                .font(AppTheme.Typography.cardBody)
                .foregroundStyle(AppTheme.Colors.secondaryText)
            } else {
                ForEach(activeMembers, id: \.userID) { member in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(memberLabel(for: member))
                                .font(AppTheme.Typography.sheetBody)
                                .foregroundStyle(AppTheme.Colors.primaryText)
                            Text(member.role == .owner
                                 ? L10n.text("family_group.members.owner", en: "Owner", zh: "创建者")
                                 : L10n.text("family_group.members.member", en: "Member", zh: "成员"))
                                .font(AppTheme.Typography.meta)
                                .foregroundStyle(AppTheme.Colors.secondaryText)
                        }
                        Spacer(minLength: 8)
                        if member.role == .member {
                            Button(action: {
                                guard store.removeMember(userID: member.userID) else { return }
                                refresh()
                                AppHaptics.selection()
                            }) {
                                Text(L10n.text("family_group.members.remove", en: "Remove", zh: "移除"))
                                    .font(AppTheme.Typography.meta)
                                    .foregroundStyle(AppTheme.Colors.primaryText)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(AppTheme.Colors.iconBackground)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
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
        refreshBabies()
    }

    private func refreshBabies() {
        babies = (try? babyRepository.fetchBabies()) ?? []
    }

    private func joinFamilyGroup() {
        let code = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }
        guard store.joinFamilyGroup(inviteCode: code) else { return }
        inviteCode = ""
        refresh()
        AppHaptics.lightImpact()
    }

    private func inviteStatusText(for familyGroup: FamilyGroup) -> String? {
        switch familyGroup.inviteState {
        case .active:
            if let expiresAt = familyGroup.inviteExpiresAt, expiresAt <= Date.now {
                return L10n.text("family_group.invite.expired", en: "Expired", zh: "已过期")
            }
            return L10n.text("family_group.invite.active", en: "Active", zh: "有效")
        case .expired:
            return L10n.text("family_group.invite.expired", en: "Expired", zh: "已过期")
        case .revoked:
            return L10n.text("family_group.invite.revoked", en: "Revoked", zh: "已撤销")
        }
    }

    private func memberLabel(for member: FamilyMemberSnapshot) -> String {
        if member.userID == store.currentUserID {
            return L10n.text("family_group.members.you", en: "You", zh: "你")
        }

        let prefix = member.userID.uuidString.prefix(4).uppercased()
        return "\(L10n.text("family_group.members.member_prefix", en: "Member", zh: "成员")) \(prefix)"
    }
}
