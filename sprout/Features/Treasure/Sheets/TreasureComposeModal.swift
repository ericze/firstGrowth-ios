import Observation
import PhotosUI
import SwiftUI
import UIKit

struct TreasureComposeModal: View {
    @Bindable var store: TreasureStore

    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isShowingPhotoSourcePicker = false
    @State private var isShowingLibraryPicker = false
    @State private var isShowingCamera = false
    @State private var capturedImage: UIImage?
    @State private var focusedPhotoIndex = 0
    @FocusState private var isNoteFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                composeHeader
                    .padding(.horizontal, AppTheme.Spacing.navigationHorizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 18)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        TreasureComposePhotoSection(
                            imagePaths: store.viewState.composeDraft.imageLocalPaths,
                            focusedIndex: $focusedPhotoIndex,
                            isInteractionEnabled: !isNoteFocused,
                            canAddMoreImages: remainingPhotoSlots > 0,
                            onTapAdd: { isShowingPhotoSourcePicker = true },
                            onRemove: removeImage(at:)
                        )

                        TreasureComposeNoteSection(
                            note: Binding(
                                get: { store.viewState.composeDraft.note },
                                set: { store.handle(.updateNote($0)) }
                            ),
                            isFocused: $isNoteFocused
                        )

                        TreasureComposeMilestoneToggle(
                            isOn: store.viewState.composeDraft.isMilestone,
                            onToggle: { store.handle(.toggleMilestone) }
                        )
                    }
                    .padding(.horizontal, AppTheme.Spacing.screenHorizontal)
                    .padding(.bottom, 36)
                }
                .scrollDismissesKeyboard(.interactively)
                .background {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            dismissNoteFocus()
                        }
                }
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .confirmationDialog("添加照片", isPresented: $isShowingPhotoSourcePicker) {
                if UIImagePickerController.isSourceTypeAvailable(.camera), remainingPhotoSlots > 0 {
                    Button("拍照") {
                        isShowingCamera = true
                    }
                }

                if remainingPhotoSlots > 0 {
                    Button("从相册选择") {
                        isShowingLibraryPicker = true
                    }
                } else {
                    Button("最多可放 6 张") {}
                }
            } message: {
                if remainingPhotoSlots == 0 {
                    Text("这一条记忆最多放 6 张照片。")
                }
            }
            .confirmationDialog("放弃这条记录？", isPresented: Binding(
                get: { store.shouldShowDiscardConfirmation },
                set: { _ in }
            )) {
                Button("继续编辑") {
                    store.handle(.cancelDiscard)
                }

                Button("放弃", role: .destructive) {
                    store.handle(.confirmDiscard)
                }
            } message: {
                Text("还没有保存。")
            }
            .alert("没有保存成功，请再试一次。", isPresented: Binding(
                get: { store.shouldShowComposeFailure },
                set: { isPresented in
                    if !isPresented {
                        store.handle(.dismissComposeError)
                    }
                }
            )) {
                Button("再试一次") {
                    store.handle(.retrySaveCompose)
                }

                Button("返回编辑") {
                    store.handle(.dismissComposeError)
                }
            } message: {
                Text(store.composeFailureMessage)
            }
            .photosPicker(
                isPresented: $isShowingLibraryPicker,
                selection: $selectedPhotoItems,
                maxSelectionCount: remainingPhotoSlots,
                matching: .images
            )
            .sheet(isPresented: $isShowingCamera) {
                SystemImagePicker(image: $capturedImage, sourceType: .camera)
            }
            .onChange(of: selectedPhotoItems) { _, newItems in
                guard !newItems.isEmpty else { return }
                Task {
                    await persistPhotoItems(newItems)
                    await MainActor.run {
                        selectedPhotoItems = []
                    }
                }
            }
            .onChange(of: capturedImage) { _, newImage in
                guard let newImage else { return }
                persistCapturedImage(newImage)
            }
            .onChange(of: store.viewState.composeDraft.imageLocalPaths) { _, newPaths in
                focusedPhotoIndex = max(0, min(focusedPhotoIndex, max(newPaths.count - 1, 0)))
            }
        }
        .interactiveDismissDisabled(store.viewState.composeDraft.hasAnyUserIntent)
    }

    private var remainingPhotoSlots: Int {
        max(TreasureLimits.maxImagesPerEntry - store.viewState.composeDraft.imageLocalPaths.count, 0)
    }

    private func dismissNoteFocus() {
        guard isNoteFocused else { return }
        isNoteFocused = false
    }

    private var composeHeader: some View {
        HStack {
            Button("关闭") {
                store.handle(.dismissCompose)
            }
            .font(AppTheme.Typography.meta)
            .foregroundStyle(AppTheme.Colors.secondaryText)

            Spacer()

            Text("留住今天")
                .font(AppTheme.Typography.sheetTitle)
                .foregroundStyle(AppTheme.Colors.primaryText)

            Spacer()

            Button("保存") {
                store.handle(.saveCompose)
            }
            .font(AppTheme.Typography.primaryButton)
            .foregroundStyle(store.isComposeSaveEnabled ? AppTheme.Colors.primaryText : AppTheme.Colors.tertiaryText)
            .disabled(!store.isComposeSaveEnabled)
        }
    }

    @MainActor
    private func persistPhotoItems(_ items: [PhotosPickerItem]) async {
        var storedPaths: [String] = []

        for item in items.prefix(remainingPhotoSlots) {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else { continue }
                let imagePath = try TreasurePhotoStorage.storeImageData(data)
                storedPaths.append(imagePath)
            } catch {
                assertionFailure("Treasure photo library import failed: \(error)")
            }
        }

        guard !storedPaths.isEmpty else { return }

        store.handle(.appendImagePaths(storedPaths))
        focusedPhotoIndex = max(store.viewState.composeDraft.imageLocalPaths.count - 1, 0)
    }

    private func removeImage(at index: Int) {
        store.handle(.removeImage(at: index))
        focusedPhotoIndex = max(0, min(focusedPhotoIndex, max(store.viewState.composeDraft.imageLocalPaths.count - 1, 0)))
    }

    @MainActor
    private func persistCapturedImage(_ image: UIImage) {
        defer { capturedImage = nil }

        guard remainingPhotoSlots > 0 else { return }

        do {
            let imagePath = try TreasurePhotoStorage.storeImage(image)
            store.handle(.appendImagePaths([imagePath]))
            focusedPhotoIndex = max(store.viewState.composeDraft.imageLocalPaths.count - 1, 0)
        } catch {
            assertionFailure("Treasure camera store failed: \(error)")
        }
    }
}

private struct TreasureComposePhotoSection: View {
    let imagePaths: [String]
    @Binding var focusedIndex: Int
    let isInteractionEnabled: Bool
    let canAddMoreImages: Bool
    let onTapAdd: () -> Void
    let onRemove: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("照片（可选）")
                    .font(AppTheme.Typography.meta)
                    .foregroundStyle(AppTheme.Colors.secondaryText)

                Spacer()

                Text("\(loadedImages.count)/\(TreasureLimits.maxImagesPerEntry)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.tertiaryText)
            }

            if let activeImage = selectedImage {
                ZStack(alignment: .topTrailing) {
                    Color.clear
                        .aspectRatio(TreasureTheme.mediaAspectRatio, contentMode: .fit)
                        .overlay {
                            Image(uiImage: activeImage.image)
                                .resizable()
                                .scaledToFill()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))

                    Button(action: { onRemove(activeImage.id) }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.primaryText)
                            .frame(width: 32, height: 32)
                            .background(AppTheme.Colors.cardBackground.opacity(0.92))
                            .clipShape(Circle())
                            .padding(14)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("删除当前照片")
                }
                .allowsHitTesting(isInteractionEnabled)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(loadedImages) { item in
                            Button {
                                focusedIndex = item.id
                            } label: {
                                Image(uiImage: item.image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 72, height: 72)
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(
                                                item.id == selectedImage?.id ? TreasureTheme.sageDeep : Color.clear,
                                                lineWidth: 1.5
                                            )
                                    }
                            }
                            .buttonStyle(.plain)
                        }

                        if canAddMoreImages {
                            Button(action: onTapAdd) {
                                VStack(spacing: 8) {
                                    Image(systemName: "plus.viewfinder")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundStyle(TreasureTheme.sageDeep)

                                    Text("继续添加")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(AppTheme.Colors.secondaryText)
                                }
                                .frame(width: 90, height: 72)
                                .background(AppTheme.Colors.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .allowsHitTesting(isInteractionEnabled)
            } else {
                Button(action: onTapAdd) {
                    VStack(spacing: 10) {
                        Image(systemName: "camera")
                            .font(.system(size: 26, weight: .light))
                            .foregroundStyle(AppTheme.Colors.secondaryText)

                        Text("留下一组画面")
                            .font(AppTheme.Typography.sheetBody)
                            .foregroundStyle(AppTheme.Colors.secondaryText)

                        Text("最多 6 张，按选择顺序排开。")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(AppTheme.Colors.tertiaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 240)
                    .background(AppTheme.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                }
                .buttonStyle(.plain)
                .allowsHitTesting(isInteractionEnabled)
            }
        }
    }

    private var loadedImages: [LoadedComposeImage] {
        imagePaths.enumerated().compactMap { index, path in
            guard let image = UIImage(contentsOfFile: path) else { return nil }
            return LoadedComposeImage(id: index, image: image)
        }
    }

    private var selectedImage: LoadedComposeImage? {
        loadedImages.first(where: { $0.id == focusedIndex }) ?? loadedImages.first
    }
}

private struct LoadedComposeImage: Identifiable {
    let id: Int
    let image: UIImage
}

private struct TreasureComposeNoteSection: View {
    @Binding var note: String
    let isFocused: FocusState<Bool>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("一句记下来的话")
                .font(AppTheme.Typography.meta)
                .foregroundStyle(AppTheme.Colors.secondaryText)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(AppTheme.Colors.cardBackground)

                TextEditor(text: $note)
                    .font(AppTheme.Typography.sheetBody)
                    .foregroundStyle(AppTheme.Colors.primaryText)
                    .scrollContentBackground(.hidden)
                    .focused(isFocused)
                    .padding(18)
                    .frame(minHeight: 180)

                if note.trimmed.isEmpty {
                    Text("今天有什么想记住的吗？")
                        .font(AppTheme.Typography.sheetBody)
                        .foregroundStyle(AppTheme.Colors.tertiaryText)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 26)
                        .allowsHitTesting(false)
                }
            }
            .frame(minHeight: 180)
        }
    }
}

private struct TreasureComposeMilestoneToggle: View {
    let isOn: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isOn ? "star.fill" : "star")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isOn ? AppTheme.Colors.highlight : AppTheme.Colors.secondaryText)

                Text("记为里程碑")
                    .font(AppTheme.Typography.sheetBody)
                    .foregroundStyle(AppTheme.Colors.primaryText)

                Spacer()

                Capsule()
                    .fill(isOn ? AppTheme.Colors.accent : AppTheme.Colors.divider)
                    .frame(width: 42, height: 26)
                    .overlay(alignment: isOn ? .trailing : .leading) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                            .padding(3)
                    }
            }
            .padding(18)
            .background(AppTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("记为里程碑")
    }
}
