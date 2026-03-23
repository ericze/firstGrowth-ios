import Observation
import PhotosUI
import SwiftUI
import UIKit

struct TreasureComposeModal: View {
    @Bindable var store: TreasureStore

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isShowingPhotoSourcePicker = false
    @State private var isShowingLibraryPicker = false
    @State private var isShowingCamera = false
    @State private var capturedImage: UIImage?
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
                            imagePath: store.viewState.composeDraft.imageLocalPath,
                            isInteractionEnabled: !isNoteFocused,
                            onTapAdd: { isShowingPhotoSourcePicker = true },
                            onRemove: { store.handle(.removeImage) }
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
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("拍照") {
                        isShowingCamera = true
                    }
                }

                Button("从相册选择") {
                    isShowingLibraryPicker = true
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
                persistCapturedImage(newImage)
            }
        }
        .interactiveDismissDisabled(store.viewState.composeDraft.hasAnyUserIntent)
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
    private func persistPhotoItem(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { return }
            let imagePath = try TreasurePhotoStorage.storeImageData(data)
            store.handle(.setImagePath(imagePath))
        } catch {
            assertionFailure("Treasure photo library import failed: \(error)")
        }
    }

    @MainActor
    private func persistCapturedImage(_ image: UIImage) {
        defer { capturedImage = nil }

        do {
            let imagePath = try TreasurePhotoStorage.storeImage(image)
            store.handle(.setImagePath(imagePath))
        } catch {
            assertionFailure("Treasure camera store failed: \(error)")
        }
    }
}

private struct TreasureComposePhotoSection: View {
    let imagePath: String?
    let isInteractionEnabled: Bool
    let onTapAdd: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("一张照片（可选）")
                .font(AppTheme.Typography.meta)
                .foregroundStyle(AppTheme.Colors.secondaryText)

            if let imagePath, let image = UIImage(contentsOfFile: imagePath) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))

                    Button(action: onRemove) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.primaryText)
                            .frame(width: 32, height: 32)
                            .background(AppTheme.Colors.cardBackground.opacity(0.92))
                            .clipShape(Circle())
                            .padding(14)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("删除照片")
                }
                .contentShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .allowsHitTesting(isInteractionEnabled)
                .onTapGesture(perform: onTapAdd)
            } else {
                Button(action: onTapAdd) {
                    VStack(spacing: 10) {
                        Image(systemName: "camera")
                            .font(.system(size: 26, weight: .light))
                            .foregroundStyle(AppTheme.Colors.secondaryText)

                        Text("留下一张画面")
                            .font(AppTheme.Typography.sheetBody)
                            .foregroundStyle(AppTheme.Colors.secondaryText)
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
