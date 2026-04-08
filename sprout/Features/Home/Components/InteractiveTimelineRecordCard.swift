import SwiftUI

struct InteractiveTimelineRecordCard<Content: View>: View {
    let item: TimelineDisplayItem
    let store: HomeStore
    let cornerRadius: CGFloat
    let isInteractionEnabled: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        Group {
            if isInteractionEnabled {
                cardButton
                    .contextMenu {
                        Button {
                            store.handle(.selectRecordContextEdit(item.recordID))
                        } label: {
                            Label(
                                L10n.text(
                                    "home.timeline.context.edit",
                                    en: "Edit record",
                                    zh: "编辑记录"
                                ),
                                systemImage: "square.and.pencil"
                            )
                        }

                        Button(role: .destructive) {
                            store.handle(.selectRecordContextDelete(item.recordID))
                        } label: {
                            Label(
                                L10n.text(
                                    "home.timeline.context.delete",
                                    en: "Delete record",
                                    zh: "删除记录"
                                ),
                                systemImage: "trash"
                            )
                        }
                    } preview: {
                        content()
                            .onAppear {
                                store.handle(.longPressTimelineRecord(item.recordID))
                            }
                            .onDisappear {
                                store.handle(.dismissRecordContextMenu)
                            }
                    }
            } else {
                cardButton
            }
        }
        .accessibilityHint(
            L10n.text(
                "home.timeline.context.hint",
                en: "Tap to edit. Touch and hold for more actions.",
                zh: "点按可编辑，长按可查看更多操作。"
            )
        )
    }

    private var isHighlighted: Bool {
        switch store.viewState.recordCellInteractionState {
        case let .pressing(recordID), let .menuTargeted(recordID):
            recordID == item.recordID
        case .idle:
            false
        }
    }

    private func handleTap() {
        guard isInteractionEnabled else { return }
        store.handle(.tapTimelineRecord(item.recordID))

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            store.handle(.releaseTimelineRecordPress)
        }
    }

    private var cardButton: some View {
        Button(action: handleTap) {
            content()
        }
        .buttonStyle(
            TimelineRecordCardButtonStyle(
                cornerRadius: cornerRadius,
                isHighlighted: isHighlighted
            )
        )
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

private struct TimelineRecordCardButtonStyle: ButtonStyle {
    let cornerRadius: CGFloat
    let isHighlighted: Bool

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed || isHighlighted

        configuration.label
            .scaleEffect(isPressed ? 0.985 : 1)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppTheme.Colors.primaryText.opacity(isPressed ? 0.035 : 0))
            }
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.12), value: isHighlighted)
    }
}
