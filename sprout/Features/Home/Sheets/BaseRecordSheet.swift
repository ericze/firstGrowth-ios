import SwiftUI

struct BaseRecordSheet<Content: View, Footer: View>: View {
    let title: String
    let onClose: (() -> Void)?
    let customHeader: AnyView?
    let content: Content
    let footer: Footer

    init(
        title: String,
        onClose: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = title
        self.onClose = onClose
        self.customHeader = nil
        self.content = content()
        self.footer = footer()
    }

    init(
        onClose: (() -> Void)? = nil,
        @ViewBuilder header: () -> some View,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = ""
        self.onClose = onClose
        self.customHeader = AnyView(header())
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        VStack(spacing: 22) {
            if let customHeader {
                customHeader
            } else {
                SheetHeader(title: title, onClose: onClose)
            }

            content

            if Footer.self != EmptyView.self {
                Spacer(minLength: 0)
                footer
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppTheme.Colors.background)
    }
}

extension BaseRecordSheet where Footer == EmptyView {
    init(
        title: String,
        onClose: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(title: title, onClose: onClose, content: content) {
            EmptyView()
        }
    }
}

struct SheetHeader: View {
    let title: String
    let onClose: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(AppTheme.Typography.sheetTitle)
                .foregroundStyle(AppTheme.Colors.primaryText)

            Spacer()

            if let onClose {
                SheetCloseButton(action: onClose)
            }
        }
    }
}

struct SheetCloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .frame(width: 32, height: 32)
                .background(AppTheme.Colors.cardBackground)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "common.close"))
    }
}

struct SheetPrimaryButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.primaryButton)
                .foregroundStyle(isEnabled ? Color.white : AppTheme.Colors.tertiaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(isEnabled ? AppTheme.Colors.primaryText : AppTheme.Colors.primaryText.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
