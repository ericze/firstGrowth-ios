import SwiftUI
import UIKit

struct FoodPhotoCard: View {
    let item: TimelineDisplayItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            imageView
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipped()

            HStack(alignment: .top, spacing: 14) {
                RecordTypeIcon(icon: item.leadingIcon)

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundStyle(AppTheme.Colors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(AppTheme.Typography.cardBody)
                            .foregroundStyle(AppTheme.Colors.secondaryText)
                    }
                }

                Spacer(minLength: 12)

                TimeMetaView(date: item.timestamp)
            }
            .padding(18)
        }
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.image, style: .continuous))
        .shadow(color: AppTheme.Shadow.color, radius: AppTheme.Shadow.radius, y: AppTheme.Shadow.y)
    }

    @ViewBuilder
    private var imageView: some View {
        if let imagePath = item.imagePath, let image = UIImage(contentsOfFile: imagePath) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                AppTheme.Colors.iconBackground

                Image(systemName: "photo")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }
        }
    }
}
