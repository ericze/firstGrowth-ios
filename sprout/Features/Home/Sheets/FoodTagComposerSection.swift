import SwiftUI

struct FoodTagComposerSection: View {
    @Binding var text: String

    let customTags: [String]
    let suggestions: [String]
    let columns: [GridItem]
    let onAdd: () -> Void
    let onSelectSuggestion: (String) -> Void
    let onRemove: (String) -> Void

    private var canAdd: Bool {
        !text.trimmed.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text("home.sheet.food.custom.title", en: "Add an ingredient", zh: "添加食材"))
                .font(AppTheme.Typography.meta)
                .foregroundStyle(AppTheme.Colors.secondaryText)

            HStack(spacing: 12) {
                TextField(
                    L10n.text("home.sheet.food.custom.placeholder", en: "Type an ingredient", zh: "输入食材名称"),
                    text: $text
                )
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .font(AppTheme.Typography.sheetBody)
                .foregroundStyle(AppTheme.Colors.primaryText)
                .onSubmit(onAdd)

                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(canAdd ? Color.white : AppTheme.Colors.tertiaryText)
                        .frame(width: 42, height: 42)
                        .background(canAdd ? AppTheme.Colors.primaryText : AppTheme.Colors.cardBackground)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(!canAdd)
                .accessibilityLabel(L10n.text("home.sheet.food.custom.add", en: "Add ingredient", zh: "添加食材"))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(AppTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))

            if !suggestions.isEmpty {
                FoodTagSection(
                    title: L10n.text("home.sheet.food.custom.suggestions", en: "Matches", zh: "可直接选择"),
                    tags: suggestions,
                    selectedTags: [],
                    columns: columns,
                    onToggle: onSelectSuggestion
                )
            }

            if !customTags.isEmpty {
                FoodTagSection(
                    title: L10n.text("home.sheet.food.custom.added", en: "Added here", zh: "刚刚添加"),
                    tags: customTags,
                    selectedTags: customTags,
                    columns: columns,
                    onToggle: onRemove
                )
            }
        }
    }
}
