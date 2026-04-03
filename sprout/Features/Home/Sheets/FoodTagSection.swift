import SwiftUI

struct FoodTagSection: View {
    let title: String
    let tags: [String]
    let selectedTags: [String]
    let columns: [GridItem]
    let onToggle: (String) -> Void

    private var orderedTags: [String] {
        let selected = tags.filter { selectedTags.contains($0) }
        let unselected = tags.filter { !selectedTags.contains($0) }
        return selected + unselected
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(AppTheme.Typography.meta)
                .foregroundStyle(AppTheme.Colors.secondaryText)

            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                ForEach(orderedTags, id: \.self) { tag in
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
                            .overlay {
                                Capsule()
                                    .stroke(
                                        isSelected ? AppTheme.Colors.accent : AppTheme.Colors.divider,
                                        lineWidth: isSelected ? 0 : 1
                                    )
                            }
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
