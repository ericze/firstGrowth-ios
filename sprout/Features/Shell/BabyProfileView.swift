import PhotosUI
import SwiftUI
import UIKit

struct BabyProfileView: View {
    let babyRepository: BabyRepository
    let onShowPaywall: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var authManager
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var babies: [BabyProfile] = []
    @State private var sharedBabies: [BabyProfile] = []
    @State private var name: String = ""
    @State private var birthDate: Date = .now
    @State private var gender: BabyProfile.Gender?
    @State private var avatarPath: String?
    @State private var saveErrorMessage: String?
    @State private var errorDismissTask: Task<Void, Never>?

    @State private var isShowingAvatarSourcePicker = false
    @State private var isShowingCreateBabySheet = false
    @State private var newBabyName: String = ""
    @State private var newBabyBirthDate: Date = .now
    @State private var newBabyGender: BabyProfile.Gender?
    @State private var deletionAlert: BabyDeletionAlert?
    @State private var isShowingLibraryPicker = false
    @State private var isShowingCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?

    init(
        babyRepository: BabyRepository,
        onShowPaywall: (() -> Void)? = nil
    ) {
        self.babyRepository = babyRepository
        self.onShowPaywall = onShowPaywall
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.section) {
                babyListSection
                avatarSection
                formSection
                sharedProfileHint
                saveFeedback
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
                Text(String(localized: "shell.sidebar.profile.title"))
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundStyle(AppTheme.Colors.primaryText)
            }
        }
        .confirmationDialog(
            String(localized: "profile.avatar.change_title"),
            isPresented: $isShowingAvatarSourcePicker
        ) {
            Button(String(localized: "profile.avatar.album")) {
                isShowingLibraryPicker = true
            }

            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button(String(localized: "profile.avatar.camera")) {
                    isShowingCamera = true
                }
            }

            if avatarPath != nil {
                Button(String(localized: "profile.avatar.remove"), role: .destructive) {
                    guard !isActiveSelectionShared else { return }
                    guard babyRepository.updateAvatar(nil) else {
                        showSaveError()
                        return
                    }
                    avatarPath = nil
                    refreshBabyListSilently()
                    AppHaptics.lightImpact()
                }
            }
        }
        .photosPicker(
            isPresented: $isShowingLibraryPicker,
            selection: $selectedPhotoItem,
            matching: .images
        )
        .sheet(isPresented: $isShowingCamera) {
            SystemImagePicker(image: $capturedImage, sourceType: .camera)
        }
        .sheet(isPresented: $isShowingCreateBabySheet) {
            CreateBabySheet(
                name: $newBabyName,
                birthDate: $newBabyBirthDate,
                gender: $newBabyGender,
                onCancel: { isShowingCreateBabySheet = false },
                onSave: createBaby
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .alert(item: $deletionAlert) { alert in
            if let babyID = alert.deleteBabyID {
                return Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    primaryButton: .destructive(Text(alert.confirmTitle)) {
                        performDeleteBaby(id: babyID)
                    },
                    secondaryButton: .cancel(Text(alert.cancelTitle))
                )
            }

            return Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text(alert.confirmTitle))
            )
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            guard !isActiveSelectionShared else {
                selectedPhotoItem = nil
                return
            }
            Task {
                guard let data = try await newItem.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                guard babyRepository.updateAvatar(image) else {
                    showSaveError()
                    return
                }
                avatarPath = babyRepository.activeBaby?.avatarPath
                refreshBabyListSilently()
                selectedPhotoItem = nil
                AppHaptics.lightImpact()
            }
        }
        .onChange(of: capturedImage) { _, newImage in
            guard let newImage else { return }
            guard !isActiveSelectionShared else {
                capturedImage = nil
                return
            }
            guard babyRepository.updateAvatar(newImage) else {
                showSaveError()
                return
            }
            avatarPath = babyRepository.activeBaby?.avatarPath
            refreshBabyListSilently()
            capturedImage = nil
            AppHaptics.lightImpact()
        }
        .onAppear {
            refreshFromRepository()
        }
        .onDisappear {
            errorDismissTask?.cancel()
            errorDismissTask = nil
        }
    }

    private var babyListSection: some View {
        VStack(spacing: AppTheme.Spacing.section) {
            babySection(
                title: L10n.text("shell.profile.babies.title", en: "Babies", zh: "宝宝"),
                detail: L10n.text(
                    "shell.profile.babies.detail",
                    en: "Choose who this moment belongs to.",
                    zh: "选择现在要记录的宝宝。"
                ),
                babies: babies,
                isShared: false,
                showsAddButton: true
            )

            if !sharedBabies.isEmpty {
                babySection(
                    title: L10n.text("shell.profile.shared_babies.title", en: "Shared Babies", zh: "共享宝宝"),
                    detail: L10n.text(
                        "shell.profile.shared_babies.detail",
                        en: "Babies shared with this account stay separate from your own.",
                        zh: "共享给这个账号的宝宝会和自己的宝宝分开显示。"
                    ),
                    babies: sharedBabies,
                    isShared: true,
                    showsAddButton: false
                )
            }
        }
    }

    private func babySection(
        title: String,
        detail: String,
        babies: [BabyProfile],
        isShared: Bool,
        showsAddButton: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundStyle(AppTheme.Colors.primaryText)

                    Text(detail)
                        .font(AppTheme.Typography.meta)
                        .foregroundStyle(AppTheme.Colors.tertiaryText)
                }

                Spacer()

                if showsAddButton {
                    Button(action: presentCreateBabySheet) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.primaryText)
                            .frame(width: 32, height: 32)
                            .background(AppTheme.Colors.iconBackground)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.text("shell.profile.add_baby", en: "Add baby", zh: "添加宝宝"))
                }
            }

            VStack(spacing: 0) {
                ForEach(babies, id: \.id) { baby in
                    babyRow(for: baby, isShared: isShared)

                    if baby.id != babies.last?.id {
                        Divider()
                            .overlay(AppTheme.Colors.divider)
                            .padding(.leading, 54)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.section)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
        .shadow(color: AppTheme.Shadow.color, radius: AppTheme.Shadow.radius, y: AppTheme.Shadow.y)
    }

    private func babyRow(for baby: BabyProfile, isShared: Bool) -> some View {
        let isCurrent = isCurrentBaby(baby)
        return HStack(spacing: 12) {
            Button(action: { activateBaby(baby) }) {
                HStack(spacing: 12) {
                    BabyAvatarView(
                        avatarPath: baby.avatarPath,
                        monogram: monogram(for: baby.name),
                        size: 42
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(baby.name)
                            .font(AppTheme.Typography.sheetBody)
                            .foregroundStyle(AppTheme.Colors.primaryText)
                            .lineLimit(1)

                        Text(baby.birthDate.formatted(.dateTime.year().month().day()))
                            .font(AppTheme.Typography.meta)
                            .foregroundStyle(AppTheme.Colors.tertiaryText)
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isCurrent)

            if isCurrent || isShared {
                Text(rowBadgeTitle(isCurrent: isCurrent, isShared: isShared))
                    .font(AppTheme.Typography.floatingLabel)
                    .foregroundStyle(AppTheme.Colors.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.Colors.iconBackground)
                    .clipShape(Capsule())
            }

            if !isShared && babies.count > 1 {
                Button(action: { presentDeleteAlert(for: baby) }) {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                        .frame(width: 32, height: 32)
                        .background(AppTheme.Colors.cardBackground)
                        .overlay {
                            Circle()
                                .stroke(AppTheme.Colors.divider, lineWidth: 1)
                        }
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    L10n.text("shell.profile.delete_baby", en: "Delete baby", zh: "删除宝宝")
                )
            }
        }
        .padding(.vertical, 12)
    }

    private func presentDeleteAlert(for baby: BabyProfile) {
        let message: String
        if baby.isActive {
            message = L10n.text(
                "shell.profile.delete.active.message",
                en: "This removes the profile after a quick check. Sprout will switch to another baby on this device.",
                zh: "删除前会先做一次快速检查。删除后，初长会自动切换到这台设备上的另一个宝宝。"
            )
        } else {
            message = L10n.text(
                "shell.profile.delete.message",
                en: "This removes the baby profile after a quick check. Existing records need to be cleared first.",
                zh: "删除前会先做一次快速检查。若这个宝宝还有记录内容，需要先清理后才能删除。"
            )
        }

        deletionAlert = BabyDeletionAlert(
            title: L10n.text("shell.profile.delete.title", en: "Delete this baby?", zh: "要删除这个宝宝吗？"),
            message: message,
            confirmTitle: L10n.text("shell.profile.delete.confirm", en: "Delete", zh: "删除"),
            cancelTitle: L10n.text("common.cancel", en: "Cancel", zh: "取消"),
            deleteBabyID: baby.id
        )
    }

    private func performDeleteBaby(id: UUID) {
        switch babyRepository.deleteBabyResult(id: id) {
        case .success:
            guard refreshFromRepository(showErrorOnFailure: false) else {
                showSaveError()
                return
            }
            AppHaptics.lightImpact()
        case .failure(.onlyRemainingBaby):
            deletionAlert = BabyDeletionAlert(
                title: L10n.text("shell.profile.delete.unavailable.title", en: "Keep one baby here", zh: "这里至少保留一个宝宝"),
                message: L10n.text(
                    "shell.profile.delete.unavailable.last",
                    en: "Sprout needs one baby profile to stay ready for quick local recording.",
                    zh: "为了让本地记录随时可用，初长需要至少保留一个宝宝资料。"
                ),
                confirmTitle: L10n.text("common.ok", en: "OK", zh: "知道了")
            )
        case .failure(.hasAssociatedData):
            deletionAlert = BabyDeletionAlert(
                title: L10n.text("shell.profile.delete.blocked.title", en: "Clear this baby's records first", zh: "请先清理这个宝宝的记录"),
                message: L10n.text(
                    "shell.profile.delete.blocked.message",
                    en: "This profile still has records, growth entries, or memories attached. Remove those first, then try again.",
                    zh: "这个宝宝下面还有记录、成长条目或珍藏内容。请先清理这些内容，再回来删除。"
                ),
                confirmTitle: L10n.text("common.ok", en: "OK", zh: "知道了")
            )
        case .failure(.babyNotFound):
            refreshFromRepository(showErrorOnFailure: false)
        case .failure:
            showSaveError()
        }
    }

    private var avatarSection: some View {
        Button(action: {
            AppHaptics.selection()
            isShowingAvatarSourcePicker = true
        }) {
            VStack(spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    BabyAvatarView(
                        avatarPath: avatarPath,
                        monogram: monogram,
                        size: 80
                    )

                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AppTheme.Colors.accent)
                        .background(Circle().fill(AppTheme.Colors.cardBackground))
                }

                Text(String(localized: "shell.profile.avatar.hint"))
                    .font(AppTheme.Typography.meta)
                    .foregroundStyle(AppTheme.Colors.tertiaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .disabled(isActiveSelectionShared)
    }

    private var formSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            nameField
            Divider().overlay(AppTheme.Colors.divider)
            birthDateField
            Divider().overlay(AppTheme.Colors.divider)
            genderField
        }
        .padding(AppTheme.Spacing.section)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
        .shadow(color: AppTheme.Shadow.color, radius: AppTheme.Shadow.radius, y: AppTheme.Shadow.y)
        .disabled(isActiveSelectionShared)
    }

    @ViewBuilder
    private var sharedProfileHint: some View {
        if isActiveSelectionShared {
            Text(L10n.text(
                "shell.profile.shared_baby.readonly",
                en: "This baby is shared with you. Profile details are managed by the owner.",
                zh: "这个宝宝是共享给你的。资料由创建者管理。"
            ))
            .font(AppTheme.Typography.meta)
            .foregroundStyle(AppTheme.Colors.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppTheme.Colors.cardBackground.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "shell.profile.nickname"))
                .font(AppTheme.Typography.meta)
                .foregroundStyle(AppTheme.Colors.tertiaryText)

            TextField(String(localized: "shell.profile.nickname"), text: $name)
                .font(AppTheme.Typography.sheetBody)
                .foregroundStyle(AppTheme.Colors.primaryText)
                .onChange(of: name) {
                    guard !isActiveSelectionShared else { return }
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    guard babyRepository.updateName(trimmed) else {
                        showSaveError()
                        return
                    }
                    refreshBabyListSilently()
                }
        }
        .padding(.vertical, 16)
    }

    private var birthDateField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "shell.sidebar.birth_date"))
                .font(AppTheme.Typography.meta)
                .foregroundStyle(AppTheme.Colors.tertiaryText)

            DatePicker(
                "",
                selection: $birthDate,
                displayedComponents: .date
            )
            .labelsHidden()
            .font(AppTheme.Typography.sheetBody)
            .foregroundStyle(AppTheme.Colors.primaryText)
            .onChange(of: birthDate) {
                guard !isActiveSelectionShared else { return }
                guard babyRepository.updateBirthDate(birthDate) else {
                    showSaveError()
                    return
                }
                refreshBabyListSilently()
            }
        }
        .padding(.vertical, 16)
    }

    private var genderField: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "shell.profile.gender"))
                .font(AppTheme.Typography.meta)
                .foregroundStyle(AppTheme.Colors.tertiaryText)

            HStack(spacing: 12) {
                genderChip(
                    label: String(localized: "shell.profile.gender.male"),
                    isSelected: gender == .male,
                    action: { toggleGender(.male) }
                )
                genderChip(
                    label: String(localized: "shell.profile.gender.female"),
                    isSelected: gender == .female,
                    action: { toggleGender(.female) }
                )
            }
        }
        .padding(.vertical, 16)
    }

    private func genderChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            AppHaptics.selection()
            action()
        }) {
            Text(label)
                .font(AppTheme.Typography.sheetBody)
                .foregroundStyle(isSelected ? AppTheme.Colors.cardBackground : AppTheme.Colors.primaryText)
                .padding(.horizontal, 20)
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

    private func toggleGender(_ target: BabyProfile.Gender) {
        guard !isActiveSelectionShared else { return }
        if gender == target {
            guard babyRepository.updateGender(nil) else {
                showSaveError()
                return
            }
            gender = nil
            refreshBabyListSilently()
        } else {
            guard babyRepository.updateGender(target) else {
                showSaveError()
                return
            }
            gender = target
            refreshBabyListSilently()
        }
    }

    private func presentCreateBabySheet() {
        do {
            let accessibleBabies = try babyRepository.fetchAccessibleBabies(for: currentUserID)
            guard subscriptionManager.canCreateAdditionalBaby(existingBabyCount: accessibleBabies.owned.count) else {
                showPaywallOrError()
                return
            }
        } catch {
            showSaveError()
            return
        }

        resetCreateDraft()
        isShowingCreateBabySheet = true
    }

    private func createBaby() {
        let previousCount = babies.count
        let previousActiveBabyID = babyRepository.activeBaby?.id

        let result = babyRepository.createBabyResult(
            name: newBabyName,
            birthDate: newBabyBirthDate,
            gender: newBabyGender,
            currentUserID: currentUserID
        )

        switch result {
        case .success:
            break
        case .failure(.entitlementBlocked):
            isShowingCreateBabySheet = false
            showPaywallOrError()
            return
        case .failure:
            showSaveError()
            return
        }

        guard refreshFromRepository(showErrorOnFailure: false) else {
            showSaveError()
            return
        }

        let activeBabyID = babyRepository.activeBaby?.id
        guard babies.count > previousCount || activeBabyID != previousActiveBabyID else {
            showSaveError()
            return
        }

        isShowingCreateBabySheet = false
        resetCreateDraft()
        AppHaptics.lightImpact()
    }

    private func activateBaby(_ baby: BabyProfile) {
        guard !isCurrentBaby(baby) else { return }
        AppHaptics.selection()
        guard babyRepository.activateAccessibleBaby(id: baby.id, currentUserID: currentUserID) else {
            showSaveError()
            return
        }
        refreshFromRepository()
    }

    private func showPaywallOrError() {
        guard let onShowPaywall else {
            showSaveError()
            return
        }
        onShowPaywall()
    }

    @ViewBuilder
    private var saveFeedback: some View {
        if let saveErrorMessage {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.secondaryText)
                Text(saveErrorMessage)
                    .font(AppTheme.Typography.meta)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppTheme.Colors.cardBackground.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .transition(.opacity)
        }
    }

    private func showSaveError() {
        saveErrorMessage = L10n.text(
            "shell.profile.save_error",
            en: "Couldn’t save that just now. Please try again.",
            zh: "刚才没有保存成功，请再试一次。"
        )
        scheduleErrorDismiss()
    }

    private func scheduleErrorDismiss() {
        errorDismissTask?.cancel()
        errorDismissTask = Task {
            do {
                try await Task.sleep(for: .seconds(3))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            saveErrorMessage = nil
            errorDismissTask = nil
        }
    }

    private var monogram: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.first ?? Character("B"))
    }

    @discardableResult
    private func refreshFromRepository(showErrorOnFailure: Bool = true) -> Bool {
        do {
            let groups = try babyRepository.fetchAccessibleBabies(for: currentUserID)
            babies = groups.owned
            sharedBabies = groups.shared
            loadFromRepository()
            return true
        } catch {
            if showErrorOnFailure {
                showSaveError()
            }
            return false
        }
    }

    private func loadFromRepository() {
        guard let baby = babyRepository.activeBaby else { return }
        name = baby.name
        birthDate = baby.birthDate
        gender = baby.gender
        avatarPath = baby.avatarPath
    }

    private func resetCreateDraft() {
        newBabyName = ""
        newBabyBirthDate = .now
        newBabyGender = nil
    }

    private func refreshBabyListSilently() {
        guard let groups = try? babyRepository.fetchAccessibleBabies(for: currentUserID) else { return }
        babies = groups.owned
        sharedBabies = groups.shared
    }

    private func monogram(for babyName: String) -> String {
        let trimmed = babyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.first ?? Character("B"))
    }

    private var currentUserID: UUID? {
        if let currentUserID = authManager.currentUserID {
            return currentUserID
        }
        guard case .authenticated(let userID) = authManager.authState else {
            return nil
        }
        return userID
    }

    private var isActiveSelectionShared: Bool {
        guard let access = babyRepository.activeBabyAccess else { return false }
        guard case .shared = access.ownership else { return false }
        return true
    }

    private func isCurrentBaby(_ baby: BabyProfile) -> Bool {
        babyRepository.activeBaby?.id == baby.id
    }

    private func rowBadgeTitle(isCurrent: Bool, isShared: Bool) -> String {
        if isCurrent {
            return L10n.text("shell.profile.active_baby", en: "Current", zh: "当前")
        }
        if isShared {
            return L10n.text("shell.profile.shared_baby.badge", en: "Shared", zh: "共享")
        }
        return ""
    }
}

private struct CreateBabySheet: View {
    @Binding var name: String
    @Binding var birthDate: Date
    @Binding var gender: BabyProfile.Gender?

    let onCancel: () -> Void
    let onSave: () -> Void

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        BaseRecordSheet(
            title: L10n.text("shell.profile.create.title", en: "Add a baby", zh: "添加宝宝"),
            onClose: onCancel
        ) {
            VStack(spacing: 14) {
                nameField
                birthDateField
                genderField
            }
        } footer: {
            SheetPrimaryButton(
                title: L10n.text("common.save", en: "Save", zh: "保存"),
                isEnabled: canSave,
                action: onSave
            )
            .disabled(!canSave)
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("shell.profile.nickname", en: "Name", zh: "昵称"))
                .font(AppTheme.Typography.meta)
                .foregroundStyle(AppTheme.Colors.secondaryText)

            TextField(
                L10n.text("shell.profile.create.name_placeholder", en: "Baby’s name", zh: "宝宝的名字"),
                text: $name
            )
            .font(AppTheme.Typography.sheetBody)
            .foregroundStyle(AppTheme.Colors.primaryText)
            .padding(16)
            .background(AppTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.sheetCard, style: .continuous))
        }
    }

    private var birthDateField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("shell.sidebar.birth_date", en: "Birth date", zh: "出生日期"))
                .font(AppTheme.Typography.meta)
                .foregroundStyle(AppTheme.Colors.secondaryText)

            DatePicker(
                "",
                selection: $birthDate,
                displayedComponents: .date
            )
            .labelsHidden()
            .font(AppTheme.Typography.sheetBody)
            .tint(AppTheme.Colors.accent)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(AppTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.sheetCard, style: .continuous))
        }
    }

    private var genderField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.text("shell.profile.create.gender", en: "Gender (optional)", zh: "性别（可选）"))
                .font(AppTheme.Typography.meta)
                .foregroundStyle(AppTheme.Colors.secondaryText)

            HStack(spacing: 10) {
                genderChip(
                    label: L10n.text("shell.profile.gender.none", en: "Not set", zh: "暂不设置"),
                    isSelected: gender == nil,
                    action: { gender = nil }
                )
                genderChip(
                    label: L10n.text("shell.profile.gender.male", en: "Boy", zh: "男孩"),
                    isSelected: gender == .male,
                    action: { gender = .male }
                )
                genderChip(
                    label: L10n.text("shell.profile.gender.female", en: "Girl", zh: "女孩"),
                    isSelected: gender == .female,
                    action: { gender = .female }
                )
            }
        }
    }

    private func genderChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            AppHaptics.selection()
            action()
        }) {
            Text(label)
                .font(AppTheme.Typography.meta)
                .foregroundStyle(isSelected ? AppTheme.Colors.cardBackground : AppTheme.Colors.primaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
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

private struct BabyDeletionAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let confirmTitle: String
    let cancelTitle: String
    let deleteBabyID: UUID?

    init(
        title: String,
        message: String,
        confirmTitle: String,
        cancelTitle: String = "",
        deleteBabyID: UUID? = nil
    ) {
        self.title = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.cancelTitle = cancelTitle
        self.deleteBabyID = deleteBabyID
    }
}
