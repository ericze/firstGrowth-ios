import PhotosUI
import SwiftUI
import UIKit

struct BabyProfileView: View {
    let babyRepository: BabyRepository

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var birthDate: Date = .now
    @State private var gender: BabyProfile.Gender?
    @State private var avatarPath: String?
    @State private var saveErrorMessage: String?
    @State private var errorDismissTask: Task<Void, Never>?

    @State private var isShowingAvatarSourcePicker = false
    @State private var isShowingLibraryPicker = false
    @State private var isShowingCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.section) {
                avatarSection
                formSection
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
                    guard babyRepository.updateAvatar(nil) else {
                        showSaveError()
                        return
                    }
                    avatarPath = nil
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
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                guard let data = try await newItem.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                guard babyRepository.updateAvatar(image) else {
                    showSaveError()
                    return
                }
                avatarPath = babyRepository.activeBaby?.avatarPath
                selectedPhotoItem = nil
                AppHaptics.lightImpact()
            }
        }
        .onChange(of: capturedImage) { _, newImage in
            guard let newImage else { return }
            guard babyRepository.updateAvatar(newImage) else {
                showSaveError()
                return
            }
            avatarPath = babyRepository.activeBaby?.avatarPath
            capturedImage = nil
            AppHaptics.lightImpact()
        }
        .onAppear {
            loadFromRepository()
        }
        .onDisappear {
            errorDismissTask?.cancel()
            errorDismissTask = nil
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
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    guard babyRepository.updateName(trimmed) else {
                        showSaveError()
                        return
                    }
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
                guard babyRepository.updateBirthDate(birthDate) else {
                    showSaveError()
                    return
                }
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
        if gender == target {
            guard babyRepository.updateGender(nil) else {
                showSaveError()
                return
            }
            gender = nil
        } else {
            guard babyRepository.updateGender(target) else {
                showSaveError()
                return
            }
            gender = target
        }
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
        saveErrorMessage = String(localized: "shell.profile.save_error")
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

    private func loadFromRepository() {
        guard let baby = babyRepository.activeBaby else { return }
        name = baby.name
        birthDate = baby.birthDate
        gender = baby.gender
        avatarPath = baby.avatarPath
    }
}
