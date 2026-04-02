import Observation
import PhotosUI
import SwiftUI
import UIKit

struct FoodRecordSheet: View {
    @Bindable var store: HomeStore

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
}

private struct FoodTagSection: View {
    let title: String
    let tags: [String]
    let selectedTags: [String]
    let columns: [GridItem]
    let onToggle: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(AppTheme.Typography.meta)
                .foregroundStyle(AppTheme.Colors.secondaryText)

            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                ForEach(tags, id: \.self) { tag in
                    let isSelected = selectedTags.contains(tag)

                    Button {
                        onToggle(tag)
                    } label: {
                        Text(tag)
                            .font(AppTheme.Typography.meta)
                            .foregroundStyle(isSelected ? Color.white : AppTheme.Colors.primaryText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.cardBackground)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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
