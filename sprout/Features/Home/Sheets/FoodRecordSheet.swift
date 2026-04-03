import Observation
import PhotosUI
import SwiftUI
import UIKit

struct FoodRecordSheet: View {
    @Bindable var store: HomeStore

    @State private var customTagText = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isShowingPhotoSourcePicker = false
    @State private var isShowingLibraryPicker = false
    @State private var isShowingCamera = false
    @State private var capturedImage: UIImage?

    private let tagColumns = [GridItem(.adaptive(minimum: 88), spacing: 10)]

    var body: some View {
        BaseRecordSheet(title: String(localized: "home.sheet.food.title"), onClose: { store.requestFoodDismiss() }) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    FoodTagComposerSection(
                        text: $customTagText,
                        customTags: store.customFoodTags,
                        suggestions: store.foodTagSuggestions(for: customTagText),
                        columns: tagColumns,
                        onAdd: addCustomTag,
                        onSelectSuggestion: addSuggestedTag,
                        onRemove: store.toggleFoodTag
                    )

                    if let firstTasteHint = store.foodFirstTasteHint {
                        FoodFirstTasteHintCard(hint: firstTasteHint)
                    }

                    if !store.foodDraft.selectedTags.isEmpty {
                        FoodTagSection(
                            title: L10n.text("home.sheet.food.selected.title", en: "Selected", zh: "已选食材"),
                            tags: store.foodDraft.selectedTags,
                            selectedTags: store.foodDraft.selectedTags,
                            columns: tagColumns,
                            onToggle: store.toggleFoodTag
                        )
                    }

                    if !store.recentFoodTags.isEmpty {
                        FoodTagSection(
                            title: String(localized: "home.sheet.food.recent"),
                            tags: store.recentFoodTags,
                            selectedTags: store.foodDraft.selectedTags,
                            columns: tagColumns,
                            onToggle: store.toggleFoodTag
                        )
                    }

                    FoodTagSection(
                        title: String(localized: "home.sheet.food.common"),
                        tags: store.suggestedFoodTags,
                        selectedTags: store.foodDraft.selectedTags,
                        columns: tagColumns,
                        onToggle: store.toggleFoodTag
                    )

                    FoodNoteEditor(note: Binding(
                        get: { store.foodDraft.note },
                        set: { store.updateFoodNote($0) }
                    ))

                    FoodPhotoPickerSection(
                        imagePath: store.foodDraft.selectedImagePath,
                        onAddPhoto: {
                            isShowingPhotoSourcePicker = true
                        },
                        onRemovePhoto: store.removeFoodImage
                    )
                }
                .padding(.bottom, 12)
            }
        } footer: {
            SheetPrimaryButton(title: String(localized: "common.done_record"), isEnabled: store.isFoodSaveEnabled) {
                store.handle(.saveFood)
            }
        }
        .confirmationDialog(String(localized: "home.sheet.food.dialog.add_photo"), isPresented: $isShowingPhotoSourcePicker) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button(String(localized: "home.sheet.food.dialog.take_photo")) {
                    isShowingCamera = true
                }
            }

            Button(String(localized: "home.sheet.food.dialog.choose_library")) {
                isShowingLibraryPicker = true
            }
        }
        .confirmationDialog(String(localized: "home.sheet.food.dialog.discard_title"), isPresented: Binding(
            get: { store.isShowingFoodDiscardConfirmation },
            set: { _ in }
        )) {
            Button(String(localized: "home.sheet.food.dialog.continue_editing")) {
                store.keepEditingFoodDraft()
            }

            Button(String(localized: "home.sheet.food.dialog.discard"), role: .destructive) {
                store.discardFoodDraft()
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
                await persistPhotoItem(newItem)
                selectedPhotoItem = nil
            }
        }
        .onChange(of: capturedImage) { _, newImage in
            guard let newImage else { return }
            do {
                let imagePath = try FoodPhotoStorage.storeImage(newImage)
                store.setFoodImagePath(imagePath)
                capturedImage = nil
                AppHaptics.lightImpact()
            } catch {
                assertionFailure("Camera image store failed: \(error)")
            }
        }
    }

    @MainActor
    private func persistPhotoItem(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { return }
            let imagePath = try FoodPhotoStorage.storeImageData(data)
            store.setFoodImagePath(imagePath)
            AppHaptics.lightImpact()
        } catch {
            assertionFailure("Photo library import failed: \(error)")
        }
    }

    private func addCustomTag() {
        guard store.addFoodTag(customTagText) else { return }
        customTagText = ""
    }

    private func addSuggestedTag(_ tag: String) {
        guard store.addFoodTag(tag) else { return }
        customTagText = ""
    }
}

private struct FoodFirstTasteHintCard: View {
    let hint: FoodFirstTasteHint

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "leaf")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.Colors.accent)
                .padding(.top, 2)

            Text(hint.message)
                .font(AppTheme.Typography.meta)
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.cardBackground.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
    }
}

private struct FoodNoteEditor: View {
    @Binding var note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "home.sheet.food.note.title"))
                .font(AppTheme.Typography.meta)
                .foregroundStyle(AppTheme.Colors.secondaryText)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
                    .fill(AppTheme.Colors.cardBackground)

                TextEditor(text: $note)
                    .font(AppTheme.Typography.sheetBody)
                    .foregroundStyle(AppTheme.Colors.primaryText)
                    .scrollContentBackground(.hidden)
                    .padding(14)
                    .frame(minHeight: 120)

                if note.trimmed.isEmpty {
                    Text(String(localized: "home.sheet.food.note.placeholder"))
                        .font(AppTheme.Typography.sheetBody)
                        .foregroundStyle(AppTheme.Colors.tertiaryText)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 22)
                        .allowsHitTesting(false)
                }
            }
            .frame(minHeight: 120)
        }
    }
}

private struct FoodPhotoPickerSection: View {
    let imagePath: String?
    let onAddPhoto: () -> Void
    let onRemovePhoto: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "home.sheet.food.photo.title"))
                .font(AppTheme.Typography.meta)
                .foregroundStyle(AppTheme.Colors.secondaryText)

            if let imagePath, let image = UIImage(contentsOfFile: imagePath) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))

                    Button(action: onRemovePhoto) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.primaryText)
                            .frame(width: 30, height: 30)
                            .background(AppTheme.Colors.cardBackground.opacity(0.92))
                            .clipShape(Circle())
                            .padding(12)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "home.sheet.food.photo.delete_accessibility"))
                }
                .onTapGesture(perform: onAddPhoto)
            } else {
                Button(action: onAddPhoto) {
                    VStack(spacing: 10) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(AppTheme.Colors.secondaryText)

                        Text(String(localized: "home.sheet.food.photo.add"))
                            .font(AppTheme.Typography.sheetBody)
                            .foregroundStyle(AppTheme.Colors.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .background(AppTheme.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
